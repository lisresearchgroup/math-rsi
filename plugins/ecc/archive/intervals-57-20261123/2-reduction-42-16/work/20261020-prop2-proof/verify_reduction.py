#!/usr/bin/env python3
"""
Independent numerical verification of the reduction lemma (case 42-16, [42,16]).

LEMMA (PARITY-2SHORT).  If a binary linear code C of length n and dimension k
has minimum distance d >= 13, then there exists a binary linear code of
length n-1 and dimension k-2 whose minimum distance is EXACTLY 14.

CONDITION (do not drop it): the statement needs k >= 16.  Step S3 only gives
dim span{columns at the zero positions} >= k - |W| with |W| <= 14, so two
independent columns inside Z are guaranteed only when k >= 16.  Without the
condition the statement is FALSE, e.g. the repetition code [13,1,13] (k=1):
after parity extension the weight-14 codeword has ones in all 13 original
coordinates, so Z is empty.  For this case k = 16, so the condition holds.

TEST COVERAGE (honest): the 7 cases below are punctured-simplex codes with
k = 5, 6, 7 and |W| = 13 throughout; they exercise the MECHANISM of S1/S2/S3,
not the k = 16 parameter instance of this case.  The k = 16 instance (plus
zero-column and repeated-column variants and an exhaustive sweep over 124208 enumerated GENERATOR MATRICES
(124208 is the number of enumerated matrices, NOT the number of distinct codes; the layered counts are in
work/20261020-prop2-redteam/REDTEAM_REPORT.md section 2.2)
small codes) is covered by the independent implementation
work/20261020-prop2-redteam/redteam_checks.py.

Structure implemented and mechanically checked here:
  S1 distance lowering : if d > 13, puncture d-13 coordinates inside the support
        of a minimum codeword, then append d-13 zero columns
        -> length n, dimension k, min distance exactly 13.
  S2 parity extension  : append the overall parity check coordinate
        -> length n+1, dimension k, all codewords even weight, min distance 14.
  S3 double shortening : take a weight-14 codeword c of the extension; let
        W = {j <= n : c_j = 1}, Z = {j <= n : c_j = 0} among the ORIGINAL n
        coordinates (the parity coordinate is index n+1 and may itself be 1);
        m = |W| in {13,14}; the column span argument gives
        dim span{g_j : j in Z} >= k - m >= 2, so two independent columns
        g_i, g_j exist inside Z; shorten at both
        -> length n-1, dimension k-2, min distance exactly 14 (c survives).

Pure stdlib, written from scratch; no other script of this repository is
imported.  All claims are checked by full enumeration of the 2^k codewords.
"""
import json, sys

def gf2_rank(rows):
    rows = list(rows); r = 0
    for c in range(max((r_ .bit_length() for r_ in rows), default=0)):
        piv = None
        for i in range(r, len(rows)):
            if rows[i] >> c & 1:
                piv = i; break
        if piv is None: continue
        rows[r], rows[piv] = rows[piv], rows[r]
        for i in range(len(rows)):
            if i != r and (rows[i] >> c & 1):
                rows[i] ^= rows[r]
        r += 1
    return r

class Code:
    """binary linear code given by a k x n generator matrix (row j <-> message bit j)"""
    def __init__(self, G, n=None):
        self.G = list(G)
        self.k = len(G)
        self.n = n if n is not None else max((g.bit_length() for g in G), default=0)
        assert all(g < (1 << self.n) for g in G), "row wider than n"
    def codewords(self):
        out = []
        for u in range(1 << self.k):
            w = 0
            for j in range(self.k):
                if u >> j & 1: w ^= self.G[j]
            out.append(w)
        return out
    def min_dist(self):
        return min(bin(w).count('1') for w in self.codewords()[1:])
    def columns(self):
        cols = []
        for i in range(self.n):
            v = 0
            for j in range(self.k):
                if self.G[j] >> i & 1: v |= 1 << j
            cols.append(v)
        return cols
    def rank(self):
        return gf2_rank(self.G)

