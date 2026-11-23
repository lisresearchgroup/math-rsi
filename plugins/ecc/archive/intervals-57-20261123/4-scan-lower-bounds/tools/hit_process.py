#!/usr/bin/env python3
"""Batch acceptance driver for one-step-extension hits (SPEC_HITS.md section 4).

  hit_process.py [--id <base id>] [--all] [--force] [--threads N] [--skip-codetables]

For every hit target in hits/pending/<id>/hit_targets.json:
  1. build the final generator matrix G (K x N) -> hits/<N>-<K>/<id>-<A|L>/ (G.txt, base.cols, s.txt, x.txt, build.json, DERIVATION.md)
  2. run verify_a (tools/verify_a/verify_a)            -> verify_A.json / verify_A.log
  3. run verify_b if tools/verify_b/verify_b exists   -> verify_B.json / verify_B.log
  4. GET the live codetables page (cached, >=3 s between requests) -> codetables_live.html, novelty_codetables.json
  5. write STATUS.json, rebuild hits/INDEX.json and hits/INDEX.md.

Targets with rho'=N-K above --max-local-rho (default 37) are built but not verified here (partial, CLUSTER_PENDING.json);
tools/hit_cluster.py verifies them on Cluster and registers the results.

Idempotent and safe while the scheduler keeps adding hits: pending/ is only read, every file is written via
tmp+rename, a flock serialises concurrent hit_process runs.  Already `verified` targets are skipped unless --force.
"""
import argparse
import fcntl
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
import traceback
import urllib.request
from datetime import datetime, timezone

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HITS = os.path.join(CASE, "hits")
PENDING = os.path.join(HITS, "pending")
CACHE = os.path.join(HITS, "_codetables_cache")
VERIFY_A = os.path.join(CASE, "tools", "verify_a", "verify_a")
VERIFY_B = os.path.join(CASE, "tools", "verify_b", "verify_b")
CT_URL = "https://www.codetables.de/BKLC/BKLC.php?q=2&n=%d&k=%d"
CT_GAP = 3.0


# ----------------------------------------------------------------------------------------------
# small utilities
# ----------------------------------------------------------------------------------------------
def utc_now():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def sha256_bytes(b):
    return hashlib.sha256(b).hexdigest()


def sha256_file(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def atomic_write(path, data):
    if isinstance(data, str):
        data = data.encode("utf-8")
    tmp = "%s.tmp.%d" % (path, os.getpid())
    with open(tmp, "wb") as f:
        f.write(data)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, path)


def jdump(obj):
    return json.dumps(obj, ensure_ascii=False, indent=1, sort_keys=False) + "\n"


def jload(path, default=None):
    try:
        with open(path) as f:
            return json.load(f)
    except (OSError, ValueError):
        return default


def log(msg):
    print("[hit_process %s] %s" % (time.strftime("%H:%M:%S"), msg), flush=True)


# ----------------------------------------------------------------------------------------------
# GF(2) linear algebra on python ints (column integers: bit i = row i)
# ----------------------------------------------------------------------------------------------
def xor_basis(cols):
    """Greedy independent column set.
    Returns (basis, kernel):
      basis : dict highbit -> (vec, comb) ; vec = XOR of original columns in bitmask `comb`; comb only involves
              columns that were inserted into the basis (so a solution built from it has all other columns = 0)
      kernel: list of bitmasks over columns, each a dependent column j plus basis columns summing to 0
              (n - rank of them; together a basis of ker H)."""
    basis = {}
    kernel = []
    for j, c in enumerate(cols):
        v, comb = c, 1 << j
        while v:
            hb = v.bit_length() - 1
            if hb in basis:
                bv, bc = basis[hb]
                v ^= bv
                comb ^= bc
            else:
                basis[hb] = (v, comb)
                break
        if v == 0:
            kernel.append(comb)
    return basis, kernel


def solve_syndrome(basis, s):
    """x (bitmask over columns, free variables = 0) with H x = s, or None if s is not in the column space."""
    v, comb = s, 0
    while v:
        hb = v.bit_length() - 1
        if hb not in basis:
            return None
        bv, bc = basis[hb]
        v ^= bv
        comb ^= bc
    return comb


def xor_cols(cols, mask):
    s = 0
    j = 0
    while mask:
        if mask & 1:
            s ^= cols[j]
        mask >>= 1
        j += 1
    return s


