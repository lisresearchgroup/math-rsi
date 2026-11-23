#!/usr/bin/env python3
"""Verifier for binary linear code catalogs (*.2 format).

usage: catalog_check.py CATALOG.2 N K D [--out DIR] [--jobs J] [--selftest S]
                        [--pair-timeout SEC] [--no-exact] [--assert-fresh]
Writes DIR/<catalogname>.check.json (DIR defaults to the script dir).
Requires numpy.
"""
import sys, os, re, json, hashlib, time, random, argparse, itertools
from collections import Counter, defaultdict
import numpy as np

np.seterr(all="ignore")
U = np.uint64
M1, M2, M3 = U(0xBF58476D1CE4E5B9), U(0x94D049BB133111EB), U(0x9E3779B97F4A7C15)


def mix(x):  # splitmix64 finalizer, vectorised, wraps mod 2^64
    x = x + M3
    x = (x ^ (x >> U(30))) * M1
    x = (x ^ (x >> U(27))) * M2
    return x ^ (x >> U(31))


# ---------------------------------------------------------------- parsing
HDR = re.compile(r'^\?\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)(?:\s+HULL\s*=\s*(\d+))?')


def parse_catalog(path):
    codes = []
    with open(path, 'r', newline='') as f:
        lines = [l.strip() for l in f.read().replace('\r\n', '\n').replace('\r', '\n').split('\n')]
    i, L = 0, len(lines)
    while i < L:
        m = HDR.match(lines[i])
        if not m:
            i += 1
            continue
        k, n, q, idx = map(int, m.groups()[:4])
        h = int(m.group(5)) if m.group(5) is not None else None
        rows = []
        i += 1
        while i < L and re.fullmatch(r'[01]+', lines[i]) and len(lines[i]) == n and len(rows) < k:
            rows.append(lines[i]); i += 1
        # collect any further 0/1 lines (to detect wrong row count) -- only same-length ones
        extra = 0
        while i < L and re.fullmatch(r'[01]{%d}' % n, lines[i]):
            extra += 1; i += 1
        grp = None
        while i < L and lines[i] == '':
            i += 1
        if i < L and re.fullmatch(r'\d+', lines[i]) and not HDR.match(lines[i]):
            grp = int(lines[i]); i += 1
        codes.append(dict(k=k, n=n, q=q, idx=idx, hull_claimed=h, rows=rows,
                          extra_rows=extra, group_order=grp))
    return codes


# ---------------------------------------------------------------- GF(2)
def rank_ints(vs):
    basis = {}
    r = 0
    for v in vs:
        while v:
            hb = v.bit_length() - 1
            if hb in basis:
                v ^= basis[hb]
            else:
                basis[hb] = v; r += 1; break
    return r


def row_ints(rows):  # coordinate j = bit j
    return [int(r[::-1], 2) for r in rows]


def codeword_ints(rints):
    arr = np.zeros(1, dtype=np.uint64)
    for r in rints:
        arr = np.concatenate([arr, arr ^ np.uint64(r)])
    return arr[1:]  # nonzero codewords (if rows independent)


def bitmatrix(cw, n):
    return ((cw[:, None] >> np.arange(n, dtype=np.uint64)) & np.uint64(1)).astype(np.uint64)


# ---------------------------------------------------------------- refinement
def refine(C, co, maxrounds=10, cw=None):
    """C: (m x n) 0/1 uint64 incidence; co: initial coordinate colours (uint64, n).
    Hash-based colour refinement (multiset hash = sum of mixed colours mod 2^64),
    independent of coordinate order / basis.  Returns (co, cw, rounds)."""
    CT = C.T
    if cw is None:
        cw = mix(C.sum(1) + U(12345))
    ncl = (len(set(co.tolist())), len(set(cw.tolist())))
    rounds = 0
    for _ in range(maxrounds):
        co = mix(co * U(3) + CT @ mix(cw ^ U(0x1111)) + U(1))
        cw = mix(cw * U(5) + C @ mix(co ^ U(0x2222)) + U(2))
        rounds += 1
        new = (len(set(co.tolist())), len(set(cw.tolist())))
        if new == ncl:
            break
        ncl = new
    return co, cw, rounds


