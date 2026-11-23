#!/usr/bin/env python3
"""Recheck both saved accepted sets and bindings; does not repeat full enumeration."""
from pathlib import Path
import argparse,json
ap=argparse.ArgumentParser();ap.add_argument('--manifest',type=Path,required=True);args=ap.parse_args()
m=json.loads(args.manifest.read_text());results=[]
def words(rows):
 out=[0]
 for r in rows:out += [x^r for x in out]
 return out
def rank(rows):
 piv={}
 for x in rows:
  while x:
   j=x.bit_length()-1
   if j in piv:x^=piv[j]
   else:piv[j]=x;break
 return len(piv)
def perm(x,p):return sum(((x>>i)&1)<<j for i,j in enumerate(p))
for rec in m['records']:
 a=rec['original_scan'];b=rec['independent_full_F']
 inp=json.loads(Path(a['input_path']).read_text());res=json.loads(Path(a['result_path']).read_text());ind=json.loads(Path(b['result_path']).read_text())
 assert a['scan_rows']==inp['rows']==res['rows']
 actual=words(rec['actual_generator_rows_40bit_int']);mapped={perm(x,a['coordinate_permutation_actual_to_input']) for x in actual}
 assert mapped==set(words(inp['rows']))
 assert res['processed_complete'] and res['processed_blocks']==2**27 and res['eligible_representatives']==2**32 and not res['sample']
 assert ind['full_domain_complete'] and ind['processed_representatives']==2**32
 basis=ind['gray_basis_40bit'];assert len(basis)==rank(basis)==32 and rank(basis+inp['rows'])==39
 assert all(0<=x<2**40 and x.bit_count()%2==0 for x in basis)
 orig=[int(x) for x in Path(a['F_path']).read_text().splitlines()]
 saved=[]
 for line in Path(b['accepted_path']).read_text().splitlines():
  idx,x,old=map(int,line.split());assert 0<=idx<2**32
  g=idx^(idx>>1);calc=0
  for j,row in enumerate(basis):
   if (g>>j)&1:calc^=row
  assert calc==x
  norm=x
  for pivot,row in zip(inp['pivots'],inp['rows']):
   if (x>>pivot)&1:norm^=row
  packed=sum(((norm>>pos)&1)<<j for j,pos in enumerate(inp['free']))
  assert packed==old  # archives store normalized free-coordinate integers
  saved.append(packed)
 assert len(orig)==len(set(orig))==len(saved)==len(set(saved))==res['accepted_count']==ind['accepted_count']
 assert set(orig)==set(saved)
 results.append({'index':rec['snapshot172_index'],'F_count':len(orig),'exact_set_agreement':True})
out={'status':'PASS','scope':'read saved complete-scan results, validate bases and all saved Gray indices/normalizations, compare exact sets; full domains not rerun','cases':len(results),'F_count':sum(x['F_count'] for x in results),'results':results}
args.manifest.with_name('saved-set-recheck.json').write_text(json.dumps(out,indent=2)+'\n');print(json.dumps({k:v for k,v in out.items() if k!='results'}))