def rank_rows(rows):
    """GF(2) rank of integer bitmask rows."""
    basis = {}
    r = 0
    for v in rows:
        while v:
            hb = v.bit_length() - 1
            if hb in basis:
                v ^= basis[hb]
            else:
                basis[hb] = v
                r += 1
                break
    return r


def mask_to_str(mask, n):
    return "".join("1" if (mask >> j) & 1 else "0" for j in range(n))


def str_to_mask(s):
    m = 0
    for j, ch in enumerate(s):
        if ch == "1":
            m |= 1 << j
    return m


def construct_code(cols, rho, s, typ):
    """Final code of a hit (SPEC_HITS.md section 1).  Returns dict with rows (list of bitmasks over N coords),
    N, K, x (bitmask over n0 coords), and the rank/consistency evidence."""
    n0 = len(cols)
    basis, kernel = xor_basis(cols)
    rank_H = len(basis)
    x = solve_syndrome(basis, s)
    if x is None:
        raise ValueError("syndrome s=%d is not in the column space of H" % s)
    gb = list(kernel)
    ev = {
        "rho": rho,
        "rank_H": rank_H,
        "rank_H_is_rho": rank_H == rho,
        "k0": n0 - rank_H,
        "rows_GB": len(gb),
        "rank_GB": rank_rows(gb),
        "GB_HT_zero": all(xor_cols(cols, r) == 0 for r in gb),
        "Hx_eq_s": xor_cols(cols, x) == s,
    }
    if typ == "A":
        rows = gb + [x]
        N = n0
    elif typ == "L":
        rows = gb + [x | (1 << n0)]
        N = n0 + 1
    else:
        raise ValueError("bad type %r" % typ)
    ev["rows_G"] = len(rows)
    ev["rank_G"] = rank_rows(rows)
    ev["rank_G_expected"] = ev["k0"] + 1
    ev["rank_ok"] = (ev["rank_H_is_rho"] and ev["rank_GB"] == ev["rows_GB"] == ev["k0"] and ev["rank_G"] == len(rows)
                     == ev["rank_G_expected"] and ev["GB_HT_zero"] and ev["Hx_eq_s"])
    return {"rows": rows, "N": N, "K": len(rows), "x": x, "evidence": ev}


# ----------------------------------------------------------------------------------------------
# verifiers
# ----------------------------------------------------------------------------------------------
def run_verifier(exe, which, tdir, D, threads, G_sha):
    """Run a verifier into verify_<which>.json/.log unless the stored state says it was already done for this G, D, binary."""
    state_path = os.path.join(tdir, "verify_state.json")
    state = jload(state_path, {})
    exe_sha = sha256_file(exe)
    outp = os.path.join(tdir, "verify_%s.json" % which)
    logp = os.path.join(tdir, "verify_%s.log" % which)
    st = state.get(which)
    if st and st.get("G_sha") == G_sha and st.get("D") == D and st.get("exe_sha") == exe_sha and st.get("rc") == 0 \
            and os.path.exists(outp):
        return jload(outp), st
    if os.path.exists(outp):
        os.remove(outp)
    cmd = [exe, os.path.join(tdir, "G.txt"), str(D), outp + ".run", str(threads)]
    t0 = time.time()
    with open(logp, "w") as lf:
        lf.write("# %s  (started %s)\n" % (" ".join(cmd), utc_now()))
        lf.flush()
        p = subprocess.run(cmd, stdout=lf, stderr=subprocess.STDOUT)
        lf.write("# exit code %d, wall %.2f s\n" % (p.returncode, time.time() - t0))
    st = {"G_sha": G_sha, "D": D, "exe_sha": exe_sha, "rc": p.returncode, "wall_sec": round(time.time() - t0, 3),
          "utc": utc_now()}
    res = None
    if p.returncode == 0 and os.path.exists(outp + ".run"):
        os.replace(outp + ".run", outp)
        res = jload(outp)
    else:
        if os.path.exists(outp + ".run"):
            os.remove(outp + ".run")
    state[which] = st
    atomic_write(state_path, jdump(state))
    return res, st