def invariant(C, n):
    # Hash use here is sound for inequivalence: the value is a deterministic function of the isomorphism class
    # (sums mod 2^64 are order independent), so DIFFERENT values prove inequivalence; equal values (incl. true
    # hash collisions) only put codes into a collision group, which the exact hash-free search then decides.
    co0 = np.full(n, 7, dtype=np.uint64)
    co, cw, rounds = refine(C, co0)
    h = hashlib.sha256()
    h.update(np.sort(co).tobytes()); h.update(b'|'); h.update(np.sort(cw).tobytes())
    return h.hexdigest(), rounds


# ---------------------------------------------------------------- per-code analysis
def analyse(code, n_exp, k_exp, d_exp):
    rows = code['rows']
    rec = dict(idx=code['idx'], header=dict(k=code['k'], n=code['n'], q=code['q']))
    k = len(rows)
    rl = sorted(set(len(r) for r in rows))
    rec['num_rows'] = k; rec['row_lengths'] = rl
    rints = row_ints(rows)
    rec['rank'] = rank_ints(rints)
    n = code['n']
    C = None
    if k == k_exp and rl == [n_exp] and rec['rank'] == k and k <= 20:
        cw = codeword_ints(rints)
        C = bitmatrix(cw, n)
        w = C.sum(1).astype(np.int64)
        wd = np.bincount(w, minlength=n + 1)
        rec['weight_dist'] = {int(i): int(c) for i, c in enumerate(wd) if c}
        rec['min_dist'] = int(w.min())
        rec['all_even'] = bool((w % 2 == 0).all())
    else:
        rec['weight_dist'] = None; rec['min_dist'] = None; rec['all_even'] = None
    # columns
    cols = [sum(((rows[r][j] == '1') << r) for r in range(k)) for j in range(n)]
    rec['zero_columns'] = sum(1 for c in cols if c == 0)
    cc = Counter(cols)
    rec['column_multiplicities'] = {int(m): int(c) for m, c in sorted(Counter(cc.values()).items())}  # multiplicity -> number of classes
    rec['projective'] = all(m == 1 for m in cc.values()) and rec['zero_columns'] == 0
    # hull
    gram = []
    for a in range(k):
        v = 0
        for b in range(k):
            if bin(rints[a] & rints[b]).count('1') & 1:
                v |= 1 << b
        gram.append(v)
    rec['rank_GGt'] = rank_ints(gram)
    rec['hull_dim'] = k - rec['rank_GGt']
    rec['hull_claimed'] = code['hull_claimed']
    rec['hull_match'] = None if code['hull_claimed'] is None else (rec['hull_dim'] == code['hull_claimed'])
    rec['group_order'] = code['group_order']
    if C is not None:
        rec['invariant'], rec['refine_rounds'] = invariant(C, n)
    else:
        rec['invariant'] = None; rec['refine_rounds'] = None
    ok = (k == k_exp and rl == [n_exp] and rec['rank'] == k_exp and rec['min_dist'] == d_exp
          and rec['zero_columns'] == 0 and rec['hull_match'] is not False and code['extra_rows'] == 0
          and code['n'] == n_exp and code['k'] == k_exp
          and rec['invariant'] is not None)
    rec['checks_pass'] = bool(ok)
    return rec


def _work(args):
    code, n, k, d = args
    return analyse(code, n, k, d)


# ---------------------------------------------------------------- exact equivalence
class Budget(Exception):
    pass


# Assertion mode (CLI --assert-fresh): at every individualization check that the new colour is absent
# from the current colouring.  ASSERT_STATS counts the checks performed.
ASSERT_FRESH = False
ASSERT_STATS = {'fresh_checks': 0}


def _dense(x):
    """Exact dense ranking of an integer array: (ranks, sorted distinct values, counts)."""
    vals, inv, cnt = np.unique(x, return_inverse=True, return_counts=True)
    return inv.reshape(-1).astype(np.int64), vals, cnt


