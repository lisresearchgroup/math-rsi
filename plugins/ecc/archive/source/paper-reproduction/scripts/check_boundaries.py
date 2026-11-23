#!/usr/bin/env python3
"""Small exhaustive counterexample probes for the proof's boundary conditions.
These checks support review; the general lemmas are established by the paper/Lean.
"""
from pathlib import Path
from math import comb
import json
ROOT=Path(__file__).resolve().parents[1]
def subspaces(n):
 current={frozenset([0])};allspaces=set(current)
 while current:
  new=set()
  for C in current:
   for x in range(1,1<<n):
    if x not in C:new.add(frozenset(set(C)|{c^x for c in C}))
  current=new-allspaces;allspaces|=current
 return allspaces
def punct(x,keep):return sum(((x>>pos)&1)<<i for i,pos in enumerate(keep))
checks=0;normalizations=0;zero_coordinate=0
for n in range(1,6):
 for C in subspaces(n):
  if len(C)==1:continue
  k=len(C).bit_length()-1;D=min(x.bit_count() for x in C if x);checks+=1
  for j in range(n):
   S={punct(x,[i for i in range(n) if i!=j]) for x in C if not ((x>>j)&1)}
   assert len(S)>=1<<max(0,k-1)
   assert all(x.bit_count()>=D for x in S if x)
   if all(not ((x>>j)&1) for x in C):assert len(S)==len(C);zero_coordinate+=1
  w=next(x for x in C if x and x.bit_count()==D)
  for d in range(1,D+1):
   deleted=[j for j in range(n) if (w>>j)&1][:D-d]
   image={punct(x,[j for j in range(n) if j not in deleted]) for x in C}
   assert len(image)==len(C) and min(x.bit_count() for x in image if x)==d;normalizations+=1
# Why positivity and parity restrictions cannot be silently dropped.
C={0,0b0011,0b1100,0b1111};image={punct(x,[2,3]) for x in C};assert len(image)==2<len(C)
P=lambda w:(w-18)*(w-20)*(w-24)*(w-26)
assert P(19)<0 and P(25)<0 and all(P(w)>=0 for w in range(18,45,2))
tails=[0b1001,0b0101,0b0011]
for u in range(1,8):
 x=0
 for i,t in enumerate(tails):
  if (u>>i)&1:x^=t
 assert x.bit_count()==(4 if u==7 else 2)
r={'status':'PASS','scope':'finite boundary probes, not substitute for general proofs','nonzero_subspaces_n_at_most5':checks,'positive_distance_normalizations':normalizations,'zero_coordinate_shortenings':zero_coordinate,'negative_controls':{'distance_zero_can_lose_rank':True,'polynomial_negative_at_odd19_and25':True},'all_seven_tail_weights':'PASS'}
(ROOT/'validation/boundary-check.json').write_text(json.dumps(r,indent=2)+'\n');print(json.dumps(r))