def check_verifier_result(res, N, K, D, rows):
    """Cross-check the verifier output against what we know. Returns (verdict, note) with verdict in
    True / False / 'bad' (inconsistent output)."""
    if res is None:
        return "bad", "no output"
    if res.get("n") != N or res.get("D") != D or res.get("rows") != len(rows) or res.get("k") != K:
        return "bad", "echoed parameters differ (n=%s k=%s rows=%s D=%s, expected n=%d k=%d rows=%d D=%d)" % (
            res.get("n"), res.get("k"), res.get("rows"), res.get("D"), N, K, len(rows), D)
    v = res.get("d_ge_D")
    if v is True:
        if res.get("witness") is not None:
            return "bad", "d_ge_D true but witness present"
        return True, ""
    if v is False:
        w = res.get("witness")
        if not w:
            return "bad", "d_ge_D false without witness"
        cw = w.get("codeword", "")
        if len(cw) != N or set(cw) - {"0", "1"}:
            return "bad", "witness has wrong length"
        m = str_to_mask(cw)
        wt = bin(m).count("1")
        if m == 0 or wt >= D or wt != w.get("weight"):
            return "bad", "witness invalid (weight %d, claimed %s, D=%d)" % (wt, w.get("weight"), D)
        if rank_rows(rows + [m]) != rank_rows(rows):
            return "bad", "witness not in the row space of G"
        return False, "witness weight %d" % wt
    return "bad", "d_ge_D missing"


# ----------------------------------------------------------------------------------------------
# codetables live page
# ----------------------------------------------------------------------------------------------
_last_req = [0.0]


def parse_ct(html, n, k):
    h = re.search(r"Bounds on linear codes \[\s*%d\s*,\s*%d\s*\] over GF\(2\)" % (n, k), html, re.I)
    lb = re.search(r"<TD>\s*lower bound:\s*</TD>\s*<TD>\s*(\d+)\s*</TD>", html, re.I)
    ub = re.search(r"<TD>\s*upper bound:\s*</TD>\s*<TD>\s*(\d+)\s*</TD>", html, re.I)
    if not (h and lb and ub):
        return None, None
    return int(lb.group(1)), int(ub.group(1))


def codetables(n, k, force=False):
    """Returns dict {html_path, fetched_utc, lower, upper, parse_ok, error}; fetches at most once per cell."""
    os.makedirs(CACHE, exist_ok=True)
    hp = os.path.join(CACHE, "%d-%d.html" % (n, k))
    mp = os.path.join(CACHE, "%d-%d.meta.json" % (n, k))
    meta = jload(mp)
    if meta and os.path.exists(hp) and not force:
        html = open(hp, encoding="utf-8", errors="replace").read()
        lb, ub = parse_ct(html, n, k)
        meta.update({"html_path": hp, "lower": lb, "upper": ub, "parse_ok": lb is not None})
        return meta
    wait = CT_GAP - (time.time() - _last_req[0])
    if wait > 0:
        time.sleep(wait)
    url = CT_URL % (n, k)
    err = None
    raw = None
    for attempt in range(3):
        try:
            _last_req[0] = time.time()
            req = urllib.request.Request(url, headers={"User-Agent": "scan-onestep-hit-verify/1.0"})
            with urllib.request.urlopen(req, timeout=60) as r:
                raw = r.read()
            break
        except Exception as e:  # network errors: retry with back-off, then give up (not cached)
            err = "%s: %s" % (type(e).__name__, e)
            time.sleep(CT_GAP * (attempt + 2))
    if raw is None:
        return {"html_path": None, "fetched_utc": None, "lower": None, "upper": None, "parse_ok": False, "error": err,
                "url": url}
    html = raw.decode("utf-8", errors="replace")
    lb, ub = parse_ct(html, n, k)
    meta = {"url": url, "fetched_utc": utc_now(), "html_sha256": sha256_bytes(raw)}
    atomic_write(hp, raw)
    atomic_write(mp, jdump(meta))
    meta.update({"html_path": hp, "lower": lb, "upper": ub, "parse_ok": lb is not None, "error": None})
    return meta


