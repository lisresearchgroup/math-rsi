#!/usr/bin/env python3
"""Regenerate both complete even-coset lists and check all pairs for one mother.
Default: print the plan without building or scanning. Use --run explicitly.
"""
from pathlib import Path
import argparse,json,subprocess,shutil
ROOT=Path(__file__).resolve().parents[1]
def words(rows):
 out=[0]
 for r in rows:out += [x^r for x in out]
 return out
def perm(x,p):return sum(((x>>i)&1)<<j for i,j in enumerate(p))
def main():
 ap=argparse.ArgumentParser(description=__doc__)
 ap.add_argument('--case',type=int,required=True,choices=range(172),metavar='0..171')
 ap.add_argument('--output',type=Path,required=True)
 ap.add_argument('--cpu-seconds',type=float,default=180)
 ap.add_argument('--run',action='store_true')
 args=ap.parse_args();assert args.cpu_seconds>1
 c=json.loads((ROOT/'data/cases'/f'{args.case:03}.json').read_text());out=args.output.resolve()
 assert sorted(c['free']+c['pivots'])==list(range(40))
 assert all(((r>>pivot)&1)==int(i==j) for i,r in enumerate(c['scan_rows']) for j,pivot in enumerate(c['pivots']))
 assert {perm(x,c['coordinate_permutation_actual_to_input']) for x in words(c['actual_rows'])}==set(words(c['scan_rows']))==set(words(c['gray_original_rows']))
 plan={'case':args.case,'name':c['name'],'mode':'FULL' if args.run else 'DRY_RUN','cosets_per_scanner':2**32,'expected_F':c['expected_F'],'expected_pairs':c['expected_pairs'],'output':str(out),'native_sources':['even_scan.cpp','literal_gray_replay.cpp','rank3_even_graph.cpp']}
 print(json.dumps(plan),flush=True)
 if not args.run:return
 out.mkdir(parents=True,exist_ok=False)
 compiler=shutil.which('clang++') or shutil.which('g++');assert compiler,'C++17 compiler required'
 (out/'compiler.txt').write_text(subprocess.check_output([compiler,'--version'],text=True))
 for name in plan['native_sources']:
  cmd=[compiler,'-std=c++17','-O3',str(ROOT/'native'/name),'-o',str(out/Path(name).stem)]
  subprocess.run(cmd,check=True)
 def save(name,text):(out/name).write_text(text)
 save('bitparallel-input.txt','40 7 16 0\n'+' '.join(map(str,c['scan_rows']))+'\n'+' '.join(map(str,c['free']))+'\n')
 save('gray-input.txt','40 7\n'+'\n'.join(' '.join(map(str,c[k])) for k in ['gray_original_rows','scan_rows','pivots','free'])+'\n')
 cmds=[['even_scan','bitparallel-input.txt','bitparallel-result.json','F.txt',str(args.cpu_seconds)],['literal_gray_replay','gray-input.txt','gray-result.json','accepted.txt','full',str(args.cpu_seconds),'0']]
 for parts in cmds:
  cmd=[str(out/parts[0]),*parts[1:]]
  with (out/(parts[0]+'.log')).open('w') as f:
   subprocess.run(cmd,cwd=out,stdout=f,stderr=subprocess.STDOUT,check=True,timeout=max(300,args.cpu_seconds*5))
 a=json.loads((out/'bitparallel-result.json').read_text());b=json.loads((out/'gray-result.json').read_text())
 assert a['processed_complete'] and not a['sample'] and a['processed_blocks']==2**27 and a['eligible_representatives']==2**32
 assert b['full_domain_complete'] and b['processed_representatives']==2**32
 fa=[int(x) for x in (out/'F.txt').read_text().splitlines()];fb=[int(x.split()[2]) for x in (out/'accepted.txt').read_text().splitlines()]
 archived=[int(x) for x in (ROOT/'data/accepted'/f'{args.case:03}.txt').read_text().splitlines()]
 assert len(fa)==len(set(fa))==len(fb)==len(set(fb))==len(archived)==len(set(archived))==c['expected_F']
 assert set(fa)==set(fb)==set(archived)
 with (out/'pair-graph.json').open('w') as f:
  subprocess.run([str(out/'rank3_even_graph'),'bitparallel-input.txt','F.txt'],cwd=out,stdout=f,check=True,timeout=150)
 g=json.loads((out/'pair-graph.json').read_text());assert g['pair_graph_complete'] and g['pair_count']==c['expected_pairs'] and not g['edges'] and not g['target_indices']
 result=dict(plan,status='PASS',full_scanners=2,set_agreement=True,all_pairs_recomputed=True,pair_graph_edges=0)
 save('verification.json',json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
if __name__=='__main__':main()