def _unique_rows(M):
    rows, inv, cnt = np.unique(M, axis=0, return_inverse=True, return_counts=True)
    return rows, inv.reshape(-1).astype(np.int64), cnt


def exact_refine_pair(CA, CB, coA, cwA, coB, cwB):
    """Joint EXACT colour refinement of two codes (no hashing anywhere).

    CA, CB: (m x n) int32 0/1 incidence (codeword x coordinate).  co*: int64 coordinate colours,
    cw*: int64 codeword colours (arbitrary integers; only equality/order matter).
    Each round: (1) the colour multisets of A and B must agree (compared exactly as sorted value /
    count arrays), then colours are replaced by dense ranks of the sorted distinct values;
    (2) every coordinate gets the exact signature (own rank, counts of incident codewords per
    codeword rank) and every codeword (own rank, counts of incident coordinates per coordinate rank);
    (3) the multiset of signatures of A and of B must be identical (exact row comparison of the sorted
    distinct signature matrices and their multiplicities), else the pair is NOT isomorphic -> None;
    (4) new colour = rank of the signature in the sorted list of distinct signatures.  Ranks are
    therefore equal for corresponding vertices of A and B under ANY isomorphism, and they are computed
    from exact integer data only.  Iterates until neither the coordinate nor the codeword class count grows.
    Returns (coA, cwA, coB, cwB) with dense-rank colours, or None if a mismatch proves non-isomorphism."""
    prev = None
    while True:
        (cA, vcoA, ncoA), (wA, vcwA, ncwA) = _dense(coA), _dense(cwA)
        (cB, vcoB, ncoB), (wB, vcwB, ncwB) = _dense(coB), _dense(cwB)
        if not (np.array_equal(vcoA, vcoB) and np.array_equal(ncoA, ncoB)
                and np.array_equal(vcwA, vcwB) and np.array_equal(ncwA, ncwB)):
            return None
        p, q = len(vcoA), len(vcwA)
        if prev == (p, q):
            return cA, wA, cB, wB
        prev = (p, q)
        new = []
        for C, c, w in ((CA, cA, wA), (CB, cB, wB)):
            Oc = np.zeros((C.shape[1], p), dtype=np.int32); Oc[np.arange(C.shape[1]), c] = 1
            Ow = np.zeros((C.shape[0], q), dtype=np.int32); Ow[np.arange(C.shape[0]), w] = 1
            sco = np.hstack([c[:, None].astype(np.int32), C.T @ Ow])
            scw = np.hstack([w[:, None].astype(np.int32), C @ Oc])
            new.append((_unique_rows(sco), _unique_rows(scw)))
        (rcoA, icoA, kcoA), (rcwA, icwA, kcwA) = new[0]
        (rcoB, icoB, kcoB), (rcwB, icwB, kcwB) = new[1]
        if not (np.array_equal(rcoA, rcoB) and np.array_equal(kcoA, kcoB)
                and np.array_equal(rcwA, rcwB) and np.array_equal(kcwA, kcwB)):
            return None
        coA, cwA, coB, cwB = icoA, icwA, icoB, icwB