# ----------------------------------------------------------------------------------------------
# one target
# ----------------------------------------------------------------------------------------------
def derivation_md(base_id, typ, cell, new_d, depth, n0, k0, rho, s, t, ev, N, K):
    kind = ("A 型（加一行）：最终码 = B + ⟨x⟩，生成矩阵 [G_B; x]，参数 [%d,%d]" % (N, K)) if typ == "A" else (
        "L 型（加一行一列）：最终码 = {(c,0)} ∪ {(x+c,1)}，生成矩阵 [G_B|0; x|1]，参数 [%d,%d]" % (N, K))
    dist = ("min(d(B), depth(s))" if typ == "A" else "min(d(B), depth(s)+1)")
    return """# 推导与证据说明：基码 {id}，{typ} 型，目标格 [{N},{K}]，目标距离 {new_d}

## 来源说明（不作为证据）

- 基码 B = `[{n0},{k0}]`，校验矩阵 H 为 {rho}×{n0}，列整数由 `base.cols` 给出（`SPEC_TOOLS.md` 第 1 节：第 j 列整数 = Σ H[i][j]·2^i）。
- 分层程序 layers3 的结果 `raw.json`（sha256 见 `build.json`）给出：深度（陪集最小重量）≥ {depth} 的伴随式存在。
  取 `free` 中 t = depth−1 = {t} 一项的第一个代表 s = {s}（`s.txt`，十进制），即 s ∉ L_{t}(H)，depth(s) ≥ {depth}。
- 取 x 使 H x = s：对 H 的列做贪心线性无关选取，把 s 用选出的列线性表示，未选出的列（自由变量）取 0。x 见 `x.txt`（{n0} 位）。
- G_B 取 H 的核的一组基（{k0} 行）：每个相关列 j 给一个向量 e_j + （前面无关列的组合）。
- {kind}。
- 来源推导：新码字要么在 B 中，要么落在陪集 x+B 中，故距离 = {dist} ≥ {new_d}。
  这一推导依赖 layers3 的结果与 depth(s) ≥ {depth}，**只是来源说明，不作证据**。

## 证据（本目录文件里可复核的东西）

1. `G.txt`：最终码的生成矩阵，{K} 行 × {N} 列，坐标顺序 = `base.cols` 的列顺序{lcol}。
2. 秩证据（`build.json` 的 `rank_evidence`，由 `hit_process.py` 用整数异或消元算出）：
   rank(H) = {rank_H}（应为 ρ = {rho}）；rank(G_B) = {rank_GB}（应为 k0 = {k0}）；rank(G) = {rank_G}（应为 K = {K}）；
   G_B·Hᵀ = 0：{gbht}；H·x = s：{hxs}。
3. 距离证据：对 `G.txt` 由两套互相独立的程序做完整、无抽样的验距（判定 d(C) ≥ D，D = {new_d}），
   结果在 `verify_A.json`（`tools/verify_a/`，方法见其 `METHOD.md`）与 `verify_B.json`（`tools/verify_b/`，若已运行）。
   任一程序判假时给出重量 < D 的非零码字作见证，并由 `hit_process.py` 另行核对该见证确在行空间内。
4. `novelty_codetables.json`、`codetables_live.html`：取回码表实时页面时的下界/上界（只是查新记录）。
5. `STATUS.json`：验收汇总；`verified` 要求秩证据全部通过、A 与 B 都判真、且目标距离 > 码表实时下界。

上面第 2、3 点是证据；"来源说明"部分的推导即使有误，也不影响 G 的验收结论，因为验收只看 G 本身。
""".format(id=base_id, typ=typ, N=N, K=K, new_d=new_d, n0=n0, k0=k0, rho=rho, depth=depth, t=t, s=s, kind=kind,
           dist=dist, rank_H=ev["rank_H"], rank_GB=ev["rank_GB"], rank_G=ev["rank_G"],
           gbht="通过" if ev["GB_HT_zero"] else "未通过", hxs="通过" if ev["Hx_eq_s"] else "未通过",
           lcol="，L 型新坐标排在最后（第 %d 列，从 0 起）" % n0 if typ == "L" else "")


def stored_result(tdir, which, G_sha, D):
    """Verifier result registered in verify_state.json for exactly this G and D (any binary, e.g. from Cluster).
    Returns (json|None, state entry|None); (None, None) when nothing usable is registered."""
    st = (jload(os.path.join(tdir, "verify_state.json"), {}) or {}).get(which)
    if not st or st.get("G_sha") != G_sha or st.get("D") != D:
        return None, None
    if st.get("rc") == 0:
        res = jload(os.path.join(tdir, "verify_%s.json" % which))
        if res is None:
            return None, None
        return res, st
    return None, st


