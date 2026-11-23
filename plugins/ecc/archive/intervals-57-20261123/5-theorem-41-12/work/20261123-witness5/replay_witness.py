#!/usr/bin/env python3
"""replay_witness.py <gen> <witness.txt.gz>
Reads only the 7x36 generator file and witness lines `s1 s2 s3 s4 s5 kmask weight`.
Rebuilds leftmost-pivot RREF and x_s, forms the 12x42 generator rows
  [K|0...0 ; x_{s_i} | e_i + e_6] (i=1..5), builds the codeword for message
  (kmask bits on RREF rows, 1 on every head row), checks weight == stated < 16, nonzero.
"""
import gzip, sys

gen = [l.strip() for l in open(sys.argv[1]) if l.strip()]
n, k, W = len(gen[0]), len(gen), 6
v = [sum(1 << j for j, c in enumerate(r) if c == "1") for r in gen]
piv, r = [], 0
for col in range(n):
    sel = next((t for t in range(r, k) if v[t] >> col & 1), None)
    if sel is None:
        continue
    v[r], v[sel] = v[sel], v[r]
    for t in range(k):
        if t != r and v[t] >> col & 1:
            v[t] ^= v[r]
    piv.append(col); r += 1
assert r == k
free = [c for c in range(n) if c not in piv]
print("n=%d k=%d pivots=%s" % (n, k, piv))

ok = bad = 0
hist = {}
with gzip.open(sys.argv[2], "rt") as f:
    for line in f:
        a = line.split()
        if not a:
            continue
        s = [int(t) for t in a[:5]]; km = int(a[5]); wt = int(a[6])
        assert len(a) == 7 and 0 <= km < (1 << k)
        rows = list(v)                                  # K rows (tail zero)
        for i in range(5):
            x = 0
            for t, q in enumerate(free):
                if s[i] >> t & 1:
                    x |= 1 << q
            rows.append(x | (1 << (n + i)) | (1 << (n + W - 1)))
        u = [(km >> i) & 1 for i in range(k)] + [1] * 5
        cw = 0
        for i in range(k + 5):
            if u[i]:
                cw ^= rows[i]
        w = bin(cw).count("1")
        if cw != 0 and w == wt and w < 16 and cw >> (n + W) == 0:
            ok += 1; hist[w] = hist.get(w, 0) + 1
        else:
            bad += 1
            if bad <= 5:
                print("FAIL", line.strip(), "computed weight", w)
print("lines verified: %d, failed: %d" % (ok, bad))
print("weight histogram:", dict(sorted(hist.items())))
sys.exit(1 if bad else 0)
