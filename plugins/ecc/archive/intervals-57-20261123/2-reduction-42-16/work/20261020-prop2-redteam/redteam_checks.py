#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
RED-TEAM self-checks for the reduction lemma PARITY-2SHORT  (case 42-16).

LEMMA UNDER ATTACK (task statement):
    If a binary linear code C subset F_2^42, dim 16, min distance d >= 13 exists,
    then a binary linear code D subset F_2^41, dim 14, min distance EXACTLY 14 exists.

DRAFT PROOF UNDER ATTACK (S1/S2/S3) and the MECHANICAL CRITERIA checked here:

  S1 (distance lowering).  tau = 13, c a minimum weight codeword (wt = d).
      If d > tau: pick T subset supp(c), |T| = d - tau, puncture T, re-insert
      |T| zero columns.
        (S1.a) puncturing on T is injective      -> dimension k is preserved;
        (S1.b) min distance of the punctured code >= d - |T| = tau;
        (S1.c) min distance of the punctured code <= wt(c^T) = tau;
        (S1.d) after re-inserting the zero columns: length n, rank k, min distance tau.
  S2 (parity extension).  C^e = {(x, sum x_i)} subset F_2^{n+1}.
        (S2.a) every codeword of C^e has EVEN weight;
        (S2.b) min distance of C^e = smallest even integer >= d;
        (S2.c) rank preserved, length n+1;
        (S2.d) the parity column equals the sum of the n data columns.
  S3 (double shortening).  c a MINIMUM weight codeword of C^e (weight d' = 14);
      W = {j <= n : c_j = 1}, Z = {j <= n : c_j = 0}; the parity coordinate n+1 may
      itself be 1 (then |W| = 13, not 14!).
        (S3.a) wt(c) = d' and parity bit == |W| mod 2;
        (S3.b) rank of the n+1 generator columns == k;
        (S3.c) column-span argument: dim span{col_j : j in Z} >= k - |W|;
        (S3.d) dim span{col_j : j in Z} >= 2  (TWO INDEPENDENT columns inside Z);
        (S3.e) shortening at that pair gives dimension EXACTLY k-2;
        (S3.f) shortened code: length n+1-2, min distance EXACTLY d';
        (S3.g) the minimum weight codeword c survives the shortening (witness);
        (S3.h) an even extension yields an even shortened code.
      Also recorded: the draft's literal counting claim "|W| = 14 and |Z| = 28"
      (which requires the parity coordinate of c to be 0).

INDEPENDENCE: written from scratch, pure standard library, imports nothing else in
this repository.  Two independent GF(2) rank routines are cross-checked on every call.

DELIBERATE BREAKS (mutants) are pushed through the SAME criteria to demonstrate that
the checks have discriminating power (see run_mutants()).
"""
import json
import os
import random
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))

# --------------------------------------------------------------------------
# GF(2) primitives (two independent rank implementations, cross-checked)
# --------------------------------------------------------------------------


def rank_row_echelon(vs):
    """rank of a list of ints (bit i = coordinate i) by row echelon over GF(2)."""
    rows = list(vs)
    r = 0
    for c in range(max((x.bit_length() for x in rows), default=0)):
        piv = None
        for i in range(r, len(rows)):
            if (rows[i] >> c) & 1:
                piv = i
                break
        if piv is None:
            continue
        rows[r], rows[piv] = rows[piv], rows[r]
        for i in range(len(rows)):
            if i != r and ((rows[i] >> c) & 1):
                rows[i] ^= rows[r]
        r += 1
    return r


def rank_col_echelon(vs):
    """rank of a list of ints interpreted as COLUMNS (independent routine: transpose)."""
    if not vs:
        return 0
    width = max(v.bit_length() for v in vs)
    trows = []
    for b in range(width):
        v = 0
        for i, c in enumerate(vs):
            if (c >> b) & 1:
                v |= 1 << i
        trows.append(v)
    return rank_row_echelon(trows)


def gf2_rank(vs):
    a = rank_row_echelon(vs)
    b = rank_col_echelon(vs)
    assert a == b, ("rank routines disagree", a, b, vs)
    return a


def nullspace(rows, nvars):
    """basis (ints over nvars bits) of {x : rows . x = 0}."""
    rws = list(rows)
    pivots = []
    r = 0
    for c in range(nvars):
        piv = None
        for i in range(r, len(rws)):
            if (rws[i] >> c) & 1:
                piv = i
                break
        if piv is None:
            continue
        rws[r], rws[piv] = rws[piv], rws[r]
        for i in range(len(rws)):
            if i != r and ((rws[i] >> c) & 1):
                rws[i] ^= rws[r]
        pivots.append(c)
        r += 1
    free = [c for c in range(nvars) if c not in pivots]
    basis = []
    for fv in free:
        x = 1 << fv
        for i, pc in enumerate(pivots):
            if (rws[i] >> fv) & 1:
                x |= 1 << pc
        basis.append(x)
    return basis


class Code:
    """binary linear code: k rows (row j selected by message bit j), n coordinates."""

    def __init__(self, rows, n=None):
        self.rows = [int(r) for r in rows]
        self.k = len(self.rows)
        self.n = n if n is not None else max((r.bit_length() for r in self.rows), default=0)
        for r in self.rows:
            assert 0 <= r < (1 << self.n), "row wider than n"

    def codewords(self):
        """all 2^k codewords, built by the doubling method (set is order independent)."""
        out = [0]
        for r in self.rows:
            out = out + [w ^ r for w in out]
        return out

    def nonzero_weights(self):
        return [bin(w).count("1") for w in self.codewords()[1:]]

    def min_dist(self):
        return min(self.nonzero_weights())

    def spectrum(self):
        sp = {}
        for w in self.nonzero_weights():
            sp[w] = sp.get(w, 0) + 1
        return dict(sorted(sp.items()))

    def rank(self):
        return gf2_rank(self.rows)

    def columns(self):
        cols = []
        for i in range(self.n):
            v = 0
            for j in range(self.k):
                if (self.rows[j] >> i) & 1:
                    v |= 1 << j
            cols.append(v)
        return cols

    @staticmethod
    def weight(w):
        return bin(w).count("1")

    def support(self, w):
        return [i for i in range(self.n) if (w >> i) & 1]

    def all_even(self):
        return all((bin(w).count("1") % 2) == 0 for w in self.codewords())


# ------------------------- coordinate operations --------------------------


def duplicate_first_column(code):
    """TRUE repeated NONZERO column: column 0 is repeated at the end
    (length n -> n+1, same code space)."""
    rows = [r | (((r >> 0) & 1) << code.n) for r in code.rows]
    return Code(rows, code.n + 1)

def duplicate_last_column(code):
    """TRUE repeated column: the last column of the generator is repeated once
    (length n -> n+1, same code space, dimension unchanged).
    NOTE: an earlier version of this script used `Code(list(rows)+[rows[0]], n)`,
    which duplicates a ROW (not a column) and makes the zero codeword appear
    twice in codewords()[1:], which corrupts min-distance bookkeeping.  That
    construction produced two spurious 'FAIL' rows; they were a script artifact,
    not counterexamples to the lemma."""
    rows = [r | (((r >> (code.n - 1)) & 1) << code.n) for r in code.rows]
    return Code(rows, code.n + 1)

def delete_coords(rows, n, coords):
    drop = set(coords)
    keep = [i for i in range(n) if i not in drop]
    out = []
    for r in rows:
        v = 0
        for newpos, oldpos in enumerate(keep):
            if (r >> oldpos) & 1:
                v |= 1 << newpos
        out.append(v)
    return Code(out, len(keep))


def zero_extend(code, t):
    """append t zero columns (length grows, no weight changes)."""
    return Code(list(code.rows), code.n + t)


def parity_extend(code):
    """C^e = {(x, sum x_i)}: append the overall parity check coordinate."""
    rows = []
    for r in code.rows:
        rows.append(r | ((bin(r).count("1") & 1) << code.n))
    return Code(rows, code.n + 1)


def shorten(code, coords):
    """shorten at the given coordinate indices: keep the codewords that are 0 there,
    then delete those coordinates."""
    cols = code.columns()
    basis = nullspace([cols[i] for i in coords], code.k)
    rows = []
    for u in basis:
        w = 0
        j = 0
        uu = u
        while uu:
            if uu & 1:
                w ^= code.rows[j]
            uu >>= 1
            j += 1
        rows.append(w)
    return delete_coords(rows, code.n, coords)


# ----------------------------- the three steps ----------------------------


def step_S1(code, tau=13, mutant=None):
    """distance lowering to exactly tau."""
    rec = {"step": "S1", "n_in": code.n, "k": code.k, "tau": tau}
    crit = {}
    d = code.min_dist()
    rec["d_in"] = d
    if d < tau:
        rec["skipped"] = "d < tau"
        rec["criteria"] = crit
        return code, rec, crit
    t = d - tau
    if t == 0:
        rec["punctured"] = 0
        out = code
        rec["criteria"] = crit
        return out, rec, crit
    cmin = min(code.codewords()[1:], key=lambda w: bin(w).count("1"))
    supp = code.support(cmin)
    assert len(supp) == d
    if mutant == "puncture_outside_support":
        # DELIBERATE BREAK: puncture coordinates OUTSIDE supp(c); then the image of c
        # still has weight d > tau and the min distance stays tau+1.
        outside = [i for i in range(code.n) if i not in set(supp)]
        T = outside[:t]
    else:
        T = supp[:t]
    rec["T"] = T
    rec["T_inside_support"] = set(T) <= set(supp)
    P = delete_coords(code.rows, code.n, T)
    rec["punctured"] = t
    crit["S1.a_dim_preserved"] = (P.rank() == code.rank() == code.k)
    pd = P.min_dist()
    crit["S1.b_lower_bound"] = (pd >= d - t)
    crit["S1.c_upper_bound_minword"] = (pd <= (d - t))
    rec["punctured_min_dist"] = pd
    out = zero_extend(P, t)
    crit["S1.d_zeropad_params"] = (out.n == code.n and out.rank() == code.k
                                   and out.min_dist() == tau)
    rec["after_min_dist"] = out.min_dist()
    rec["criteria"] = crit
    return out, rec, crit


def step_S2(code, mutant=None):
    """parity extension."""
    rec = {"step": "S2", "n_in": code.n, "k": code.k}
    crit = {}
    if mutant == "no_extension":
        out = code
        rec["mutant"] = mutant
        crit["S2.a_all_even"] = code.all_even()
        d = code.min_dist()
        crit["S2.b_min_dist_is_even_roundup"] = (d == d + (d % 2))
        crit["S2.c_rank_length"] = (code.rank() == code.k and code.n == code.n)
        rec["mutated"] = True
        rec["criteria"] = crit
        return out, rec, crit
    E = parity_extend(code)
    rec["n_out"] = E.n
    rec["min_dist"] = E.min_dist()
    crit["S2.a_all_even"] = E.all_even()
    d = code.min_dist()
    crit["S2.b_min_dist_is_even_roundup"] = (E.min_dist() == d + (d % 2))
    crit["S2.c_rank_length"] = (E.rank() == code.rank() == code.k and E.n == code.n + 1)
    cols = E.columns()
    par = 0
    for c in cols[:code.n]:
        par ^= c
    crit["S2.d_parity_column_is_column_sum"] = (par == cols[code.n])
    rec["criteria"] = crit
    return E, rec, crit


def step_S3(E, mutant=None, n_data=None, min_word=None):
    """double shortening of the (even) extension E of length n_data+1."""
    rec = {"step": "S3", "n_in": E.n, "k": E.k}
    crit = {}
    n = n_data if n_data is not None else E.n - 1
    cols = E.columns()
    rec["rank_of_columns"] = gf2_rank(cols)
    crit["S3.b_rank_of_columns_is_k"] = (rec["rank_of_columns"] == E.k)
    dmin = E.min_dist()
    rec["min_dist_of_extension"] = dmin

    if min_word is None:
        cands = [w for w in E.codewords()[1:] if E.weight(w) == dmin]
        min_word = cands[0]
    c = min_word
    rec["witness_weight"] = E.weight(c)
    crit["S3.a_witness_is_min_weight"] = (E.weight(c) == dmin)
    W = [i for i in range(n) if (c >> i) & 1]
    Z = [i for i in range(n) if not ((c >> i) & 1)]
    m = len(W)
    par_bit = (c >> n) & 1
    rec["W_size"] = m
    rec["Z_size"] = len(Z)
    rec["parity_bit"] = par_bit
    crit["S3.a_parity_bit_consistent"] = (par_bit == (m % 2))
    # the draft's literal counting claim (requires the parity coordinate of c to be 0)
    rec["draft_claim_W_eq_14_and_Z_eq_28"] = (m == 14 and len(Z) == 28)

    rW = gf2_rank([cols[i] for i in W])
    rZ = gf2_rank([cols[i] for i in Z])
    rAll = rec["rank_of_columns"]
    rec["rW"] = rW
    rec["rZ"] = rZ
    crit["S3.c_span_argument"] = (rZ >= rAll - rW) and (rZ >= rAll - m)
    crit["S3.d_two_independent_columns_in_Z"] = (rZ >= 2)

    pair = None
    if mutant == "first_two_Z_columns":
        # DELIBERATE BREAK: take the first two columns of Z without checking
        # independence (fails when one of them is a zero column).
        pair = (Z[0], Z[1]) if len(Z) >= 2 else None
    elif mutant == "any_two_columns":
        # DELIBERATE BREAK: take an arbitrary coordinate pair, ignoring Z.
        pair = (0, 1) if E.n >= 2 else None
    else:
        for a in range(len(Z)):
            for b in range(a + 1, len(Z)):
                if gf2_rank([cols[Z[a]], cols[Z[b]]]) == 2:
                    pair = (Z[a], Z[b])
                    break
            if pair:
                break
    rec["pair"] = list(pair) if pair else None
    if pair is None:
        crit["S3.e_dim_exactly_k_minus_2"] = False
        crit["S3.f_params"] = False
        crit["S3.g_witness_survives"] = False
        crit["S3.h_shortened_is_even"] = False
        rec["criteria"] = crit
        return None, rec, crit
    # FIX 2026-10-20 (outer review): the previous version forced
    # crit["S3.d_two_independent_columns_in_Z"] = False whenever a mutant flag was on.
    # That was an ARTIFICIAL failure and could not demonstrate discriminating power.
    # Now every criterion is computed from the actual data (column rank, witness
    # survival, output parameters); a mutant is detected only if a real check fails.
    crit["S3.d_two_independent_columns_in_Z"] = (rZ >= 2)
    crit["S3.pair_is_independent"] = (gf2_rank([cols[pair[0]], cols[pair[1]]]) == 2)
    D = shorten(E, list(pair))
    rec["D_n"] = D.n
    rec["D_k"] = D.rank()
    rec["D_min_dist"] = D.min_dist() if D.k > 0 else None
    crit["S3.e_dim_exactly_k_minus_2"] = (D.rank() == E.k - 2)
    crit["S3.f_params"] = (D.n == E.n - 2 and (D.k == 0 or D.min_dist() == dmin))
    surv = ((c >> pair[0]) & 1) == 0 and ((c >> pair[1]) & 1) == 0
    crit["S3.g_witness_survives"] = surv
    if D.k > 0:
        cw = [D.weight(w) for w in D.codewords()[1:]]
        crit["S3.f_witness_weight_in_D"] = (min(cw) == dmin and dmin in cw)
        crit["S3.h_shortened_is_even"] = D.all_even()
    else:
        crit["S3.f_witness_weight_in_D"] = False
        crit["S3.h_shortened_is_even"] = True
    rec["criteria"] = crit
    return D, rec, crit


# --------------------------- test code constructions ----------------------


def simplex_code(m):
    """binary simplex code [2^m-1, m, 2^(m-1)]; columns = all nonzero vectors."""
    n = (1 << m) - 1
    rows = []
    for j in range(m):
        r = 0
        for i in range(1, 1 << m):
            if (i >> j) & 1:
                r |= 1 << (i - 1)
        rows.append(r)
    return Code(rows, n)


def extended_simplex_code(m):
    """[2^m, m, 2^(m-1)]; columns = ALL vectors of F_2^m (the last one is zero)."""
    n = 1 << m
    rows = []
    for j in range(m):
        r = 0
        for i in range(1 << m):
            if (i >> j) & 1:
                r |= 1 << i
        rows.append(r)
    return Code(rows, n)


def hamming_code(r):
    """binary Hamming code [2^r-1, 2^r-1-r, 3]: parity check matrix = all nonzero
    r-bit columns; systematic generator [I_k | P] with the identity block on the
    non-pivot (multi-bit) columns and the parity block on the single-bit columns."""
    n = (1 << r) - 1
    allcols = list(range(1, 1 << r))
    pivots = [c for c in allcols if bin(c).count("1") == 1]
    frees = [c for c in allcols if bin(c).count("1") > 1]
    kk = len(frees)
    G = []
    for j, col in enumerate(frees):
        row = 1 << j                       # identity block (positions 0..kk-1)
        for b in range(r):                # parity block (positions kk..n-1)
            if (col >> b) & 1:
                row |= 1 << (kk + b)
        G.append(row)
    return Code(G, n)


def bch_127_rows(nrows=16):
    """primitive narrow-sense binary BCH code of length 127, designed distance 13
       (generator = product of the minimal polynomials of alpha^1..alpha^12 over
       GF(2^7)); returns the first `nrows` rows of a generator matrix of a
       16-dimensional subcode => a genuine [127,16,>=13] binary linear code."""
    m = 7
    mod = 0b10001001            # x^7 + x^3 + 1 (primitive)
    mask = (1 << m) - 1

    def fmul(a, b):
        r = 0
        while b:
            if b & 1:
                r ^= a
            b >>= 1
            a <<= 1
            if a >> m:
                a ^= mod
        return r & mask

    roots = set()
    for s in range(1, 13):
        c = s
        while c not in roots:
            roots.add(c)
            c = (c * 2) % 127
    alphas = {}
    a = 1
    for j in range(127):
        alphas[j] = a
        a = fmul(a, 2)          # multiply by x
    assert a == 1, "x must be primitive mod the chosen polynomial"

    def pmul(p, q):
        r = [0] * (len(p) + len(q) - 1)
        for i, ci in enumerate(p):
            if ci == 0:
                continue
            for j, cj in enumerate(q):
                if cj:
                    r[i + j] ^= fmul(ci, cj)
        return r

    g = [1]
    for j in sorted(roots):
        g = pmul(g, [alphas[j], 1])      # (x + alpha^j)
    assert all(c in (0, 1) for c in g), "generator polynomial must have binary coefficients"
    deg = len(g) - 1
    assert deg == 42, deg
    rows = []
    for i in range(nrows):
        row = 0
        for t, c in enumerate(g):
            if c:
                row |= 1 << (t + i)
        rows.append(row)
    return Code(rows, 127)


def all_binary_codes(k, n):
    """exhaustively enumerate all k x n binary generator matrices."""
    for bits in range(1 << (k * n)):
        rows = []
        for j in range(k):
            r = 0
            for i in range(n):
                if (bits >> (j * n + i)) & 1:
                    r |= 1 << i
            rows.append(r)
        yield Code(rows, n)


# ------------------------------- the checks -------------------------------


def step_failures(rec, crit, prefix):
    out = []
    for kk, vv in crit.items():
        if kk.startswith(prefix) and vv is not True:
            out.append(kk)
    return out


def run_chain(code, tau=13, mutants=(), label="", note=None):
    """Run S1 -> S2 -> S3 with the given mutants; return (record, failures)."""
    rec = {"label": label, "input": {"n": code.n, "k": code.k, "d": code.min_dist()}}
    if note:
        rec["note"] = note
    fails = []
    C1, r1, c1 = step_S1(code, tau=tau,
                          mutant="puncture_outside_support"
                          if "S1_puncture_outside" in mutants else None)
    rec["S1"] = r1
    f1 = step_failures(r1, c1, "S1.")
    fails += [(label + "/S1", x, c1[x]) for x in f1]
    C2, r2, c2 = step_S2(C1, mutant="no_extension" if "S2_no_extension" in mutants else None)
    rec["S2"] = r2
    f2 = step_failures(r2, c2, "S2.")
    fails += [(label + "/S2", x, c2[x]) for x in f2]
    D, r3, c3 = step_S3(C2, mutant=("first_two_Z_columns"
                                    if "S3_first_two_Z" in mutants else
                                    ("any_two_columns" if "S3_any_two" in mutants else None)),
                        n_data=code.n)
    rec["S3"] = r3
    f3 = step_failures(r3, c3, "S3.")
    fails += [(label + "/S3", x, c3[x]) for x in f3]
    rec["failures"] = fails
    rec["PASS"] = (len(fails) == 0)
    return rec, fails


def run_mutants(bch, bch_leadzero, simplex16, tau=13):
    """Each mutant must be DETECTED by the criteria of its own step."""
    out = []
    specs = [
        ("S1_puncture_outside", "S1", simplex16,
         "S1 punctures coordinates OUTSIDE supp(c): the upper bound wt(c^T) = tau breaks"),
        ("S2_no_extension", "S2", bch,
         "S2 omits the parity extension: the min distance stays tau instead of tau+1"),
        ("S3_first_two_Z", "S3", bch_leadzero,
         "S3 takes the first two columns of Z without checking independence "
         "(a leading zero column makes them dependent)"),
        ("S3_any_two", "S3", bch_leadzero,
         "S3 takes an arbitrary coordinate pair instead of a pair inside Z"),
    ]
    for mut, step, inst, desc in specs:
        rec, fails = run_chain(inst, tau=tau, mutants=(mut,), label="mutant:" + mut)
        own = [f[1] for f in fails if f[0].endswith("/" + step)]
        out.append({"mutant": mut, "step": step, "description": desc,
                    "detected": len(own) > 0,
                    "failing_criteria_of_own_step": own[:6],
                    "n_failures_total": len(fails)})
    return out


def main():
    t0 = time.time()
    out = {"lemma": "PARITY-2SHORT",
           "statement": "binary [42,16,d>=13]  =>  binary [41,14, min distance EXACTLY 14]",
           "generated": time.strftime("%Y-%m-%dT%H:%M:%S"),
           "instances": [], "mutants": [], "exhaustive": {}, "random_search": {},
           "summary": {}}

    # ---- 1. real instances -------------------------------------------------
    inst = []

    # 1a. extended simplex [32,5,16]: S1 lowers 16 -> 13 (the "d > tau" path).
    #     NOTE (corrected 2026-10-20 after the Grok cross-family review): the
    #     written lower bound  dim span{Z} >= k - |W|  is too weak to certify
    #     rZ >= 2 when k < 16, but that does NOT mean the chain fails: for this
    #     instance the chain happens to succeed (rZ = 4).  k >= 16 is a
    #     SUFFICIENT condition used by the proof, not a necessary one.
    #     The genuine counterexample to the unrestricted statement is the
    #     k = 1 family (e.g. the repetition code [13,1,13]).
    S = extended_simplex_code(5)
    rec, _ = run_chain(S, tau=13, label="extended simplex [32,5,16]",
                       note="k=5 < 16: the sufficient condition is not met, but the chain "
                            "still succeeds here (rZ=4). k>=16 is sufficient, not necessary.")
    rec["k_below_sufficient_bound"] = True
    inst.append(rec)

    # 1b. same code + zero column / + repeated column (no projective assumption)
    Sz = Code(list(S.rows), S.n + 1)
    rec, _ = run_chain(Sz, tau=13, label="extended simplex + zero column",
                       note="EXPECTED S3 failure (k=5)")
    rec["k_below_sufficient_bound"] = True
    inst.append(rec)
    Sd = duplicate_last_column(S)
    rec, _ = run_chain(Sd, tau=13, label="extended simplex + repeated column",
                       note="EXPECTED S3 failure (k=5)")
    rec["k_below_sufficient_bound"] = True
    inst.append(rec)

    # 1c. Hamming [15,11,3] (odd d, k >= d+3): mechanism analogue with tau = d = 3.
    H = hamming_code(4)
    rec, _ = run_chain(H, tau=3, label="Hamming [15,11,3], tau=3 (analogue)",
                       note="mechanism analogue: d=3 odd, k=11 >= d+3=6")
    inst.append(rec)

    # 1d. BCH [127,16,>=13]: the EXACT parameter instance (k=16, d=13) of the lemma.
    B = bch_127_rows(16)
    rec, _ = run_chain(B, tau=13,
                       label="BCH [127,16,15] (k=16; S1 lowers 15 -> 13, the d=13 branch)",
                       note="k=16 and d=13: the parameters of the case, at length 127. "
                            "This is the only way to exercise S1/S2/S3 at k=16, d=13 "
                            "without assuming the (open) existence of a [42,16,13] code.")
    rec["input_spectrum"] = {str(a): b for a, b in B.spectrum().items()}
    inst.append(rec)

    # 1d-bis. the genuine [127,16,13] code obtained from S1 (S1 is a no-op on it):
    #          this is the d = 13 BRANCH of the case, exercised at k = 16.
    B13, _r, _c = step_S1(B, tau=13)
    rec, _ = run_chain(B13, tau=13,
                       label="genuine [127,16,13] (S1 output of the BCH subcode)",
                       note="S1 is a no-op here: the min distance is already exactly 13, "
                            "so this instance exercises the d=13 branch at k=16; the "
                            "minimum weight codeword of the extension has parity bit 1 "
                            "(|W| = 13), i.e. exactly the configuration in which the "
                            "draft's counting '|W| = 14, |Z| = 28' is false.")
    rec["input_spectrum"] = {str(a): b for a, b in B13.spectrum().items()}
    inst.append(rec)

    # 1e. BCH + trailing zero column / + repeated column.
    #     HONESTY NOTE (added 2026-10-20 after the outer review): the BCH generator
    #     used here has a ZERO last column, so duplicate_last_column() duplicates a
    #     ZERO column, not a nonzero one.  We therefore ALSO duplicate a NONZERO
    #     column (the first one) in a separate instance.
    Bz = Code(list(B.rows), B.n + 1)
    rec, _ = run_chain(Bz, tau=13, label="BCH + trailing zero column")
    inst.append(rec)
    Bd = duplicate_last_column(B)
    rec, _ = run_chain(Bd, tau=13,
                       label="BCH + repeated column (duplicates the ZERO last column)")
    rec["note"] = "the BCH generator's last column is zero -> this duplicates a zero column"
    inst.append(rec)
    Bdn = duplicate_first_column(B)
    rec, _ = run_chain(Bdn, tau=13,
                       label="BCH + repeated NONZERO column (duplicates column 0)")
    rec["note"] = "duplicates a nonzero column -> the two coordinates are dependent"
    inst.append(rec)

    # 1f. BCH + LEADING zero column (used as the mutant target)
    Bz0 = Code([r << 1 for r in B.rows], B.n + 1)
    rec, _ = run_chain(Bz0, tau=13, label="BCH + leading zero column")
    inst.append(rec)

    # 1g. every minimum weight codeword of the extension must admit a valid pair
    E = parity_extend(B)
    dmin = E.min_dist()
    cands = [w for w in E.codewords()[1:] if E.weight(w) == dmin]
    perword = []
    allok = True
    for c in cands:
        D, r3, c3 = step_S3(E, min_word=c, n_data=B.n)
        bad = [kk for kk, vv in c3.items() if kk.startswith("S3.") and vv is not True]
        allok = allok and (not bad)
        perword.append({"witness_weight": E.weight(c), "parity_bit": (c >> B.n) & 1,
                        "W_size": r3["W_size"], "Z_size": r3["Z_size"],
                        "rZ": r3["rZ"], "rW": r3["rW"],
                        "D_k": r3.get("D_k"), "D_n": r3.get("D_n"),
                        "D_min_dist": r3.get("D_min_dist"), "bad_criteria": bad})
    out["every_min_weight_word_of_extension"] = {
        "extension_min_dist": dmin, "n_min_words": len(cands),
        "records": perword[:8], "n_records": len(perword), "all_ok": allok}

    # 1h. the shortened code D produced at the exact parameters: full evidence.
    #     NOTE (corrected 2026-10-20 after the Grok cross-family review): E here is the
    #     parity extension of the RAW BCH code (d = 15), so its extension has d = 16 and
    #     |W| = 16 -- this is NOT the lemma's tau = 13 path.  The lemma's output is
    #     computed separately below from the S1 output B13 (d = 13).
    D, r3, c3 = step_S3(E, n_data=B.n)
    if D is not None:
        out["D_from_raw_bch_extension_NOT_the_tau13_path"] = {
            "n": D.n, "k": D.rank(), "min_dist": D.min_dist(),
            "spectrum": {str(a): b for a, b in D.spectrum().items()},
            "all_even": D.all_even(), "pair": r3.get("pair"),
            "rW": r3.get("rW"), "rZ": r3.get("rZ"),
            "W_size": r3.get("W_size"), "Z_size": r3.get("Z_size"),
            "parity_bit": r3.get("parity_bit"),
            "draft_claim_W_eq_14_and_Z_eq_28": r3.get("draft_claim_W_eq_14_and_Z_eq_28")}

    # 1i. THE lemma's tau = 13 path at the exact parameters k = 16:
    #     S1 output B13 (d = 13) -> parity extension -> double shortening.
    E13 = parity_extend(B13)
    D13, r13, c13 = step_S3(E13, n_data=B13.n)
    if D13 is not None:
        out["D_at_tau13_path_exact_parameters"] = {
            "input": "S1 output of the BCH [127,16,15] subcode, i.e. [127,16,13] (d exactly 13)",
            "extension_min_dist": E13.min_dist(),
            "n": D13.n, "k": D13.rank(), "min_dist": D13.min_dist(),
            "spectrum": {str(a): b for a, b in D13.spectrum().items()},
            "all_even": D13.all_even(), "pair": r13.get("pair"),
            "rW": r13.get("rW"), "rZ": r13.get("rZ"),
            "W_size": r13.get("W_size"), "Z_size": r13.get("Z_size"),
            "parity_bit": r13.get("parity_bit"),
            "all_criteria_pass": all(v is True for v in c13.values())}

    # ---- 2. deliberate breaks ---------------------------------------------
    out["mutants"] = run_mutants(B, Bz0, S, tau=13)

    # ---- 3. exhaustive tiny search ----------------------------------------
    # FIX 2026-10-20 (outer review): the previous version reported the number of
    # GENERATED MATRICES (2^(k*n)) as "codes tested" (it included rank-deficient
    # matrices and several representations of the same code), used tau = d (so S1
    # never lowered the distance), and -- since all retained objects have k <= 3 --
    # the sufficient condition (k >= tau+3) was NEVER satisfied, making the
    # "zero violations" a vacuous check.  Now everything is counted precisely and
    # the number of objects that actually entered the sufficient-condition branch
    # is reported.
    viol = []
    boundary = []
    matrices_enumerated = 0
    full_rank_matrices = 0
    distinct_codes = 0
    codes_with_d_ge_3 = 0
    codes_in_sufficient_regime = 0
    s1_lowering_applied = 0
    seen_code_spaces = set()
    for (k, n) in [(1, 4), (1, 5), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (3, 4), (3, 5)]:
        for code in all_binary_codes(k, n):
            matrices_enumerated += 1
            if code.rank() < code.k:
                continue
            full_rank_matrices += 1
            key = tuple(sorted(code.codewords()))
            if key in seen_code_spaces:
                continue
            seen_code_spaces.add(key)
            distinct_codes += 1
            d = code.min_dist()
            if d < 3:
                continue
            codes_with_d_ge_3 += 1
            tau = d - 1                      # EXERCISE the S1 lowering path (t = 1)
            C1, r1, c1 = step_S1(code, tau=tau)
            s1_lowering_applied += 1
            bad1 = [kk for kk, vv in c1.items() if vv is not True]
            if bad1:
                viol.append({"k": k, "n": n, "d": d, "tau": tau, "why": "S1", "bad": bad1})
                continue
            C2, r2, c2 = step_S2(C1)
            bad2 = [kk for kk, vv in c2.items() if vv is not True]
            if bad2:
                viol.append({"k": k, "n": n, "d": d, "tau": tau, "why": "S2", "bad": bad2})
                continue
            D, r3, c3 = step_S3(C2, n_data=n)
            bad3 = [kk for kk, vv in c3.items() if kk.startswith("S3.") and vv is not True]
            # sufficient condition of the S3 rank argument: k - m >= 2 with
            # m <= tau+1 (the weight of the extension's minimum codeword)
            cond = (k >= tau + 3)
            if cond:
                codes_in_sufficient_regime += 1
                if bad3:
                    viol.append({"k": k, "n": n, "d": d, "tau": tau, "why": "S3", "bad": bad3,
                                 "rZ": r3.get("rZ"), "rW": r3.get("rW"),
                                 "W_size": r3.get("W_size")})
            elif bad3 and len(boundary) < 15:
                boundary.append({"k": k, "n": n, "d": d, "tau": tau, "bad": bad3,
                                 "rZ": r3.get("rZ"), "rW": r3.get("rW"),
                                 "W_size": r3.get("W_size"),
                                 "Z_size": r3.get("Z_size"),
                                 "parity_bit": r3.get("parity_bit")})
    out["exhaustive"] = {
        "ranges": "all 2^(k*n) matrices for k<=2,n<=8 and k=3,n<=5",
        "matrices_enumerated": matrices_enumerated,
        "full_rank_matrices": full_rank_matrices,
        "distinct_codes": distinct_codes,
        "distinct_codes_with_d_ge_3": codes_with_d_ge_3,
        "s1_lowering_applied": s1_lowering_applied,
        "codes_entering_the_sufficient_condition_branch": codes_in_sufficient_regime,
        "violations": viol,
        "violations_in_sufficient_regime": [v for v in viol if v.get("why") == "S3"],
        "violations_S1_or_S2": [v for v in viol if v.get("why") in ("S1", "S2")],
        "boundary_failures_examples": boundary,
        "coverage_note": ("This tiny-parameter sweep exercises the MECHANISM of S1/S2/S3 "
                          "(with S1 actually lowering the distance by 1). Because every "
                          "object here has k <= 3, the sufficient condition k >= tau+3 is "
                          "NEVER satisfied (codes_entering_the_sufficient_condition_branch = 0), "
                          "so the S3 part of this sweep is a MECHANISM check only, NOT a check "
                          "of the sufficient condition. The sufficient-condition regime "
                          "(k >= tau+3) is covered by the k=16 BCH instances and by the "
                          "randomized search below (see random_search.codes_in_sufficient_regime).")}

    # ---- 4. randomized search in the "good" regime ------------------------
    # FIX 2026-10-20 (outer review): tau is now d-1 (S1 really lowers the
    # distance) and the number of samples that actually entered the
    # sufficient-condition branch is reported, so that "zero violations" is
    # not a vacuous statement.
    rnd = random.Random(20261020)
    rnd_viol = []
    rnd_kept = 0
    rnd_sufficient = 0
    rnd_trials = 40000
    for _ in range(rnd_trials):
        k = rnd.randint(1, 8)
        n = rnd.randint(k, 12)
        rows = [rnd.getrandbits(n) for _ in range(k)]
        code = Code(rows, n)
        if code.rank() < k:
            continue
        d = code.min_dist()
        if d < 2:
            continue
        rnd_kept += 1
        tau = d - 1
        C1, r1, c1 = step_S1(code, tau=tau)
        if any(vv is not True for vv in c1.values()):
            rnd_viol.append({"why": "S1", "k": k, "n": n, "d": d, "tau": tau})
            continue
        C2, r2, c2 = step_S2(C1)
        if any(vv is not True for vv in c2.values()):
            rnd_viol.append({"why": "S2", "k": k, "n": n, "d": d, "tau": tau})
            continue
        D, r3, c3 = step_S3(C2, n_data=n)
        bad3 = [kk for kk, vv in c3.items() if kk.startswith("S3.") and vv is not True]
        cond = (k >= tau + 3)
        if cond:
            rnd_sufficient += 1
            if bad3:
                rnd_viol.append({"why": "S3", "k": k, "n": n, "d": d, "tau": tau, "bad": bad3,
                                 "rZ": r3.get("rZ"), "W_size": r3.get("W_size")})
    out["random_search"] = {
        "trials": rnd_trials,
        "samples_kept_full_rank_d_ge_2": rnd_kept,
        "codes_entering_the_sufficient_condition_branch": rnd_sufficient,
        "violations": rnd_viol,
        "violations_in_sufficient_regime": [v for v in rnd_viol if v.get("why") == "S3"],
        "note": ("S1 lowers the distance by 1 (tau = d-1). The S3 count refers to the "
                 "branch where the sufficient condition k >= tau+3 actually holds; "
                 "violations there would contradict the lemma.")}

    # ---- 5. summary --------------------------------------------------------
    out["summary"] = {
        "instances": [{"label": r["label"], "PASS": r["PASS"],
                       "k_below_sufficient_bound": r.get("k_below_sufficient_bound", False),
                       "S3_rZ": r.get("S3", {}).get("rZ"),
                       "S3_rW": r.get("S3", {}).get("rW"),
                       "S3_W_size": r.get("S3", {}).get("W_size"),
                       "S3_parity_bit": r.get("S3", {}).get("parity_bit"),
                       "D": {k: r.get("S3", {}).get(k) for k in
                             ("D_n", "D_k", "D_min_dist")}}
                      for r in inst],
        "all_mutants_detected": all(m["detected"] for m in out["mutants"]),
        "exhaustive_matrices_enumerated": matrices_enumerated,
        "exhaustive_distinct_codes": distinct_codes,
        "exhaustive_distinct_codes_with_d_ge_3": codes_with_d_ge_3,
        "exhaustive_codes_entering_sufficient_regime": codes_in_sufficient_regime,
        "exhaustive_violations": len(viol),
        "exhaustive_violations_in_sufficient_regime":
            len([v for v in viol if v.get("why") == "S3"]),
        "random_violations": len(rnd_viol),
        "random_codes_entering_sufficient_regime": rnd_sufficient,
        "random_samples_kept": rnd_kept,
        "every_min_weight_word_ok": out["every_min_weight_word_of_extension"]["all_ok"],
        "elapsed_s": round(time.time() - t0, 1),
    }
    out["instances"] = inst
    with open(os.path.join(HERE, "redteam_checks.json"), "w") as f:
        json.dump(out, f, indent=1, default=str)
    print(json.dumps(out["summary"], indent=1, default=str))
    print("MUTANTS:", json.dumps(out["mutants"], indent=1))
    print("exhaustive: matrices_enumerated=%d distinct_codes=%d (d>=3: %d) "
          "entering_sufficient_regime=%d  violations=%d (S3 in sufficient regime: %d)"
          % (matrices_enumerated, distinct_codes, codes_with_d_ge_3,
             codes_in_sufficient_regime, len(viol),
             len([v for v in viol if v.get("why") == "S3"])))
    print("random: trials=%d kept=%d entering_sufficient_regime=%d violations=%d"
          % (rnd_trials, rnd_kept, rnd_sufficient, len(rnd_viol)))
    print("boundary failure examples:", json.dumps(boundary[:8], indent=1))
    print("D at tau=13 path (exact parameters):",
          json.dumps(out.get("D_at_tau13_path_exact_parameters"), indent=1))
    print("D from RAW BCH extension (NOT the tau=13 path):",
          json.dumps(out.get("D_from_raw_bch_extension_NOT_the_tau13_path"), indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