def process_target(hid, hdir, hit, tg, raw, raw_sha, cols, args):
    """Process one target; returns the STATUS dict (also written to disk)."""
    typ = tg["type"]
    cell = tg["cell"]
    new_d, depth = tg["new_d"], tg["depth"]
    n0, k0 = hit["base"]
    rho = hit["rho"]
    tdir = os.path.join(HITS, "%d-%d" % (cell[0], cell[1]), "%s-%s" % (hid, typ))
    os.makedirs(tdir, exist_ok=True)
    stp = os.path.join(tdir, "STATUS.json")
    old = jload(stp)
    bj_old = jload(os.path.join(tdir, "build.json"))
    if (old and old.get("status") == "verified" and not args.force and bj_old and bj_old.get("raw_sha256") == raw_sha
            and bj_old.get("new_d") == new_d and bj_old.get("depth") == depth):
        log("%s %s %s: already verified, skipped" % (hid, typ, cell))
        return old

    status = {"status": "partial", "note": "", "utc": utc_now(),
              "checks": {"rank": None, "verify_A": None, "verify_B": None, "codetables_live_lb": None,
                         "improves_live": None}}
    notes = []
    failed = False

    def fin():
        status["note"] = "; ".join(notes)
        status["utc"] = utc_now()
        atomic_write(stp, jdump(status))
        if status["status"] == "failed" and not (old and old.get("status") == "failed"):
            try:
                sys.path.insert(0, os.path.join(CASE, "sched"))
                import events
                events.emit(CASE, "hit_verify_failed", "%s %s cell %s d=%s: %s" % (hid, typ, cell, new_d, status["note"]),
                            {"id": hid, "type": typ, "cell": cell, "new_d": new_d, "dir": os.path.relpath(tdir, CASE)})
            except Exception as e:  # event emission must not hide the failure itself
                log("could not emit event: %s" % e)
        return status

    # ---- 1. build ----
    try:
        if (n0 + 1 if typ == "L" else n0, k0 + 1) != tuple(cell):
            raise ValueError("cell %s inconsistent with base [%d,%d] type %s" % (cell, n0, k0, typ))
        if len(cols) != n0 or raw["r"] != rho:
            raise ValueError("cols/raw shape mismatch (n=%d, r=%s, rho=%s)" % (len(cols), raw["r"], rho))
        fr = [f for f in raw["free"] if f["t"] == depth - 1]
        if not fr or not fr[0]["reps"]:
            raise ValueError("raw.json has no free entry with t=%d" % (depth - 1))
        s = fr[0]["reps"][0]
        code = construct_code(cols, rho, s, typ)
    except Exception as e:
        status["status"] = "failed"
        status["checks"]["rank"] = False
        notes.append("build error: %s: %s" % (type(e).__name__, e))
        return fin()
    ev, rows, N, K = code["evidence"], code["rows"], code["N"], code["K"]
    if k0 != ev["k0"]:
        notes.append("rank(H)=%d so k0=%d, but base id says k0=%d" % (ev["rank_H"], ev["k0"], k0))
        ev["rank_ok"] = False
    Gtxt = "".join(mask_to_str(r, N) + "\n" for r in rows)
    colstxt = " ".join(str(c) for c in cols) + "\n"
    files = {"G.txt": Gtxt, "base.cols": colstxt, "s.txt": "%d\n" % s, "x.txt": mask_to_str(code["x"], n0) + "\n"}
    for fn, data in files.items():
        atomic_write(os.path.join(tdir, fn), data)
    dmd = derivation_md(hid, typ, cell, new_d, depth, n0, k0, rho, s, depth - 1, ev, N, K)
    atomic_write(os.path.join(tdir, "DERIVATION.md"), dmd)
    G_sha = sha256_file(os.path.join(tdir, "G.txt"))
    build = {"base_id": hid, "type": typ, "cell": cell, "new_d": new_d, "depth": depth, "closes": tg.get("closes"),
             "base": [n0, k0], "rho": rho, "n": N, "k": K, "s": s, "free_t": depth - 1,
             "rank_evidence": ev,
             "raw_sha256": raw_sha,
             "file_sha256": dict([(fn, sha256_bytes(d.encode())) for fn, d in files.items()] +
                                 [("DERIVATION.md", sha256_bytes(dmd.encode()))]),
             "built_utc": utc_now()}
    atomic_write(os.path.join(tdir, "build.json"), jdump(build))
    status["checks"]["rank"] = bool(ev["rank_ok"])
    if not ev["rank_ok"]:
        status["status"] = "failed"
        notes.append("rank/consistency evidence failed: %s" % json.dumps(ev))
        return fin()

    # ---- 2/3. verifiers ----
    # rho' = N-K above --max-local-rho: never run here (bitmap of 2^rho' bits); the results come from Cluster via
    # tools/hit_cluster.py, which registers them in verify_state.json (where="cluster").
    verdicts = {}
    local = (N - K) <= args.max_local_rho
    cluster_missing = []
    for which, exe in (("A", VERIFY_A), ("B", VERIFY_B)):
        if local:
            if not (os.path.isfile(exe) and os.access(exe, os.X_OK)):
                status["checks"]["verify_" + which] = None
                if which == "A":
                    notes.append("verify_a missing")
                else:
                    notes.append("verify_b not available yet")
                continue
            res, st = run_verifier(exe, which, tdir, new_d, args.threads, G_sha)
        else:
            res, st = stored_result(tdir, which, G_sha, new_d)
            if st is None:
                status["checks"]["verify_" + which] = None
                cluster_missing.append(which)
                continue
        if st["rc"] != 0:
            status["checks"]["verify_" + which] = "error"
            tail = ""
            if not local:
                lp = os.path.join(tdir, "verify_%s.log" % which)
                try:
                    tail = ": " + [l for l in open(lp, errors="replace").read().splitlines() if l.strip()][-1][:300]
                except (OSError, IndexError):
                    pass
            notes.append("verify_%s exit code %s%s (see verify_%s.log%s)" % (
                which, st["rc"], " on Cluster job %s" % st.get("job") if not local else "", which, tail))
            continue
        v, why = check_verifier_result(res, N, K, new_d, rows)
        if v == "bad":
            status["checks"]["verify_" + which] = "error"
            notes.append("verify_%s output rejected: %s" % (which, why))
            continue
        verdicts[which] = v
        status["checks"]["verify_" + which] = v
        if v is False:
            failed = True
            notes.append("verify_%s: d < %d, %s, witness %s" % (which, new_d, why, res["witness"]["codeword"]))
    if len(verdicts) == 2 and verdicts["A"] != verdicts["B"]:
        failed = True
        notes.append("verify_A and verify_B DISAGREE")
    pend_path = os.path.join(tdir, "CLUSTER_PENDING.json")
    if cluster_missing:
        cf = jload(os.path.join(tdir, "cluster_failed.json"))
        if cf and cf.get("G_sha") == G_sha and cf.get("D") == new_d:
            notes.append("Cluster 验距失败: %s（resubmit: hit_cluster.py submit --force --id %s）" % (cf.get("note"), hid))
        else:
            notes.append("等待 Cluster 验距（rho'=%d > %d，缺 %s）" % (N - K, args.max_local_rho, "/".join(cluster_missing)))
            pend = {"base_id": hid, "type": typ, "cell": cell, "new_d": new_d, "depth": depth, "n": N, "k": K,
                    "rho_prime": N - K, "G_sha": G_sha, "D": new_d, "missing": cluster_missing,
                    "tdir": os.path.relpath(tdir, CASE)}
            old_p = jload(pend_path)
            if not old_p or {k: v for k, v in old_p.items() if k != "created_utc"} != pend:
                pend["created_utc"] = (old_p or {}).get("created_utc") or utc_now()
                atomic_write(pend_path, jdump(pend))
    elif os.path.exists(pend_path):
        os.remove(pend_path)

    # ---- 4. codetables ----
    live_lb = None
    if args.skip_codetables:
        notes.append("codetables not queried (--skip-codetables)")
        ct = None
    else:
        ct = codetables(cell[0], cell[1])
        if ct["html_path"]:
            shutil.copyfile(ct["html_path"], os.path.join(tdir, "codetables_live.html"))
        nov = {"cell": cell, "url": ct.get("url"), "fetched_utc": ct.get("fetched_utc"),
               "lower_bound": ct["lower"], "upper_bound": ct["upper"], "parse_ok": ct["parse_ok"],
               "html_sha256": ct.get("html_sha256"), "error": ct.get("error"),
               "new_d": new_d, "improves_live": (new_d > ct["lower"]) if ct["lower"] is not None else None}
        atomic_write(os.path.join(tdir, "novelty_codetables.json"), jdump(nov))
        live_lb = ct["lower"]
        if live_lb is None:
            notes.append("codetables live lower bound unavailable (%s)" % (ct.get("error") or "parse failed"))
    status["checks"]["codetables_live_lb"] = live_lb
    status["checks"]["improves_live"] = (new_d > live_lb) if live_lb is not None else None

    # ---- 5. status ----
    if failed:
        status["status"] = "failed"
    elif verdicts.get("A") is True and verdicts.get("B") is True and live_lb is not None and new_d > live_lb:
        status["status"] = "verified"
    else:
        status["status"] = "partial"
        if live_lb is not None and new_d <= live_lb:
            notes.append("not an improvement: live lower bound %d >= new_d %d" % (live_lb, new_d))
        if "B" not in verdicts and verdicts.get("A") is True:
            notes.append("only verify_A done")
    if not notes and status["status"] == "verified":
        notes.append("rank ok, verify_A and verify_B true, new_d %d > live lower bound %d" % (new_d, live_lb))
    return fin()