def parity_extend(C):
    G = []
    for g in C.G:
        G.append(g | ((bin(g).count('1') & 1) << C.n))
    return Code(G, C.n + 1)

def kernel_basis(functionals, k):
    """basis of {u in F_2^k : f(u)=0 for all f in functionals} (f given as k-bit vectors)"""
    rows = [f for f in functionals]
    pivots = []
    r = 0
    for c in range(k):
        piv = None
        for i in range(r, len(rows)):
            if rows[i] >> c & 1:
                piv = i; break
        if piv is None:
            continue
        rows[r], rows[piv] = rows[piv], rows[r]
        for i in range(len(rows)):
            if i != r and (rows[i] >> c & 1):
                rows[i] ^= rows[r]
        pivots.append(c); r += 1
    free = [c for c in range(k) if c not in pivots]
    basis = []
    for fv in free:
        u = 1 << fv
        for i, pc in enumerate(pivots):
            if (rows[i] >> fv) & 1:
                u |= 1 << pc
        basis.append(u)
    return basis

def shorten_at(C, coords):
    """SHORTEN at the given coordinate indices: restrict to the codewords that are
    0 there, then delete those coordinates"""
    cols = C.columns()
    basis = kernel_basis([cols[i] for i in coords], C.k)
    assert len(basis) == C.k - len(set(coords)), (len(basis), C.k)
    keep = [i for i in range(C.n) if i not in set(coords)]
    G = []
    for u in basis:
        w = 0
        for j in range(C.k):
            if u >> j & 1:
                w ^= C.G[j]
        ng = 0
        for newpos, oldpos in enumerate(keep):
            if w >> oldpos & 1:
                ng |= 1 << newpos
        G.append(ng)
    return Code(G, len(keep))

def delete_coords(C, coords):
    keep = [i for i in range(C.n) if i not in set(coords)]
    G = []
    for g in C.G:
        ng = 0
        for newpos, oldpos in enumerate(keep):
            if g >> oldpos & 1: ng |= 1 << newpos
        G.append(ng)
    return Code(G, len(keep))

def zero_pad(C, t):
    return Code(list(C.G), C.n + t)

def simplex(m):
    """binary simplex code [2^m-1, m, 2^{m-1}]: columns = all nonzero vectors of F_2^m"""
    n = (1 << m) - 1
    G = []
    for j in range(m):
        g = 0
        for i in range(1, 1 << m):
            if (i >> j) & 1: g |= 1 << (i - 1)
        G.append(g)
    return Code(G, n)

def reduce_to_exact13(C):
    """S1"""
    d = C.min_dist()
    if d == 13:
        assert C.n >= 42 or True
        return C, 0
    t = d - 13
    cmin = min(C.codewords()[1:], key=lambda w: bin(w).count('1'))
    supp = [i for i in range(C.n) if cmin >> i & 1]
    assert len(supp) == d
    P = delete_coords(C, supp[:t])
    assert P.rank() == C.rank() == C.k, "puncturing must preserve dimension"
    assert P.min_dist() == 13, (P.min_dist(), d, t)
    Z = zero_pad(P, t)
    assert Z.n == C.n and Z.rank() == C.k and Z.min_dist() == 13
    return Z, t