def equivalent(rowsA, rowsB, n, timeout=300.0, maxnodes=5_000_000):
    """Individualise-and-refine search for a coordinate permutation p (A coord j -> B coord p[j])
    with p(code A) = code B.  Returns ('equivalent', p) | ('inequivalent', nodes) | ('unresolved', nodes).

    Why the search is exhaustive.  An equivalence is a permutation p of the n coordinates with
    p(A) = B as sets of codewords; p induces a bijection of the nonzero codewords preserving weight and
    the codeword/coordinate incidence.  Colour refinement is equivariant, so every such p maps each
    refined class of A onto the class of B with the same rank (exact_refine_pair returns None only if
    the multisets differ, in which case no p exists).  At a node, pick the smallest non-singleton
    coordinate class (same rank in A and B), fix one vertex v of it in A; any p must send v to SOME
    vertex w of the same class in B, so branching over ALL w in that class covers all p.  The branch
    (v,w) gives both v and w the colour max(co)+1, which is FRESH by construction (colours are dense
    ranks 0..r-1 at that point, so the new colour exceeds every existing coordinate colour) and
    identical in A and B; every p with p(v)=w respects the new colourings.  Recursion ends when the
    coordinate partition is discrete: then p is forced (rank r in A -> rank r in B) and is verified
    exactly against the codeword set of B.  'inequivalent' is returned only after every branch has
    been refuted (refinement mismatch or failed exact verification).  No hash is used anywhere here."""
    ra, rb = row_ints(rowsA), row_ints(rowsB)
    if rank_ints(ra) != len(ra) or rank_ints(rb) != len(rb) or len(ra) != len(rb):
        raise ValueError('equivalent(): generator rows must be independent and of equal number')
    cwA_, cwB_ = codeword_ints(ra), codeword_ints(rb)
    CA = bitmatrix(cwA_, n).astype(np.int32)
    CB = bitmatrix(cwB_, n).astype(np.int32)
    setB = set(int(x) for x in cwB_)
    t0 = time.time()
    nodes = [0]

    def verify(p):
        for r in ra:
            v = 0
            for j in range(n):
                if (r >> j) & 1:
                    v |= 1 << p[j]
            if v not in setB:
                return False
        return True

    def rec(coA, cwA, coB, cwB):
        nodes[0] += 1
        if nodes[0] > maxnodes or time.time() - t0 > timeout:
            raise Budget()
        res = exact_refine_pair(CA, CB, coA, cwA, coB, cwB)
        if res is None:
            return None
        coA, cwA, coB, cwB = res
        ncls = int(coA.max()) + 1
        sizes = np.bincount(coA, minlength=ncls)
        if ncls == n:
            p = [None] * n
            posB = {int(c): j for j, c in enumerate(coB.tolist())}
            for j, c in enumerate(coA.tolist()):
                p[j] = posB[c]
            return p if verify(p) else None
        c = min((c for c in range(ncls) if sizes[c] > 1), key=lambda c: (sizes[c], c))
        v = int(np.flatnonzero(coA == c)[0])
        fresh = ncls  # = max(coA)+1 = max(coB)+1: absent from both colourings
        for w in np.flatnonzero(coB == c).tolist():
            if ASSERT_FRESH:
                assert fresh not in set(coA.tolist()) and fresh not in set(coB.tolist()), 'individualisation colour not fresh'
                assert coA[v] == c and coB[w] == c
                ASSERT_STATS['fresh_checks'] += 1
            a2 = coA.copy(); a2[v] = fresh
            b2 = coB.copy(); b2[w] = fresh
            r = rec(a2, cwA, b2, cwB)
            if r is not None:
                return r
        return None

    z = np.zeros(n, dtype=np.int64)
    wA0 = CA.sum(1).astype(np.int64); wB0 = CB.sum(1).astype(np.int64)  # initial codeword colour = weight
    try:
        p = rec(z.copy(), wA0, z.copy(), wB0)
    except Budget:
        return 'unresolved', nodes[0]
    if p is not None:
        return 'equivalent', p
    return 'inequivalent', nodes[0]


def resolve_groups(groups, byidx, n, timeout):
    out = []
    for g in groups:
        reps = []   # list of lists of idx (equivalence classes found)
        pairs = []
        unresolved = []
        for idx in g:
            placed = False
            for cls in reps:
                st, info = equivalent(byidx[cls[0]]['rows'], byidx[idx]['rows'], n, timeout)
                if st == 'equivalent':
                    cls.append(idx); placed = True
                    pairs.append(dict(a=cls[0], b=idx, result='equivalent', perm=info))
                    break
                elif st == 'inequivalent':
                    pairs.append(dict(a=cls[0], b=idx, result='inequivalent_exhaustive', nodes=info))
                else:
                    pairs.append(dict(a=cls[0], b=idx, result='unresolved', nodes=info))
                    unresolved.append((cls[0], idx))
            if not placed:
                reps.append([idx])
        out.append(dict(idx_group=g, classes=reps, pair_results=pairs, unresolved_pairs=unresolved))
    return out


