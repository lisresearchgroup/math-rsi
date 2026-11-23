#!/usr/bin/env python3
"""Check actual matrix parameters and graph inequivalence; requires pynauty."""
from pathlib import Path
from collections import Counter
import json,pynauty
ROOT=Path(__file__).resolve().parents[1]
keys=set();hulls=Counter()
for c in json.loads((ROOT/'data/actual172_matrices.json').read_text())['representatives']:
 rows=c['generator_rows_40bit_int'];words=[0]
 for r in rows:words += [x^r for x in words]
 assert len(rows)==7 and len(set(words))==128 and words==c['all128_words']
 assert all(0<=x<2**40 for x in rows)
 assert min(w.bit_count() for w in words[1:])==18 and all(w.bit_count()%2==0 for w in words)
 union=0
 for r in rows:union|=r
 assert union==2**40-1
 hull=[w for w in words if all((w&r).bit_count()%2==0 for r in rows)]
 h=len(hull).bit_length()-1;assert len(hull)==2**h;hulls[h]+=1
 adj={i:[] for i in range(168)}
 for i,w in enumerate(words,40):
  for j in range(40):
   if (w>>j)&1:adj[i].append(j);adj[j].append(i)
 g=pynauty.Graph(168,adjacency_dict=adj,vertex_coloring=[set(range(40)),set(range(40,168))])
 key=pynauty.certificate(g);assert key not in keys;keys.add(key)
assert len(keys)==172 and hulls=={1:33,3:62,5:77}
print(json.dumps({'status':'PASS','distinct_codes':len(keys),'hull_distribution':dict(hulls),'published_class_bound':'external input','pynauty_version':pynauty.__version__}))