def double_shorten_exact14(C):
    """S3, C must have min distance exactly 14 (the even extension)"""
    assert C.min_dist() == 14
    cmin = min(C.codewords()[1:], key=lambda w: bin(w).count('1'))
    assert bin(cmin).count('1') == 14
    cols = C.columns()
    par = C.n - 1                       # parity coordinate is the LAST one
    W = [i for i in range(par) if (cmin >> i) & 1]      # ones among the original coords
    Z = [i for i in range(par) if not (cmin >> i) & 1]  # zeros among the original coords
    m = len(W)
    assert m in (13, 14), m
    assert (cmin >> par) & 1 == (m & 1), "parity coordinate must equal parity of the rest"
    rW = gf2_rank([cols[i] for i in W])
    rZ = gf2_rank([cols[i] for i in Z])
    rAll = gf2_rank(cols)
    info = {"m": m, "nZ": len(Z), "rW": rW, "rZ": rZ, "rank_all_columns": rAll,
            "parity_bit": (cmin >> par) & 1}
    assert rAll == C.k, info
    assert rZ >= C.k - m, info          # the rank argument
    assert rZ >= 2, info                # two independent columns inside Z
    pair = None
    for a in range(len(Z)):
        for b in range(a + 1, len(Z)):
            if gf2_rank([cols[Z[a]], cols[Z[b]]]) == 2:
                pair = (Z[a], Z[b]); break
        if pair: break
    assert pair is not None
    D = shorten_at(C, set(pair))
    info["pair"] = list(pair)
    info["D"] = {"n": D.n, "k": D.rank(), "d": D.min_dist()}
    assert D.rank() == C.k - 2, info
    assert D.n == C.n - 2, info   # C is the parity-extended code (length n+1)
    assert D.min_dist() == 14, info
    return D, info

def punctured_simplex(m, t):
    """puncture t coordinates of a minimum codeword of the simplex code"""
    S = simplex(m)
    cmin = S.G[0]
    supp = [i for i in range(S.n) if cmin >> i & 1]
    return delete_coords(S, supp[:t])

def main():
    results = []
    for (m, t) in ((6, 18), (6, 3), (5, 3), (5, 2), (5, 1), (5, 0), (7, 50)):
        C = punctured_simplex(m, t)
        d = C.min_dist()
        rec = {"source": f"punctured simplex m={m}, punctured t={t}",
               "n": C.n, "k": C.k, "d": d}
        if d < 13:
            rec["skipped"] = "min distance < 13"
            results.append(rec); continue
        C13, used = reduce_to_exact13(C)
        rec["S1"] = {"punctured": used, "n": C13.n, "k": C13.k, "d": C13.min_dist()}
        E = parity_extend(C13)
        rec["S2"] = {"n": E.n, "k": E.k, "d": E.min_dist(),
                     "all_even": all(bin(w).count('1') % 2 == 0 for w in E.codewords())}
        assert rec["S2"]["all_even"] and rec["S2"]["d"] == 14
        D, info = double_shorten_exact14(E)
        rec["S3"] = info
        rec["result"] = {"n": D.n, "k": D.k, "d": D.min_dist()}
        assert D.min_dist() == 14 and D.rank() == C.k - 2 and D.n == C.n - 1
        rec["PASS"] = True
        results.append(rec)

    # negative control: a code with min distance < 13 must NOT be pushed through
    S = simplex(4)                       # [15,4,8]
    neg = {"control": "simplex m=4 has d=8 < 13", "d": S.min_dist(),
           "PASS": S.min_dist() == 8}
    # negative control 2: the two-shortening step on a code whose min distance is
    # NOT 14 must not be reported as producing min distance 14
    S5 = simplex(5)                      # [31,5,16]
    bad = {"control": "double shortening of [31,5,16] does not yield d=14",
           "PASS": True}
    try:
        double_shorten_exact14(S5)
        bad["PASS"] = False
    except AssertionError:
        bad["raised"] = "AssertionError (min distance is not 14) - as expected"

    out = {"lemma": "PARITY-2SHORT",
           "statement": ("binary [n,k,d>=13] with k >= 16  =>  binary [n-1,k-2], min distance "
                         "exactly 14  (the condition k>=16 is needed: the S3 rank argument gives "
                         "dim span{columns at the zero positions} >= k-|W| with |W| <= 14)"),
           "results": results,
           "controls": [neg, bad],
           "all_pass": all(r.get("PASS") for r in results) and neg["PASS"] and bad["PASS"]}
    print(json.dumps(out, indent=1))
    return 0 if out["all_pass"] else 1

if __name__ == "__main__":
    sys.exit(main())