# ---------------------------------------------------------------- self-test
def random_equiv_copy(rows, n, rng):
    k = len(rows)
    perm = list(range(n)); rng.shuffle(perm)
    pr = [''.join(r[perm[j]] for j in range(n)) for r in rows]
    ints = row_ints(pr)
    while True:  # random invertible transform
        T = [[rng.randint(0, 1) for _ in range(k)] for _ in range(k)]
        newr = []
        for a in range(k):
            v = 0
            for b in range(k):
                if T[a][b]:
                    v ^= ints[b]
            newr.append(v)
        if rank_ints(newr) == k:
            break
    return [format(v, '0%db' % n)[::-1] for v in newr]


def selftest(codes, n, k, count, seed=1):
    rng = random.Random(seed)
    sample = codes if len(codes) <= count else rng.sample(codes, count)
    res = []
    for c in sample:
        inv0 = invariant(bitmatrix(codeword_ints(row_ints(c['rows'])), n), n)[0]
        ok = True
        for _ in range(2):
            r2 = random_equiv_copy(c['rows'], n, rng)
            inv1 = invariant(bitmatrix(codeword_ints(row_ints(r2)), n), n)[0]
            ok &= (inv0 == inv1)
        r3 = random_equiv_copy(c['rows'], n, rng)
        st_, info = equivalent(c['rows'], r3, n, 60.0)
        res.append(dict(idx=c['idx'], invariant_preserved=bool(ok), exact_search_finds_perm=(st_ == 'equivalent')))
    return res