# ----------------------------------------------------------------------------------------------
# INDEX
# ----------------------------------------------------------------------------------------------
def build_index():
    cells = {}
    if os.path.isdir(HITS):
        for cn in sorted(os.listdir(HITS)):
            m = re.fullmatch(r"(\d+)-(\d+)", cn)
            cdir = os.path.join(HITS, cn)
            if not m or not os.path.isdir(cdir):
                continue
            for sn in sorted(os.listdir(cdir)):
                sdir = os.path.join(cdir, sn)
                st = jload(os.path.join(sdir, "STATUS.json"))
                bj = jload(os.path.join(sdir, "build.json"))
                if not st or not bj:
                    continue
                nov = jload(os.path.join(sdir, "novelty_codetables.json")) or {}
                c = cells.setdefault(cn, {"cell": [int(m.group(1)), int(m.group(2))], "live_lb": None, "live_ub": None,
                                          "fetched_utc": None, "sources": []})
                if nov.get("lower_bound") is not None:
                    c["live_lb"], c["live_ub"], c["fetched_utc"] = nov["lower_bound"], nov["upper_bound"], nov.get("fetched_utc")
                c["sources"].append({"id": bj["base_id"], "type": bj["type"], "new_d": bj["new_d"], "depth": bj["depth"],
                                     "closes_snapshot": bj.get("closes"), "status": st["status"], "note": st.get("note", ""),
                                     "dir": os.path.relpath(sdir, CASE), "checks": st.get("checks")})
    out = []
    for cn, c in sorted(cells.items(), key=lambda kv: (kv[1]["cell"][0], kv[1]["cell"][1])):
        srcs = c["sources"]
        c["new_lb_claimed"] = max(s["new_d"] for s in srcs)
        ver = [s["new_d"] for s in srcs if s["status"] == "verified"]
        c["new_lb_verified"] = max(ver) if ver else None
        ub = c["live_ub"]
        c["closes_live"] = (c["new_lb_verified"] == ub) if (ub is not None and ver) else None
        c["closes_snapshot"] = any(s["closes_snapshot"] for s in srcs)
        out.append(c)
    index = {"generated_utc": utc_now(), "cells": out}
    atomic_write(os.path.join(HITS, "INDEX.json"), jdump(index))
    lines = ["# 命中验收索引", "", "生成时间 %s（UTC）。每个目标格一行；来源 = 基码 id、类型（A 加一行 / L 加一行一列）、目标距离、验收状态。" % index["generated_utc"],
             "状态：verified = 秩正确 + 验距 A、B 均判真 + 新距离 > 码表实时下界；partial = 证据不全或非改进；failed = 有判假/秩错。", "",
             "| 目标格 [n,k] | 码表下界(实时) | 码表上界 | 新下界(已验收) | 新下界(声称) | 闭合区间 | 来源（基码 类型 d 状态） |",
             "|---|---|---|---|---|---|---|"]
    for c in out:
        src = "<br>".join("%s %s d=%d **%s**" % (s["id"], s["type"], s["new_d"], s["status"]) for s in c["sources"])
        cl = {True: "是", False: "否", None: "-"}[c["closes_live"]]
        lines.append("| [%d,%d] | %s | %s | %s | %d | %s | %s |" % (
            c["cell"][0], c["cell"][1], "-" if c["live_lb"] is None else c["live_lb"],
            "-" if c["live_ub"] is None else c["live_ub"],
            "-" if c["new_lb_verified"] is None else c["new_lb_verified"], c["new_lb_claimed"], cl, src))
    lines += ["", "注：“闭合区间”按实时上界判断（已验收的新下界 = 上界）。", ""]
    atomic_write(os.path.join(HITS, "INDEX.md"), "\n".join(lines))
    return index


