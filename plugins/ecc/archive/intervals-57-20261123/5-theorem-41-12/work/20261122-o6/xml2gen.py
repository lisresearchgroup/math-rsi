#!/usr/bin/env python3
"""Make generator matrix of K = nullspace of the parity-check rows found in magma_*.xml (rows = <line> entries of length N)."""
import re, sys
xml, out = sys.argv[1], sys.argv[2]
s = open(xml).read()
L = re.findall(r"<line>(.*?)</line>", s)
H = [l for l in L if re.fullmatch(r"[01]+", l)]
N = len(H[0]); assert all(len(h) == N for h in H)
rows = [sum(1 << c for c in range(N) if h[c] == "1") for h in H]
# row-reduce H, nullspace
piv = []; R = []
for c in range(N):
    r = next((i for i in range(len(piv), len(rows)) if rows[i] >> c & 1), None)
    if r is None: continue
    k = len(piv); rows[k], rows[r] = rows[r], rows[k]
    for i in range(len(rows)):
        if i != k and rows[i] >> c & 1: rows[i] ^= rows[k]
    piv.append(c)
free = [c for c in range(N) if c not in piv]
G = []
for f in free:
    v = 1 << f
    for i, p in enumerate(piv):
        if rows[i] >> f & 1: v |= 1 << p
    G.append(v)
# verify G * H^T = 0
for g in G:
    for h in H:
        hv = sum(1 << c for c in range(N) if h[c] == "1")
        assert bin(g & hv).count("1") % 2 == 0
print("N=%d rank(H)=%d kappa=%d" % (N, len(piv), len(G)), file=sys.stderr)
with open(out, "w") as f:
    for g in G: f.write("".join("1" if g >> c & 1 else "0" for c in range(N)) + "\n")