# ---------------------------------------------------------------- main
def name_for_lists(path):
    return os.path.splitext(os.path.basename(path))[0]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('catalog'); ap.add_argument('n', type=int); ap.add_argument('k', type=int); ap.add_argument('d', type=int)
    ap.add_argument('--out', default=os.path.dirname(os.path.abspath(__file__)))
    ap.add_argument('--jobs', type=int, default=3)
    ap.add_argument('--selftest', type=int, default=20)
    ap.add_argument('--pair-timeout', type=float, default=300.0)
    ap.add_argument('--no-exact', action='store_true')
    ap.add_argument('--assert-fresh', action='store_true', help='assert freshness of every individualisation colour')
    a = ap.parse_args()
    global ASSERT_FRESH
    ASSERT_FRESH = a.assert_fresh
    t0 = time.time()
    codes = parse_catalog(a.catalog)
    n, k, d = a.n, a.k, a.d
    if a.jobs > 1 and len(codes) > 50:
        import multiprocessing as mp
        with mp.Pool(a.jobs) as pool:
            recs = pool.map(_work, [(c, n, k, d) for c in codes], chunksize=64)
    else:
        recs = [_work((c, n, k, d)) for c in codes]
    t_an = time.time() - t0
    byidx_list = {}
    for c in codes:
        byidx_list.setdefault(c['idx'], []).append(c)
    dup_idx = [i for i, v in byidx_list.items() if len(v) > 1]
    # use position-independent keys: idx as given (check uniqueness)
    byidx = {c['idx']: c for c in codes}
    inv_groups = defaultdict(list)
    for r in recs:
        if r['invariant']:
            inv_groups[r['invariant']].append(r['idx'])
    collisions = [sorted(g) for g in inv_groups.values() if len(g) > 1]
    collisions.sort()
    exact = []
    if collisions and not a.no_exact:
        exact = resolve_groups(collisions, byidx, n, a.pair_timeout)
    st = selftest(codes, n, k, a.selftest) if codes else []
    # positive control of the exact search on every member of every collision group
    rng = random.Random(7)
    ctrl = []
    for g in collisions:
        for idx in g:
            r3 = random_equiv_copy(byidx[idx]['rows'], n, rng)
            s_, _ = equivalent(byidx[idx]['rows'], r3, n, a.pair_timeout)
            ctrl.append(dict(idx=idx, found=(s_ == 'equivalent')))

    def hist(rs):
        return {str(h): c for h, c in sorted(Counter(r['hull_dim'] for r in rs).items())}
    even = [r for r in recs if r['all_even']]
    proj = [r for r in recs if r['projective']]
    ep = [r for r in even if r['projective']]
    unresolved = sum(len(e['unresolved_pairs']) for e in exact)
    equiv_found = [p for e in exact for p in e['pair_results'] if p['result'] == 'equivalent']
    totals = dict(
        expected=dict(n=n, k=k, d=d), count=len(recs),
        count_even=len(even), count_projective=len(proj), count_even_and_projective=len(ep),
        hull_hist_all=hist(recs), hull_hist_even=hist(even),
        hull_mismatches=[r['idx'] for r in recs if r['hull_match'] is False],
        distinct_invariants=len(inv_groups), collision_groups=collisions,
        exact_resolution=exact, unresolved_pairs=unresolved,
        equivalent_pairs_found=equiv_found,
        duplicate_idx=dup_idx,
        exact_engine='v2: exact integer ranks, fresh individualisation colour',
        assert_fresh_mode=a.assert_fresh, assert_fresh_checks=ASSERT_STATS['fresh_checks'],
        selftest_count=len(st), selftest_all_preserved=all(s['invariant_preserved'] for s in st),
        selftest_exact_search_all_found=all(s['exact_search_finds_perm'] for s in st),
        collision_member_positive_control=ctrl,
        checks_failed=[r['idx'] for r in recs if not r['checks_pass']],
        group_order_hist={str(g): c for g, c in sorted(Counter(r['group_order'] for r in recs).items(), key=lambda x: (x[0] is None, x[0]))},
        min_dist_hist={str(g): c for g, c in sorted(Counter(r['min_dist'] for r in recs).items(), key=lambda x: (x[0] is None, x[0]))},
        seconds_analysis=round(t_an, 1), seconds_total=round(time.time() - t0, 1),
    )
    totals['all_checks_pass'] = bool(
        len(recs) > 0 and not totals['checks_failed'] and not dup_idx and totals['selftest_all_preserved']
        and totals['selftest_exact_search_all_found'] and all(c['found'] for c in ctrl))
    totals['all_codes_pairwise_inequivalent_proved'] = bool(
        totals['all_checks_pass'] and unresolved == 0 and not equiv_found)
    totals['selftest'] = st
    totals['zero_column_failures'] = [r['idx'] for r in recs if r['zero_columns'] != 0]
    totals['count_non_even'] = len(recs) - len(even)
    nev = Counter()
    for r in recs:
        if r['weight_dist'] is not None and not r['all_even']:
            nev[tuple(sorted(r['weight_dist'].items()))] += 1
    totals['non_even_distinct_weight_distributions'] = len(nev)
    totals['count_hull_claimed_absent'] = sum(1 for r in recs if r['hull_claimed'] is None)
    totals['count_group_order_absent'] = sum(1 for r in recs if r['group_order'] is None)
    base = name_for_lists(a.catalog)
    for fn, rs in ((base + '.even_idx.txt', even), (base + '.even_projective_idx.txt', ep)):
        with open(os.path.join(a.out, fn), 'w') as f:
            f.write(''.join('%d\n' % i for i in sorted(r['idx'] for r in rs)))
    name = os.path.basename(a.catalog)
    os.makedirs(a.out, exist_ok=True)
    outp = os.path.join(a.out, name + '.check.json')
    with open(outp, 'w') as f:
        json.dump(dict(catalog=a.catalog, totals=totals, codes=recs), f, indent=1)
    print(json.dumps({k_: v for k_, v in totals.items() if k_ not in ('selftest', 'exact_resolution', 'collision_member_positive_control')}, indent=1))
    print('wrote', outp)


if __name__ == '__main__':
    main()
