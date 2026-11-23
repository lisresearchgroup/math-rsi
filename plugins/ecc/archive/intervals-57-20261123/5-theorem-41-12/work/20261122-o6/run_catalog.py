#!/usr/bin/env python3
"""run_catalog.py CATALOG.2 w D OUTDIR [--jobs J] [--extsearch PATH]
For every code in a *.2 catalog whose generator rows are all even weight, run extsearch and write OUTDIR/<idx>.json
(temp file + rename; existing results skipped => restartable). Codes with an odd-weight row get <idx>.skipped_odd.json.
Failures of extsearch get <idx>.failed.json (stderr kept). Finally writes OUTDIR/summary.json."""
import os, re, sys, json, subprocess, time, argparse
from concurrent.futures import ThreadPoolExecutor

ap = argparse.ArgumentParser()
ap.add_argument("catalog"); ap.add_argument("w", type=int); ap.add_argument("D", type=int); ap.add_argument("outdir")
ap.add_argument("--jobs", type=int, default=1)
ap.add_argument("--extsearch", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "extsearch"))
args = ap.parse_args()
os.makedirs(args.outdir, exist_ok=True)
tmpd = os.path.join(args.outdir, "_tmp"); os.makedirs(tmpd, exist_ok=True)

HDR = re.compile(r"^\?\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)")
codes = []   # (idx, k, n, rows)
lines = open(args.catalog, newline="").read().replace("\r", "").split("\n")
i = 0
while i < len(lines):
    mm = HDR.match(lines[i])
    if not mm:
        i += 1; continue
    k, n, q, idx = map(int, mm.groups())
    rows = []; i += 1
    pat = re.compile(r"^[01]{%d}$" % n)
    while i < len(lines) and len(rows) < k:
        s = lines[i].strip()
        if HDR.match(lines[i]): break
        if pat.match(s): rows.append(s)
        i += 1
    if len(rows) != k:
        raise SystemExit("catalog parse error at idx %d: got %d of %d rows" % (idx, len(rows), k))
    if q != 2: raise SystemExit("non-binary code idx %d" % idx)
    codes.append((idx, k, n, rows))
ids = [c[0] for c in codes]
if len(set(ids)) != len(ids): raise SystemExit("duplicate idx in catalog")
print("parsed %d codes from %s" % (len(codes), args.catalog), file=sys.stderr)

def work(c):
    idx, k, n, rows = c
    fin = os.path.join(args.outdir, "%d.json" % idx)
    sk = os.path.join(args.outdir, "%d.skipped_odd.json" % idx)
    if os.path.exists(fin) or os.path.exists(sk):
        return idx, "existing"
    if any(r.count("1") % 2 for r in rows):
        tmp = sk + ".tmp"
        with open(tmp, "w") as f:
            json.dump({"idx": idx, "N": n, "kappa": k, "skipped_odd": True,
                       "odd_rows": [j for j, r in enumerate(rows) if r.count("1") % 2]}, f)
        os.rename(tmp, sk); return idx, "skipped_odd"
    gen = os.path.join(tmpd, "%d.gen" % idx)
    with open(gen, "w") as f: f.write("\n".join(rows) + "\n")
    tmp = fin + ".tmp"
    t = time.time()
    r = subprocess.run([args.extsearch, gen, str(args.w), str(args.D), tmp], capture_output=True, text=True)
    el = time.time() - t
    os.remove(gen)
    if r.returncode != 0:
        with open(os.path.join(args.outdir, "%d.failed.json" % idx), "w") as f:
            json.dump({"idx": idx, "returncode": r.returncode, "stderr": r.stderr[-2000:]}, f)
        if os.path.exists(tmp): os.remove(tmp)
        return idx, "failed"
    d = json.load(open(tmp)); d["idx"] = idx; d["wall_seconds"] = round(el, 3)
    with open(tmp, "w") as f: json.dump(d, f)
    os.rename(tmp, fin)
    return idx, "done"

t0 = time.time()
with ThreadPoolExecutor(args.jobs) as ex:
    for idx, st in ex.map(work, codes):
        print("idx %d: %s (%.0fs)" % (idx, st, time.time() - t0), file=sys.stderr, flush=True)
try: os.rmdir(tmpd)
except OSError: pass

per = {}; skipped = []; failed = []
for idx, k, n, rows in codes:
    p = os.path.join(args.outdir, "%d.json" % idx)
    if os.path.exists(p):
        d = json.load(open(p))
        e = {"N": d["N"], "kappa": d["kappa"], "min_distance_K": d["min_distance_K"], "F_size": d["F_size"],
             "edges": d.get("edges"), "solutions": d["solutions"], "seconds": d["seconds"],
             "F_sha256": d["F_sha256"]}
        for j in range(3, args.w): e["c%d" % j] = d.get("c%d" % j)
        per[str(idx)] = e
    elif os.path.exists(os.path.join(args.outdir, "%d.skipped_odd.json" % idx)): skipped.append(idx)
    elif os.path.exists(os.path.join(args.outdir, "%d.failed.json" % idx)): failed.append(idx)
S = {"catalog": args.catalog, "w": args.w, "D": args.D, "n_codes": len(codes), "n_done": len(per),
     "skipped_odd": skipped, "failed": failed,
     "total_seconds_extsearch": round(sum(v["seconds"] for v in per.values()), 3),
     "total_F_size": sum(v["F_size"] for v in per.values()),
     "total_edges": sum(v["edges"] or 0 for v in per.values()),
     "total_solutions": sum(v["solutions"] for v in per.values()),
     "idx_with_solutions": [int(k) for k, v in per.items() if v["solutions"] > 0],
     "min_distance_K_below_D": [int(k) for k, v in per.items() if v["min_distance_K"] < args.D],
     "per_code": per}
with open(os.path.join(args.outdir, "summary.json.tmp"), "w") as f: json.dump(S, f, indent=1)
os.rename(os.path.join(args.outdir, "summary.json.tmp"), os.path.join(args.outdir, "summary.json"))
print("summary: done=%d skipped_odd=%d failed=%d solutions>0: %s" % (len(per), len(skipped), len(failed), S["idx_with_solutions"]), file=sys.stderr)
