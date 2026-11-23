#!/usr/bin/env python3
"""Finite manuscript-data checks; does NOT rerun exhaustive coset scans."""
from pathlib import Path
from collections import Counter
from math import comb
import json
ROOT=Path(__file__).resolve().parents[1]
def words(rows):
    out=[0]
    for r in rows:out += [x^r for x in out]
    return out
report={'scope':'lower spectra, mother parameters, polynomial, recorded coverage; no full coset scans or pair streams rerun','lower':[]}
for c in json.loads((ROOT/'data/lower-generators.json').read_text())['codes']:
    n,k,d=c['n'],c['k'],c['distance'];r=c['rows'];w=words(r)
    assert len(r)==k and all(0<=x<1<<n for x in r)
    assert len(set(w))==1<<k
    spectrum=Counter(x.bit_count() for x in w[1:])
    assert min(spectrum)==d
    report['lower'].append(dict(n=n,k=k,distance=d,nonzero_messages=len(w)-1,spectrum=dict(sorted(spectrum.items()))))
mothers=json.loads((ROOT/'data/actual172_matrices.json').read_text())['representatives']
assert len(mothers)==172
for c in mothers:
    r=c['generator_rows_40bit_int'];w=words(r)
    assert len(r)==7 and all(0<=x<1<<40 for x in r) and len(set(w))==128
    assert w==c['all128_words'] and [x.bit_count() for x in w[1:]]==c['all127_nonzero_weights']
    assert min(x.bit_count() for x in w[1:])==18 and all(x.bit_count()%2==0 for x in w)
    union=0
    for x in r:union|=x
    assert union==(1<<40)-1
report['mothers']={'count':172,'nonzero_messages_checked':172*127,'rank_even_distance_full_support':'PASS','inequivalence':'requires separate canonicalization check'}
def binom(n,k):return comb(n,k) if 0<=k<=n else 0
def kw(j,w):return sum((-1)**t*binom(w,t)*binom(44-w,j-t) for t in range(j+1))
for w in range(45):
    poly=(w-18)*(w-20)*(w-24)*(w-26)
    assert 2*poly==3*kw(4,w)+44*kw(2,w)+403
    if w>=18 and w%2==0:assert poly>=0
m=json.loads((ROOT/'data/COMPUTATIONAL_COVERAGE.json').read_text());records=m['records']
assert len(records)==172
assert sorted(r['snapshot172_index'] for r in records)==list(range(172))
for r in records:
    assert r['actual_generator_rows_40bit_int']==mothers[r['snapshot172_index']]['generator_rows_40bit_int']
    assert r['original_scan']['full_domain_complete'] and r['original_scan']['processed_even_representatives']==2**32
    assert r['pair_graph']['compatible_edges']==0 and r['pair_graph']['all_pairs_complete']
    assert r['pair_graph']['pair_count']==comb(r['original_scan']['accepted_count'],2)
assert sum(r['original_scan']['accepted_count'] for r in records)==429024
assert sum(r['pair_graph']['pair_count'] for r in records)==619053789
v=json.loads((ROOT/'data/historical-pair-replay.json').read_text())
assert v['pairs_replayed']==619053789 and sum(v['weight_histogram'].values())==619053789
assert v['all_F_actual_distances_checked']==429024*128
assert 172*2**32==738734374912
report['recorded_coverage']={'cosets_per_implementation':172*2**32,'accepted_cosets':429024,'pairs':619053789}
# Portable inputs and all saved sets: verify coordinate conventions and counts.
for case in json.loads((ROOT/'data/case-index.json').read_text()):
    i=case['index'];c=json.loads((ROOT/'data/cases'/f'{i:03}.json').read_text())
    assert c['actual_rows']==mothers[i]['generator_rows_40bit_int']
    assert sorted(c['pivots']+c['free'])==list(range(40))
    assert all(((row>>pos)&1)==int(a==b) for a,row in enumerate(c['scan_rows']) for b,pos in enumerate(c['pivots']))
    perm=c['coordinate_permutation_actual_to_input'];assert sorted(perm)==list(range(40))
    mapped={sum(((x>>a)&1)<<b for a,b in enumerate(perm)) for x in words(c['actual_rows'])}
    assert mapped==set(words(c['scan_rows']))==set(words(c['gray_original_rows']))
    saved=[int(x) for x in (ROOT/'data/accepted'/f'{i:03}.txt').read_text().splitlines()]
    assert len(saved)==len(set(saved))==c['expected_F']==case['F']
    assert comb(len(saved),2)==case['pairs']==c['expected_pairs']
    assert all(0<=x<2**33 and x.bit_count()%2==0 for x in saved)
report['portable_inputs']={'cases':172,'saved_cosets':429024,'matrices_coordinates_parity_counts':'PASS','saved_coset_distance_checks':'see prior complete native replay; this script does not repeat pair rejection'}
report['status']='PASS'
(ROOT/'validation/data-check.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
