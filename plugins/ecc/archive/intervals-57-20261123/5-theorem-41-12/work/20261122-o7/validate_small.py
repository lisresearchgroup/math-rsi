#!/usr/bin/env python3
"""Independent oracle: literal vectors and full expanded-code enumeration.
No edges, clique intersection, XOR-depth subset test, or distance transform
is used to decide extensions. All even singleton heads are expanded and
fully enumerated first. A failed singleton excludes every superset because
its actual codewords remain present. Enumerate EVERY j-subset of the
surviving singleton domain, independently for j=2..m, expanding and fully
enumerating its entire (k+j)-row code. This is an exact exhaustive factoring
of the full even syndrome-subset domain; odd heads are excluded by SPEC.
"""
import hashlib,itertools,json,random,subprocess,time
from pathlib import Path
HERE=Path(__file__).resolve().parent
OUT=HERE/'small';OUT.mkdir(exist_ok=True)

def words(rows):
    z=[0]
    for r in rows:z += [c^r for c in z]
    return z

def canonical(rows,n):
    # Independent Gaussian elimination with row lists, left-to-right.
    a=[[(x>>j)&1 for j in range(n)] for x in rows];p=[];k=0
    for j in range(n):
        t=next((i for i in range(k,len(a)) if a[i][j]),None)
        if t is None:continue
        a[k],a[t]=a[t],a[k]
        for i in range(len(a)):
            if i!=k and a[i][j]:a[i]=[u^v for u,v in zip(a[i],a[k])]
        p.append(j);k+=1
    return p,[j for j in range(n) if j not in p]

def oracle(rows,n,w,D):
    piv,q=canonical(rows,n);rho=len(q);base=words(rows)
    reps={s:sum(((s>>t)&1)<<j for t,j in enumerate(q)) for s in range(1<<rho) if s.bit_count()%2==0}
    depths={s:min((x^c).bit_count() for c in base) for s,x in reps.items()}
    F=[]
    for s,x in reps.items():
        if not s:continue
        expanded=words(rows+[x|(1<<n)|(1<<(n+w-1))])
        if min(c.bit_count() for c in expanded[1:])>=D:F.append(s)
    # Full matrix word enumeration, not graph/subset-condition logic.
    counts={};sols=[];tested={}
    for j in range(2,w):
        count=0;tested[j]=0
        for heads in itertools.combinations(F,j):
            tested[j]+=1
            extra=[reps[s]|(1<<(n+i))|(1<<(n+w-1)) for i,s in enumerate(heads)]
            expanded=words(rows+extra)
            good=min(c.bit_count() for c in expanded[1:])>=D
            if good:
                count+=1
                if j==w-1:sols.append(list(heads))
        counts[j]=count
    return F,depths,counts,sols,tested,piv,q

def main():
    rng=random.Random(20261122);cases=[];seen=set()
    # Twelve nonempty full solution tables, including repeated columns.
    for i in range(12):
        rho=6;k=1+i%3;n=rho+k
        while True:
            rows=[]
            for _ in range(k):
                r=rng.randrange(1,1<<n)
                if r.bit_count()%2:r^=1
                rows.append(r)
            cw=words(rows)
            if len(set(cw))==1<<k and min(x.bit_count() for x in cw[1:])>=4 and (n,tuple(sorted(cw))) not in seen:break
        cases.append((rows,n,4+i%2,4));seen.add((n,tuple(sorted(cw))))
    # Twenty-one further cases, all rho=6..12, w=4/5/6.
    for rho in range(6,13):
        n=rho+1;weight=n-1 if n%2 else n-2
        for w in (4,5,6):
            D=6 if rho<=7 else 2*((n//2+5)//2)
            D=min(D,weight)
            row=next(sum(1<<j for j in pos) for pos in itertools.combinations(range(n),weight) if (n,(0,sum(1<<j for j in pos))) not in seen)
            seen.add((n,(0,row)))
            cases.append(([row],n,w,D))
    report=[];start=time.monotonic()
    for idx,(rows,n,w,D) in enumerate(cases,1):
        name=f'{idx:02d}';matrix=OUT/(name+'.matrix');dest=OUT/(name+'.json');dump=OUT/(name+'.F')
        matrix.write_text(''.join(''.join(str((r>>j)&1) for j in range(n))+'\n' for r in rows))
        subprocess.run([str(HERE/'ext2'),str(matrix),str(w),str(D),str(dest),'--dump-F',str(dump)],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
        got=json.loads(dest.read_text());F,depths,counts,sols,tested,piv,q=oracle(rows,n,w,D)
        expected={'F_size':len(F),'F_sha256':hashlib.sha256(''.join(f'{s}\n' for s in F).encode()).hexdigest(),'pivots':piv,'free':q,'min_distance_K':min(c.bit_count() for c in words(rows)[1:]),'solutions':len(sols),'solution_list':sols[:100000]}
        expected['edges']=counts[2]
        expected.update({f'c{j}':counts[j] for j in range(3,w)})
        hist={str(d):sum(v==d for v in depths.values()) for d in range(0,n+1,2)};expected['depth_hist_even']=hist
        failures={key:{'expected':val,'actual':got.get(key)} for key,val in expected.items() if got.get(key)!=val}
        actualF=[int(s) for s in dump.read_text().splitlines()]
        if actualF!=F:failures['F_elements']={'expected':F,'actual':actualF}
        if bool(got.get('solution_list_truncated',False))!=(len(sols)>100000):failures['truncation']=True
        entry={'idx':idx,'N':n,'kappa':len(rows),'rho':n-len(rows),'w':w,'D':D,'F_size':len(F),**{('edges' if j==2 else f'c{j}'):c for j,c in counts.items()},'solutions':len(sols),'subsets_fully_expanded':tested,'repeated_columns':len({tuple((r>>j)&1 for r in rows) for j in range(n)})<n,'pass':not failures}
        report.append(entry)
        if failures:
            (OUT/'FAILURE.json').write_text(json.dumps({'case':entry,'failures':failures},indent=2)+'\n');raise SystemExit('MISMATCH: STOP, see small/FAILURE.json')
        print(f"small {idx}: rho={n-len(rows)} w={w} D={D} F={len(F)} solutions={len(sols)} PASS",flush=True)
    assert len(seen)==len(cases)
    summary={'all_pass':True,'distinct_mother_rowspaces':len(seen),'count':len(report),'nonempty':sum(x['solutions']>0 for x in report),'empty':sum(x['solutions']==0 for x in report),'seconds':time.monotonic()-start,'cases':report}
    (OUT/'verification.json').write_text(json.dumps(summary,indent=2)+'\n')
    assert summary['nonempty']>=8 and summary['empty']>=8
if __name__=='__main__':main()
