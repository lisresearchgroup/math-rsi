#!/usr/bin/env python3
"""Small-domain control: exact search `equivalent()` vs brute force over all n! coordinate permutations."""
import sys, json, random, itertools
import numpy as np
import catalog_check as cc

cc.ASSERT_FRESH = True
rng = random.Random(int(sys.argv[1]) if len(sys.argv) > 1 else 2024)


def rand_code(n, k):
    while True:
        pool = [0] + [rng.randrange(1, 1 << k) for _ in range(rng.randint(1, max(1, n - 1)))]
        cols = [rng.choice(pool) for _ in range(n)]          # repeated and zero columns occur
        rows = [''.join('1' if (cols[j] >> r) & 1 else '0' for j in range(n)) for r in range(k)]
        if cc.rank_ints(cc.row_ints(rows)) == k:
            return rows


def brute(rowsA, rowsB, n):
    ra = cc.row_ints(rowsA)
    tab = np.zeros(1 << n, dtype=bool)
    tab[[int(x) for x in cc.codeword_ints(cc.row_ints(rowsB))]] = True
    tab[0] = True
    perms = np.array(list(itertools.permutations(range(n))), dtype=np.int64)  # n! x n ; image position of coord j
    ok = np.ones(len(perms), dtype=bool)
    for r in ra:
        bits = np.array([(r >> j) & 1 for j in range(n)], dtype=np.int64)
        img = (bits[None, :] * (1 << perms)).sum(1)
        ok &= tab[img]
    return bool(ok.any())


codes = []   # (n,k,rows)
shapes = [(6, 3), (7, 3), (7, 4), (8, 3), (8, 4), (5, 2)]
for _ in range(30):
    n, k = rng.choice(shapes)
    codes.append((n, k, rand_code(n, k)))
for n, k, rows in list(codes):   # add random equivalent copies so that equivalent pairs are plentiful
    codes.append((n, k, cc.random_equiv_copy(rows, n, rng)))
rng.shuffle(codes)
cache = {}
npairs = same_shape = agree = 0
n_equiv = n_ineq = 0
dis = []
for i in range(len(codes)):
    for j in range(i + 1, len(codes)):
        npairs += 1
        (n1, k1, r1), (n2, k2, r2) = codes[i], codes[j]
        if (n1, k1) != (n2, k2):
            continue
        same_shape += 1
        st, info = cc.equivalent(r1, r2, n1, 60.0)
        bf = brute(r1, r2, n1)
        if st == 'unresolved':
            dis.append((i, j, st, bf)); continue
        if (st == 'equivalent') == bf:
            agree += 1
            n_equiv += bf; n_ineq += (not bf)
        else:
            dis.append((i, j, st, bf))
# n=9,10 positive control
pos_ok = pos = 0
for _ in range(12):
    n = rng.choice([9, 10]); k = rng.choice([3, 4])
    r1 = rand_code(n, k); r2 = cc.random_equiv_copy(r1, n, rng)
    st, p = cc.equivalent(r1, r2, n, 60.0); pos += 1; pos_ok += (st == 'equivalent')
res = dict(codes=len(codes), pairs_total=npairs, pairs_same_shape=same_shape, agree=agree,
           equivalent_pairs=n_equiv, inequivalent_pairs=n_ineq, disagreements=dis,
           n9_10_positive_controls=pos, n9_10_positive_found=pos_ok,
           assert_fresh_checks=cc.ASSERT_STATS['fresh_checks'],
           zero_cols_in_codes=sum(1 for n, k, rows in codes if any(all(r[j] == '0' for r in rows) for j in range(n))),
           repeated_cols_in_codes=sum(1 for n, k, rows in codes if len(set(zip(*rows))) < n))
print(json.dumps(res))
json.dump(res, open('small_control.json', 'w'), indent=1)
