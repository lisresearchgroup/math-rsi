#!/usr/bin/env python3
"""Recompute work/20261123-assembly/w6_subset_compare.json from the raw per-code JSON of the two implementations.
Subsets of the even [36,7,16] catalog codes: without repeated columns (K6, main domain), with repeated columns, all."""
import json, os, hashlib, datetime
A = [int(x) for x in open('work/20261122-catalog/check/36_7_16.even_projective_idx.txt').read().split()]
Ae = [int(x) for x in open('work/20261122-catalog/check/36_7_16.even_idx.txt').read().split()]
codes = json.load(open('work/20261122-catalog/check2/36_7_16.audit.json'))['codes']
B = sorted(c['idx'] for c in codes if c['even'] and not c['repeated_columns'])
Be = sorted(c['idx'] for c in codes if c['even'])
S = '/shared/ecc-41-12/out/'
def load(d, idxs):
    r = {}
    for i in idxs:
        f = f'{S}{d}/{i}.json'
        if os.path.exists(f):
            r[i] = json.load(open(f))
    return r
o6, o7 = load('o6_36_w6', Ae), load('o7_36_w6', Ae)
keys = ['pivots', 'free', 'min_distance_K', 'F_size', 'F_sha256', 'edges', 'c3', 'c4', 'c5', 'solutions', 'solution_list']
hist = lambda r: {k: v for k, v in r['depth_hist_even'].items() if v}
out = {'generated': datetime.datetime.now().isoformat(timespec='seconds'),
       'A_B_norepeat_lists_identical': A == B, 'A_B_even_lists_identical': Ae == Be,
       'idx_list_sha256': hashlib.sha256(open('work/20261123-assembly/36_7_16.even_norepeat_idx.txt', 'rb').read()).hexdigest()}
for name, idxs in (('even_norepeat', A), ('even_with_repeat', sorted(set(Ae) - set(A))), ('even_all', Ae)):
    both = [i for i in idxs if i in o6 and i in o7]
    tot = lambda R, k: sum(R[i][k] for i in idxs if i in R)
    out[name] = {'count': len(idxs), 'o6_done': sum(i in o6 for i in idxs), 'o7_done': sum(i in o7 for i in idxs), 'compared': len(both),
                 'mismatch_idx': [i for i in both if any(o6[i][k] != o7[i][k] for k in keys) or hist(o6[i]) != hist(o7[i])],
                 'missing_o7': [i for i in idxs if i not in o7], 'missing_o6': [i for i in idxs if i not in o6],
                 'o6': {k: tot(o6, k) for k in ['F_size', 'edges', 'c3', 'c4', 'c5', 'solutions']},
                 'o7': {k: tot(o7, k) for k in ['F_size', 'edges', 'c3', 'c4', 'c5', 'solutions']},
                 'o6_max_c4': max((o6[i]['c4'], i) for i in idxs if i in o6),
                 'o6_seconds': round(sum(o6[i]['seconds'] for i in idxs if i in o6)), 'o7_seconds': round(sum(o7[i]['seconds'] for i in idxs if i in o7))}
    print(name, {k: out[name][k] for k in ('count', 'o6_done', 'o7_done', 'compared', 'mismatch_idx', 'missing_o7')}, out[name]['o7'])
json.dump(out, open('work/20261123-assembly/w6_subset_compare.json', 'w'), indent=1)