# ----------------------------------------------------------------------------------------------
# one base code (pending directory)
# ----------------------------------------------------------------------------------------------
def process_hit(hid, args, only=None):
    hdir = os.path.join(PENDING, hid)
    hit = jload(os.path.join(hdir, "hit_targets.json"))
    rawp = os.path.join(hdir, "raw.json")
    if hit is None or not os.path.exists(rawp):
        log("%s: hit_targets.json/raw.json not there yet, skipped" % hid)
        return []
    raw_sha = sha256_file(rawp)
    if hit.get("raw_sha256") != raw_sha:
        log("%s: raw.json sha256 differs from hit_targets.json (collector mid-write?), skipped" % hid)
        return []
    raw = jload(rawp)
    cols = raw["cols"]
    colf = os.path.join(hdir, hid + ".cols")
    if os.path.exists(colf):
        c2 = [int(x) for x in open(colf).read().split()]
        if c2 != cols:
            log("%s: %s.cols differs from raw.json cols" % (hid, hid))
            cols_bad = True
        else:
            cols_bad = False
    else:
        cols_bad = False
    results = []
    for tg in hit["targets"]:
        if not tg.get("hit"):
            continue
        if only is not None and (tg["type"], tuple(tg["cell"])) not in only:
            continue
        try:
            if cols_bad:
                raise ValueError("%s.cols differs from the cols inside raw.json" % hid)
            st = process_target(hid, hdir, hit, tg, raw, raw_sha, cols, args)
        except Exception as e:
            traceback.print_exc()
            st = {"status": "failed", "note": "driver exception: %s: %s" % (type(e).__name__, e)}
            tdir = os.path.join(HITS, "%d-%d" % tuple(tg["cell"]), "%s-%s" % (hid, tg["type"]))
            os.makedirs(tdir, exist_ok=True)
            atomic_write(os.path.join(tdir, "STATUS.json"), jdump(st))
        log("%s %s cell %s d=%s -> %s %s" % (hid, tg["type"], tg["cell"], tg["new_d"], st["status"], st.get("note", "")))
        results.append((hid, tg, st))
        build_index()  # keep INDEX/dashboard current while long batches run
    return results


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--id", action="append", help="base code id under hits/pending/ (repeatable)")
    ap.add_argument("--all", action="store_true", help="process every hits/pending/<id>/")
    ap.add_argument("--force", action="store_true", help="redo also targets that are already verified")
    ap.add_argument("--threads", type=int, default=4, help="threads per verifier run (default 4)")
    ap.add_argument("--skip-codetables", action="store_true", help="do not query codetables.de (cached pages are NOT used either)")
    ap.add_argument("--max-local-rho", type=int, default=int(os.environ.get("HIT_MAX_LOCAL_RHO", "37")),
                    help="targets with rho'=N-K above this are NOT verified locally (bitmap too large): status partial, "
                         "CLUSTER_PENDING.json written for tools/hit_cluster.py (default 37, env HIT_MAX_LOCAL_RHO)")
    args = ap.parse_args()
    if not args.id and not args.all:
        ap.error("give --id <id> or --all")
    os.makedirs(HITS, exist_ok=True)
    lockf = open(os.path.join(HITS, ".hit_process.lock"), "w")
    try:
        fcntl.flock(lockf, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        print("another hit_process.py is running; exiting", file=sys.stderr)
        return 3
    ids = list(args.id or [])
    if args.all:
        ids += [d for d in sorted(os.listdir(PENDING)) if os.path.isdir(os.path.join(PENDING, d)) and d not in ids]
    summary = []
    for hid in ids:
        summary += process_hit(hid, args)
    index = build_index()
    cnt = {}
    for _, _, st in summary:
        cnt[st["status"]] = cnt.get(st["status"], 0) + 1
    log("done: %d targets processed %s; INDEX has %d cells" % (len(summary), cnt, len(index["cells"])))
    return 1 if cnt.get("failed") else 0


if __name__ == "__main__":
    sys.exit(main())
