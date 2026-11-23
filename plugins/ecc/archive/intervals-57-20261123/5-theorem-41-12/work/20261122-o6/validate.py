#!/usr/bin/env python3
"""Small-domain validation of extsearch vs brute (and layering-only check). Writes validation/REPORT.md."""
import os, sys, random, subprocess, json, hashlib, itertools, time
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
VD = os.path.join(HERE, "validation")
CD = os.path.join(VD, "cases")
os.makedirs(CD, exist_ok=True)
EXT = os.path.join(HERE, "extsearch")
BR = os.path.join(HERE, "brute")

def min_dist(rows, N):
    best = N + 1
    cur = 0
    for g in range(1, 1 << len(rows)):
        cur ^= rows[(g & -g).bit_length() - 1]
        w = bin(cur).count("1")
        best = min(best, w)
    return best

def rank(rows):
    rows = list(rows); r = 0
    basis = []
    for v in rows:
        for b in basis:
            v = min(v, v ^ b)
        if v:
            basis.append(v)
    return len(basis)

def to_str(v, N):  # coordinate c = bit c, leftmost char = coordinate 0
    return "".join("1" if v >> c & 1 else "0" for c in range(N))

def gen_rand(rng, kappa, N, D, kind):
    """kind: rand (random even rows), rep (column multiset with a repeated column), lowd (dK<D, with repeated H column or weight-2 word)"""
    for _ in range(200000):
        if kind == "rand" or kind == "lowd":
            rows = []
            for _ in range(kappa):
                wt = rng.choice([x for x in range(max(2, D if kind == "rand" else 2), N + 1, 2)])
                v = sum(1 << c for c in rng.sample(range(N), wt))
                rows.append(v)
            if kind == "lowd":
                a, b = rng.sample(range(N), 2); rows[0] = (1 << a) | (1 << b)
        else:  # rep: pick columns (in F2^kappa) with repetition
            ncol = rng.randrange(max(2, N // 2), N)  # number of distinct column slots
            cols = [rng.randrange(1, 1 << kappa) for _ in range(N)]
            cs = [cols[i] for i in range(N)]
            if len(set(cs)) == N:
                continue
            rows = [sum(((cs[c] >> i) & 1) << c for c in range(N)) for i in range(kappa)]
            if any(bin(r).count("1") & 1 for r in rows):
                continue
        if rank(rows) != kappa:
            continue
        d = min_dist(rows, N)
        if kind == "lowd":
            if d < D:
                # also require extsearch-relevant structure: weight-2 word (repeated H column) at least half the time
                return rows
        else:
            if d >= D:
                return rows
    return None

# (w, D, kappa, N, kind)   (kappa,N satisfy Griesmer for d>=D; brute-force cost limits rho)
SPECS = []
def add(w, D, lst, kind="rand"):
    for (k, N) in lst:
        SPECS.append((w, D, k, N, kind))
# w=4 (m=3)
add(4, 4, [(3, 9), (2, 8), (4, 10), (5, 11), (2, 9)])
add(4, 6, [(2, 9), (2, 9), (2, 10), (3, 11), (3, 12), (2, 11)])
add(4, 8, [(2, 12), (2, 12), (3, 14), (3, 14), (4, 15), (2, 13)])
add(4, 4, [(3, 9)], "rep")
add(4, 6, [(3, 12), (2, 10)], "rep")
add(4, 8, [(2, 12), (3, 14)], "rep")
add(4, 4, [(3, 10)], "lowd")
add(4, 6, [(3, 11)], "lowd")
add(4, 8, [(2, 12)], "lowd")
# w=5 (m=4), rho<=8
add(5, 4, [(2, 8), (3, 9), (4, 10)])
add(5, 6, [(2, 9), (2, 9), (2, 9), (2, 10), (2, 10), (3, 11)])
add(5, 4, [(3, 9)], "rep")
add(5, 6, [(2, 9), (2, 9)], "rep")
add(5, 4, [(3, 9)], "lowd")
add(5, 6, [(2, 9)], "lowd")
# w=6 (m=5), rho<=7
add(6, 4, [(2, 8), (3, 9), (4, 10)])
add(6, 6, [(2, 9), (2, 9), (2, 9), (2, 9)])
add(6, 6, [(2, 9), (2, 9)], "rep")
add(6, 4, [(3, 9)], "rep")
add(6, 4, [(3, 9)], "lowd")
add(6, 6, [(2, 9)], "lowd")
# w=3 (m=2), w=2 (m=1): larger rho allowed
add(3, 6, [(2, 11), (3, 13)])
add(3, 8, [(2, 14), (3, 14), (4, 15)])
add(3, 6, [(4, 15)], "lowd")
add(2, 6, [(3, 16), (2, 13)])
# heavier brute-force cases (appended): w=5 rho 9-10, w=6 rho 8
add(5, 8, [(2, 12)])
add(6, 6, [(2, 10), (3, 11)])

def run(cmd, **kw):
    t = time.time()
    r = subprocess.run(cmd, capture_output=True, text=True, **kw)
    if r.returncode != 0:
        raise RuntimeError("cmd failed %s: %s" % (cmd, r.stderr[-500:]))
    return time.time() - t

def fmt_list(l, cap=3):
    s = str(l[:cap])
    return s + ("..." if len(l) > cap else "")

def do_case(idx, spec, rows, N):
    w, D, kappa, _, kind = spec
    name = "c%02d" % idx
    gen = os.path.join(CD, name + ".gen")
    with open(gen, "w") as f:
        for v in rows:
            f.write(to_str(v, N) + "\n")
    ej = os.path.join(CD, name + ".ext.json"); bj = os.path.join(CD, name + ".brute.json")
    ef = os.path.join(CD, name + ".F.txt"); ed = os.path.join(CD, name + ".depth.bin")
    t_ext = run([EXT, gen, str(w), str(D), ej, "--dump-F", ef, "--dump-depth", ed, "--sol-cap", "100000000"])
    t_br = run([BR, gen, str(w), str(D), bj])
    E = json.load(open(ej)); B = json.load(open(bj))
    m = w - 1
    res = {}
    rho = E["rho"]
    res["labelling"] = (E["pivots"] == B["pivots"] and E["free"] == B["free"])
    res["dK"] = (E["min_distance_K"] == B["min_distance_K"])
    ed_bytes = open(ed, "rb").read()
    res["depth"] = (list(ed_bytes) == B["depth"])
    Fb = [s for s in range(1, 1 << rho) if bin(s).count("1") % 2 == 0 and B["depth"][s] >= D - 2]
    Fe = [int(x) for x in open(ef).read().split()]
    res["F"] = (Fb == Fe and E["F_size"] == len(Fb))
    h = hashlib.sha256("".join("%d\n" % x for x in Fb).encode()).hexdigest()
    res["sha"] = (h == E["F_sha256"])
    # depth histogram of even syndromes from brute depth
    hist = {}
    for s in range(1 << rho):
        if bin(s).count("1") % 2 == 0:
            hist[str(B["depth"][s])] = hist.get(str(B["depth"][s]), 0) + 1
    res["hist"] = (hist == E["depth_hist_even"])
    ec = [E["F_size"], E.get("edges", 0)] + [E.get("c%d" % j, 0) for j in range(3, m + 1)]
    ec = ec[:m]
    cl = B["c_literal"]; cmx = B["c_matrix"]
    res["counts_vs_literal"] = (ec == cl)
    valid_parent = B["min_distance_K"] >= D
    res["counts_vs_matrix"] = (ec == cmx) if valid_parent else (cmx == [0] * m)
    el = E["solution_list"]
    res["sol_vs_literal"] = (el == B["solutions_literal"] and E["solutions"] == len(el) == cl[m - 1] and "solution_list_truncated" not in E)
    res["sol_vs_matrix"] = (el == B["solutions_matrix"]) if valid_parent else (B["solutions_matrix"] == [])
    ok = all(res.values())
    return dict(name=name, w=w, D=D, kappa=kappa, N=N, rho=rho, kind=kind, dK=B["min_distance_K"], F=E["F_size"],
                counts=ec, nsol=len(el), res=res, ok=ok, t_ext=t_ext, t_br=t_br, valid=valid_parent,
                first=el[:2])

def main():
    seed = int(sys.argv[1]) if len(sys.argv) > 1 else 20261122
    sel = sys.argv[2] if len(sys.argv) > 2 else None
    rng = random.Random(seed)
    cases = []
    for i, spec in enumerate(SPECS):
        w, D, kappa, N, kind = spec
        rows = gen_rand(rng, kappa, N, D, kind)
        if rows is None:
            print("could not generate", spec, file=sys.stderr)
            continue
        cases.append((i, spec, rows, N))
    print("generated", len(cases), "cases", file=sys.stderr)
    out = []
    with ThreadPoolExecutor(3) as ex:
        futs = [ex.submit(do_case, i, spec, rows, N) for (i, spec, rows, N) in cases]
        for f in futs:
            r = f.result(); out.append(r)
            print(r["name"], r["w"], r["D"], r["kappa"], r["N"], r["kind"], "ok" if r["ok"] else "FAIL", r["counts"], "t_br=%.1f" % r["t_br"], file=sys.stderr, flush=True)
    # layering-only checks: rho 18..20
    lay = []
    rng2 = random.Random(seed + 1)
    for (kappa, N, D) in [(4, 22, 6), (5, 24, 8), (3, 23, 4)]:
        rows = gen_rand(rng2, kappa, N, 2, "rand") if False else None
        while rows is None:
            rows = []
            for _ in range(kappa):
                v = rng2.getrandbits(N)
                if bin(v).count("1") & 1: v ^= 1 << rng2.randrange(N)
                rows.append(v)
            if rank(rows) != kappa: rows = None
        name = "lay_rho%d" % (N - kappa)
        gen = os.path.join(CD, name + ".gen")
        with open(gen, "w") as f:
            for v in rows: f.write(to_str(v, N) + "\n")
        ed = os.path.join(CD, name + ".depth.bin"); bd = os.path.join(CD, name + ".brute_depth.bin")
        ej = os.path.join(CD, name + ".ext.json")
        t1 = run([EXT, gen, "2", str(D), ej, "--dump-depth", ed])
        t2 = run([BR, gen, "2", str(D), bd, "--depth-only"])
        same = open(ed, "rb").read() == open(bd, "rb").read()
        E = json.load(open(ej))
        lay.append((name, kappa, N, N - kappa, E["min_distance_K"], same, t1, t2, E["depth_hist_even"]))
        print(name, "same" if same else "DIFF", file=sys.stderr, flush=True)
    # report
    L = []
    L.append("# Validation report: extsearch.c vs brute.c\n")
    L.append("Generated by `validate.py` (seed %d). Each small instance: extsearch (layering, clique search) vs brute.c (true-matrix min distance over all 2^(kappa+j) codewords for every j-subset of all nonzero syndromes, and a literal-definition check with brute-force depths).\n" % seed)
    L.append("Checks: **lab**=pivots/free equal; **dK**=min distance of K; **depth**=depth of every syndrome (extsearch --dump-depth vs brute); **F**=F set + sha256; **hist**=even depth histogram; **cnt-lit**=(F_size,edges,c3..) vs brute literal counts; **cnt-mat**=vs true-matrix counts (valid parent dK>=D) or matrix counts all 0 (dK<D); **sol-lit**/**sol-mat**=complete solution list element by element (lex order).\n")
    L.append("`kind`: rand=random even code; rep=generator matrix with repeated columns; lowd=dK<D parent (matrix mode must give 0, literal mode checked vs spec).\n")
    L.append("| case | w | D | kappa | N | rho | kind | d(K) | |F| | counts (F,edges,c3..) | #sol | lab | dK | depth | F | hist | cnt-lit | cnt-mat | sol-lit | sol-mat | all |")
    L.append("|" + "---|" * 22)
    P = lambda b: "PASS" if b else "**FAIL**"
    for r in out:
        s = r["res"]
        L.append("| %s | %d | %d | %d | %d | %d | %s | %d | %d | %s | %d | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |" % (
            r["name"], r["w"], r["D"], r["kappa"], r["N"], r["rho"], r["kind"], r["dK"], r["F"], r["counts"], r["nsol"],
            P(s["labelling"]), P(s["dK"]), P(s["depth"]), P(s["F"] and s["sha"]), P(s["hist"]), P(s["counts_vs_literal"]), P(s["counts_vs_matrix"]),
            P(s["sol_vs_literal"]), P(s["sol_vs_matrix"]), P(r["ok"])))
    nne = sum(1 for r in out if r["nsol"] > 0); ne = sum(1 for r in out if r["nsol"] == 0)
    nvalid_ne = sum(1 for r in out if r["nsol"] > 0 and r["valid"])
    L.append("\nInstances: %d; non-empty solution list: %d (of which valid parents d(K)>=D: %d); empty: %d; all PASS: %s\n" % (len(out), nne, nvalid_ne, ne, all(r["ok"] for r in out)))
    L.append("By w: " + ", ".join("w=%d: %d" % (w, sum(1 for r in out if r["w"] == w)) for w in sorted(set(r["w"] for r in out))) + "\n")
    L.append("## Layering-only checks (extsearch depth for all 2^rho syndromes vs brute depth, w=2)\n")
    L.append("| case | kappa | N | rho | d(K) | depth identical | ext s | brute s | even depth hist |\n|---|---|---|---|---|---|---|---|---|")
    for (name, kappa, N, rho, dK, same, t1, t2, hist) in lay:
        L.append("| %s | %d | %d | %d | %d | %s | %.1f | %.1f | %s |" % (name, kappa, N, rho, dK, P(same), t1, t2, hist))
    L.append("")
    allok = all(r["ok"] for r in out) and all(x[5] for x in lay)
    L.append("**OVERALL: %s**\n" % ("ALL PASS" if allok else "FAILURES PRESENT"))
    open(os.path.join(VD, "REPORT.md"), "w").write("\n".join(L))
    print("OVERALL", "ALL PASS" if allok else "FAILURES", "nonempty", nne, "empty", ne)

main()
