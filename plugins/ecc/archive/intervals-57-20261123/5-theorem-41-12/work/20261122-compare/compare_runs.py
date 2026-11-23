#!/usr/bin/env python3
"""Join per-code outputs of two implementations (dirs A and B) for one catalog.

usage: compare_runs.py <catalog.2> <w> <dirA> <dirB> <out.json>

Facts only; no mathematical conclusions.  See work/O6_SPEC.md section 4 for fields.
"""
import hashlib
import json
import os
import re
import sys
import time
from concurrent.futures import ThreadPoolExecutor

D_REQ = 16
LEVEL_FIELD = {1: "F_size", 2: "edges", 3: "c3", 4: "c4", 5: "c5"}
COUNT_FIELDS = ["F_size", "edges", "c3", "c4", "c5", "solutions"]
RE_RES = re.compile(r"^(\d+)\.json$")
RE_SKIP = re.compile(r"^(\d+)\.skipped_odd\.json$")


# ---------------------------------------------------------------- catalog
def parse_catalog(path):
    """-> (sha256, {idx: (k, n, [row ints with bit j = column j], [row strings])}, [errors])"""
    with open(path, "rb") as f:
        raw = f.read()
    sha = hashlib.sha256(raw).hexdigest()
    lines = raw.decode("latin-1").replace("\r\n", "\n").replace("\r", "\n").split("\n")
    blocks, errors = {}, []
    i, L = 0, len(lines)
    while i < L:
        line = lines[i].strip()
        if not line.startswith("?"):
            i += 1
            continue
        tok = line[1:].split()
        try:
            k, n, q, idx = int(tok[0]), int(tok[1]), int(tok[2]), int(tok[3])
        except Exception:
            errors.append("bad header line %d: %r" % (i + 1, line))
            i += 1
            continue
        rows = []
        i += 1
        while len(rows) < k and i < L:
            s = lines[i].strip()
            i += 1
            if not s:
                continue
            if len(s) != n or set(s) - {"0", "1"}:
                errors.append("idx %d: bad row %r (line %d)" % (idx, s, i))
                break
            rows.append(s)
        if len(rows) != k:
            errors.append("idx %d: expected %d rows got %d" % (idx, k, len(rows)))
            continue
        if q != 2:
            errors.append("idx %d: q=%d" % (idx, q))
        if idx in blocks:
            errors.append("duplicate idx %d" % idx)
        blocks[idx] = (k, n, rows)
    return sha, blocks, errors


def rref_pivots(rows, n):
    """leftmost-pivot RREF over GF(2); column j <-> bit j. Returns pivot columns (ascending)."""
    v = [sum((1 << j) for j, c in enumerate(r) if c == "1") for r in rows]
    piv, r = [], 0
    for col in range(n):
        b = 1 << col
        sel = None
        for t in range(r, len(v)):
            if v[t] & b:
                sel = t
                break
        if sel is None:
            continue
        v[r], v[sel] = v[sel], v[r]
        for t in range(len(v)):
            if t != r and v[t] & b:
                v[t] ^= v[r]
        piv.append(col)
        r += 1
        if r == len(v):
            break
    return piv


def all_even(rows):
    return all(r.count("1") % 2 == 0 for r in rows)


# ---------------------------------------------------------------- result dirs
def scan_dir(d):
    res, skip, errs = {}, {}, []
    with os.scandir(d) as it:
        for e in it:
            m = RE_RES.match(e.name)
            if m:
                res[int(m.group(1))] = e.path
                continue
            m = RE_SKIP.match(e.name)
            if m:
                skip[int(m.group(1))] = e.path
    return res, skip


def load_json(path):
    try:
        with open(path, "rb") as f:
            return json.loads(f.read().decode("utf-8")), None
    except Exception as ex:  # noqa
        return None, "%s: %s" % (type(ex).__name__, ex)


def strip_zeros(h):
    if not isinstance(h, dict):
        return h
    return {str(k): v for k, v in h.items() if v != 0}


def brief(v):
    """shorten long lists for the report"""
    if isinstance(v, list) and len(v) > 40:
        return {"len": len(v), "head": v[:20],
                "sha256": hashlib.sha256(json.dumps(v).encode()).hexdigest()}
    return v


