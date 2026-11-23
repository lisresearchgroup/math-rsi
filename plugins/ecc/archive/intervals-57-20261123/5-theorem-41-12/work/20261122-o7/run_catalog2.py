#!/usr/bin/env python3
"""Standard-library catalog driver. Only ext2 child processes do heavy work."""
import argparse, concurrent.futures, hashlib, json, os, re, subprocess, sys, threading, time
from pathlib import Path
HERE=Path(__file__).resolve().parent

def read_catalog(path):
    lines=Path(path).read_text().splitlines(); i=0; seen=set()
    while i<len(lines):
        match=re.match(r'^\s*\?(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\b',lines[i]); i+=1
        if not match: continue
        k,n,q,idx=map(int,match.groups())
        if q!=2 or idx in seen: raise ValueError('nonbinary or duplicate catalog index')
        seen.add(idx); rows=[]
        for _ in range(k):
            if i>=len(lines): raise ValueError('truncated matrix')
            row=lines[i].strip();i+=1
            if len(row)!=n or set(row)-set('01'): raise ValueError('invalid matrix row')
            rows.append(row)
        # Zenodo has a trailing integer; qext also emits blocks without it.
        if i<len(lines) and re.fullmatch(r'\s*[-+]?\d+\s*',lines[i]): i+=1
        yield idx,rows

def atomic_json(path,data):
    tmp=Path(str(path)+'.tmp');tmp.write_text(json.dumps(data,indent=2)+'\n');os.replace(tmp,path)

def spectrum(rows):
    words=[0]
    for row in rows: words += [x^row for x in words]
    h={}
    for x in words: h[x.bit_count()]=h.get(x.bit_count(),0)+1
    return {'dimension':len(rows),'nonzero_messages':len(words)-1,'min_distance':min(x.bit_count() for x in words[1:]),'weight_spectrum':h}

def verify_solution(outdir,idx,rows,data):
    n=data['N'];w=data['w'];heads=data['solution_list'][0]
    base=[sum((c=='1')<<j for j,c in enumerate(row)) for row in rows]
    extra=[sum(((s>>t)&1)<<q for t,q in enumerate(data['free'])) | (1<<(n+i)) | (1<<(n+w-1)) for i,s in enumerate(heads)]
    matrix=base+extra
    full=outdir/f'{idx}.solution.matrix';full.write_text(''.join(''.join(str((x>>j)&1) for j in range(n+w))+'\n' for x in matrix))
    punct=outdir/f'{idx}.solution.punctured.matrix';punct.write_text(''.join(''.join(str((x>>j)&1) for j in range(n+w-1))+'\n' for x in matrix))
    result={'idx':idx,'heads':heads,'full_N':n+w,'full':spectrum(matrix),'punctured_N':n+w-1,'punctured':spectrum([x&((1<<(n+w-1))-1) for x in matrix])}
    atomic_json(outdir/f'{idx}.solution.check.json',result)
    print('REAL SOLUTION VERIFIED: '+json.dumps(result),flush=True)
    return result

def main():
    p=argparse.ArgumentParser();p.add_argument('catalog');p.add_argument('w',type=int);p.add_argument('D',type=int);p.add_argument('outdir',type=Path);p.add_argument('--jobs',type=int,default=1);a=p.parse_args()
    if not 1<=a.jobs<=2: p.error('jobs must be 1 or 2')
    out=a.outdir;out.mkdir(parents=True,exist_ok=True);items=list(read_catalog(a.catalog));stop=threading.Event();lock=threading.Lock();active=set()
    def one(item):
        idx,rows=item;dest=out/f'{idx}.json';skip=out/f'{idx}.skipped_odd.json'
        if stop.is_set(): return None
        if any(row.count('1')%2 for row in rows):
            if not skip.exists(): atomic_json(skip,{'idx':idx,'skipped_odd':True,'odd_row_indices':[i for i,r in enumerate(rows) if r.count('1')%2]})
            return json.loads(skip.read_text())
        matrix=out/f'{idx}.matrix';text='\n'.join(rows)+'\n'
        if matrix.exists() and matrix.read_text()!=text: raise ValueError('existing matrix differs')
        matrix.write_text(text)
        if dest.exists():
            d=json.loads(dest.read_text())
            if (d['N'],d['kappa'],d['w'],d['D'])!=(len(rows[0]),len(rows),a.w,a.D): raise ValueError('existing result parameters differ')
        else:
            tmp=out/f'{idx}.json.tmp';log=out/f'{idx}.log'
            with log.open('w') as f:
                with lock:
                    if stop.is_set(): return None
                    proc=subprocess.Popen([str(HERE/'ext2'),str(matrix),str(a.w),str(a.D),str(tmp)],stderr=f,stdout=f);active.add(proc)
                rc=proc.wait()
                with lock: active.discard(proc)
                if rc:
                    if stop.is_set(): return None
                    raise RuntimeError(f'ext2 index {idx} failed {rc}; see {log}')
            d=json.loads(tmp.read_text());os.replace(tmp,dest)
        d['idx']=idx
        print(f"idx={idx} F={d['F_size']} edges={d.get('edges',0)} solutions={d['solutions']} seconds={d['seconds']:.3f}",flush=True)
        if d['solutions']:
            with lock:
                stop.set()
                for proc in active: proc.terminate()
            verify_solution(out,idx,rows,d)
        return d
    started=time.monotonic()
    with concurrent.futures.ThreadPoolExecutor(max_workers=a.jobs) as pool: results=[d for d in pool.map(one,items) if d is not None]
    keys=['idx','F_size','F_sha256','edges','c3','c4','c5','solutions','seconds','stage_seconds','skipped_odd','odd_row_indices']
    summary={'catalog':str(Path(a.catalog).resolve()),'catalog_sha256':hashlib.sha256(Path(a.catalog).read_bytes()).hexdigest(),'w':a.w,'D':a.D,'jobs':a.jobs,'catalog_count':len(items),'completed':len(results),'stopped_on_solution':stop.is_set(),'wall_seconds':time.monotonic()-started,'codes':[{k:d[k] for k in keys if k in d} for d in results],'solution_indices':[d['idx'] for d in results if d.get('solutions',0)>0]}
    atomic_json(out/'summary.json',summary)
    return 3 if stop.is_set() else 0
if __name__=='__main__': sys.exit(main())