def norm_list(v):
    if isinstance(v, list):
        return [list(x) if isinstance(x, (list, tuple)) else x for x in v]
    return v


# ---------------------------------------------------------------- main
def main():
    if len(sys.argv) != 6:
        print(__doc__)
        sys.exit(2)
    cat_path, w_s, dirA, dirB, out_path = sys.argv[1:]
    w = int(w_s)
    m = w - 1
    t0 = time.time()
    cat_sha, blocks, cat_errors = parse_catalog(cat_path)
    idxs = sorted(blocks)
    even = {i: all_even(blocks[i][2]) for i in idxs}
    even_idx = [i for i in idxs if even[i]]
    odd_idx = [i for i in idxs if not even[i]]
    exp_piv = {}
    exp_rank_ok = {}
    for i in even_idx:
        k, n, rows = blocks[i]
        p = rref_pivots(rows, n)
        exp_piv[i] = p
        exp_rank_ok[i] = (len(p) == k)

    dirs = {"A": dirA, "B": dirB}
    scans = {t: scan_dir(d) for t, d in dirs.items()}

    # load every needed file exactly once through a thread pool
    jobs = []  # (tag, idx, kind, path)
    for t in dirs:
        res, skip = scans[t]
        for i, p in res.items():
            jobs.append((t, i, "res", p))
        for i, p in skip.items():
            jobs.append((t, i, "skip", p))

    def work(job):
        t, i, kind, p = job
        return job, load_json(p)

    loaded = {"A": {}, "B": {}}
    skipped_loaded = {"A": {}, "B": {}}
    bad_json = []
    with ThreadPoolExecutor(max_workers=32) as ex:
        for (t, i, kind, p), (obj, err) in ex.map(work, jobs, chunksize=16):
            if err:
                bad_json.append({"dir": t, "idx": i, "kind": kind, "file": p, "error": err})
            elif kind == "res":
                loaded[t][i] = obj
            else:
                skipped_loaded[t][i] = obj

    # ---- file presence
    missing = {"A": [], "B": []}  # idx with absent required file
    extra = {"A": [], "B": []}    # unexpected files (by idx), with reason
    for t in dirs:
        res, skip = scans[t]
        for i in idxs:
            if even[i]:
                if i not in res:
                    missing[t].append(i)
                if i in skip:
                    extra[t].append({"idx": i, "file": "skipped_odd.json", "reason": "even code has skipped_odd file"})
            else:
                if i not in skip:
                    missing[t].append(i)
                if i in res:
                    extra[t].append({"idx": i, "file": "json", "reason": "odd code has result json"})
        for i in sorted(set(res) | set(skip)):
            if i not in blocks:
                extra[t].append({"idx": i, "file": "json" if i in res else "skipped_odd.json",
                                 "reason": "idx not in catalog"})
    bad_json_idx = {(b["dir"], b["idx"], b["kind"]) for b in bad_json}

    # ---- per-file catalog checks and A/B comparison
    catalog_failures = []  # {"idx","dir","check","expected","got"}
    mismatches = []        # {"idx","fields":{f:{"A":..,"B":..}}}

    def cf(i, t, check, exp, got):
        catalog_failures.append({"idx": i, "dir": t, "check": check,
                                 "expected": brief(exp), "got": brief(got)})

    def check_one(t, i, r):
        k, n, _ = blocks[i]
        for name, exp in (("N", n), ("kappa", k), ("w", w), ("D", D_REQ), ("rho", n - k)):
            if r.get(name) != exp:
                cf(i, t, name, exp, r.get(name))
        if r.get("pivots") != exp_piv[i]:
            cf(i, t, "pivots_vs_python_rref", exp_piv[i], r.get("pivots"))
        if not exp_rank_ok[i]:
            cf(i, t, "catalog_rows_full_rank", k, len(exp_piv[i]))
        exp_free = [c for c in range(n) if c not in set(exp_piv[i])]
        if r.get("free") != exp_free:
            cf(i, t, "free_vs_complement_of_pivots", exp_free, r.get("free"))
        if r.get("min_distance_K") != D_REQ:
            cf(i, t, "min_distance_K", D_REQ, r.get("min_distance_K"))
        # internal consistency
        top = LEVEL_FIELD.get(m) if m <= 5 else None
        if m == 1:
            if r.get("solutions") != r.get("F_size"):
                cf(i, t, "solutions==F_size(m=1)", r.get("F_size"), r.get("solutions"))
        elif top and r.get("solutions") != r.get(top):
            cf(i, t, "solutions==%s" % top, r.get(top), r.get("solutions"))
        for j in range(2, m + 1):
            if j <= 5 and LEVEL_FIELD[j] not in r:
                cf(i, t, "field_present_%s" % LEVEL_FIELD[j], "present", "absent")
        for f in ("F_size", "F_sha256", "solutions", "solution_list", "depth_hist_even"):
            if f not in r:
                cf(i, t, "field_present_%s" % f, "present", "absent")
        sl = r.get("solution_list")
        if isinstance(sl, list) and not r.get("solution_list_truncated"):
            if len(sl) != r.get("solutions"):
                cf(i, t, "len(solution_list)==solutions", r.get("solutions"), len(sl))
        if isinstance(sl, list) and sl and any(len(x) != m for x in sl):
            cf(i, t, "solution_tuple_length", m, "mixed")
        h = strip_zeros(r.get("depth_hist_even"))
        if isinstance(h, dict):
            try:
                tot = sum(h.values())
                nk = n - k
                if tot != 1 << (nk - 1):
                    cf(i, t, "sum(depth_hist_even)==2^(rho-1)", 1 << (nk - 1), tot)
                fs = sum(v for kk, v in h.items() if int(kk) >= D_REQ - 2)
                if fs != r.get("F_size"):
                    cf(i, t, "F_size==hist(depth>=D-2)", r.get("F_size"), fs)
            except Exception as ex2:  # noqa
                cf(i, t, "depth_hist_even_parse", "dict of ints", repr(ex2))

    cmp_fields = ["pivots", "free", "min_distance_K", "F_size", "F_sha256", "depth_hist_even",
                  "edges", "c3", "c4", "c5", "solutions", "solution_list", "solution_list_truncated"]
    compared = 0
    identical = 0
    for i in even_idx:
        ra, rb = loaded["A"].get(i), loaded["B"].get(i)
        for t, r in (("A", ra), ("B", rb)):
            if r is not None:
                check_one(t, i, r)
        if ra is None or rb is None:
            continue
        compared += 1
        diff = {}
        for f in cmp_fields:
            va, vb = ra.get(f), rb.get(f)
            if f == "depth_hist_even":
                va, vb = strip_zeros(va), strip_zeros(vb)
            elif f == "solution_list":
                va, vb = norm_list(va), norm_list(vb)
            elif f == "solution_list_truncated":
                va, vb = bool(va), bool(vb)
            if f in ("edges", "c3", "c4", "c5") and f not in ra and f not in rb:
                continue
            if va != vb or (f in ra) != (f in rb) and f in ("edges", "c3", "c4", "c5"):
                diff[f] = {"A": brief(va), "B": brief(vb)}
        if diff:
            mismatches.append({"idx": i, "fields": diff})
        else:
            identical += 1

    # ---- totals per implementation
    last_but_one = LEVEL_FIELD.get(m - 1) if 2 <= m <= 6 else None  # level m-1
    totals = {}
    for t in dirs:
        rs = {i: r for i, r in loaded[t].items() if i in blocks and even.get(i)}
        tt = {"codes_loaded": len(rs)}
        for f in COUNT_FIELDS:
            vals = [(i, r[f]) for i, r in rs.items() if isinstance(r.get(f), (int, float))]
            tt["sum_" + f] = sum(v for _, v in vals)
            if vals:
                mi, mv = max(vals, key=lambda x: (x[1], -x[0]))
                tt["max_" + f] = {"value": mv, "idx": mi}
            else:
                tt["max_" + f] = None
        tt["idx_with_solutions"] = sorted(i for i, r in rs.items()
                                          if isinstance(r.get("solutions"), int) and r["solutions"] > 0)
        tt["last_but_one_level_field"] = last_but_one
        if last_but_one:
            vals = [(i, r.get(last_but_one)) for i, r in rs.items()
                    if isinstance(r.get(last_but_one), (int, float))]
            vals.sort(key=lambda x: (-x[1], x[0]))
            tt["top10_last_but_one_level"] = [{"idx": i, "value": v} for i, v in vals[:10]]
        tt["sum_seconds"] = sum(r["seconds"] for r in rs.values()
                                if isinstance(r.get("seconds"), (int, float)))
        tt["impl_names"] = sorted({str(r.get("impl")) for r in rs.values()})
        totals[t] = tt

    # odd code checks: skipped files must exist (in `missing`) and no result json (in `extra`)
    complete = {t: sum(1 for i in even_idx if i in loaded[t]) for t in dirs}
    odd_ok = {t: all(i in scans[t][1] for i in odd_idx) and not any(i in scans[t][0] for i in odd_idx)
              for t in dirs}
    problems_exist = bool(mismatches or catalog_failures or bad_json or cat_errors
                          or missing["A"] or missing["B"] or extra["A"] or extra["B"])
    all_ok = (not problems_exist) and compared == len(even_idx) and odd_ok["A"] and odd_ok["B"]

    out = {
        "catalog": os.path.abspath(cat_path),
        "catalog_sha256": cat_sha,
        "w": w,
        "D": D_REQ,
        "dirA": os.path.abspath(dirA),
        "dirB": os.path.abspath(dirB),
        "counts": {
            "codes": len(idxs), "even": len(even_idx), "odd": len(odd_idx),
            "complete_in_A": complete["A"], "complete_in_B": complete["B"],
            "compared": compared, "identical": identical,
        },
        "catalog_parse_errors": cat_errors,
        "mismatching": mismatches,
        "catalog_check_failures": catalog_failures,
        "missing_files": missing,
        "unexpected_files": extra,
        "unreadable_json": bad_json,
        "odd_idx": odd_idx,
        "totals": totals,
        "sum_seconds": {t: totals[t]["sum_seconds"] for t in dirs},
        "all_even_codes_compared_identical": bool(all_ok),
    }
    with open(out_path, "w") as f:
        json.dump(out, f, indent=1)
        f.write("\n")

    c = out["counts"]
    print("compare_runs: catalog=%s sha256=%s w=%d" % (os.path.basename(cat_path), cat_sha[:16], w))
    print("codes=%d even=%d odd=%d | complete A=%d B=%d | compared=%d identical=%d"
          % (c["codes"], c["even"], c["odd"], c["complete_in_A"], c["complete_in_B"], compared, identical))
    print("A-vs-B mismatching idx (%d): %s" % (len(mismatches), [x["idx"] for x in mismatches][:30]))
    print("catalog/internal check failures: %d (idx %s); unreadable json: %d; catalog parse errors: %d"
          % (len(catalog_failures), sorted({x["idx"] for x in catalog_failures})[:30], len(bad_json), len(cat_errors)))
    print("missing files A: %s ; B: %s" % (missing["A"][:30], missing["B"][:30]))
    print("unexpected files A: %s ; B: %s" % ([(x["idx"], x["reason"]) for x in extra["A"]][:10],
                                              [(x["idx"], x["reason"]) for x in extra["B"]][:10]))
    for t in dirs:
        tt = totals[t]
        print("%s: sum F_size=%d edges=%d c3=%d c4=%d c5=%d solutions=%d | max F_size=%s | sec=%.1f impl=%s"
              % (t, tt["sum_F_size"], tt["sum_edges"], tt["sum_c3"], tt["sum_c4"], tt["sum_c5"],
                 tt["sum_solutions"], tt["max_F_size"], tt["sum_seconds"], tt["impl_names"]))
    print("idx with solutions>0: A=%s B=%s" % (totals["A"]["idx_with_solutions"][:20],
                                              totals["B"]["idx_with_solutions"][:20]))
    print("top last-but-one (%s) A=%s" % (last_but_one, [(x["idx"], x["value"]) for x in
                                                         totals["A"].get("top10_last_but_one_level", [])][:5]))
    print("odd codes: A has all skipped & no result=%s, B=%s ; elapsed %.1fs" % (odd_ok["A"], odd_ok["B"], time.time() - t0))
    print("all_even_codes_compared_identical = %s" % out["all_even_codes_compared_identical"])


if __name__ == "__main__":
    main()
