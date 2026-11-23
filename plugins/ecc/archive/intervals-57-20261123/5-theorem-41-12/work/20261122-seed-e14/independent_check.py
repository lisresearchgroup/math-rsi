#!/usr/bin/env python3
# Independent: reads generator_12x41.txt only; no harness imports.
import json
lines=[l.strip() for l in open("generator_12x41.txt") if l.strip()]
assert len(lines)==12 and all(len(l)==41 and set(l)<={"0","1"} for l in lines)
R=[[int(c) for c in l] for l in lines]
# rank by row reduction on lists
M=[r[:] for r in R]; rank=0
for c in range(41):
    p=next((i for i in range(rank,12) if M[i][c]),None)
    if p is None: continue
    M[rank],M[p]=M[p],M[rank]
    for i in range(12):
        if i!=rank and M[i][c]: M[i]=[a^b for a,b in zip(M[i],M[rank])]
    rank+=1
# enumeration: message bit i selects row i (row 1 = bit 0); codeword string leftmost=coord 1
rowint=[int(l[::-1],2) for l in lines]  # bit j = char j
spec={}; best=None; cws=set(); evenall=True
for m in range(1,4096):
    cw=0
    for i in range(12):
        if (m>>i)&1: cw^=rowint[i]
    w=bin(cw).count("1")
    spec[w]=spec.get(w,0)+1
    cws.add(cw)
    if w&1: evenall=False
    if best is None or w<best[0]: best=(w,m,cw)
w,m,cw=best
cwstr="".join(str((cw>>j)&1) for j in range(41))
out=dict(n=41,k_declared=12,rank=rank,nonzero_messages=4095,distinct_nonzero_codewords=len(cws),zero_codeword_absent=0 not in cws,
 min_weight=w,even_code=evenall,spectrum={str(k):spec[k] for k in sorted(spec)},spectrum_total=sum(spec.values()),
 min_weight_message_rows_1based=[i+1 for i in range(12) if (m>>i)&1],min_weight_message_bits_lsb_first="".join(str((m>>i)&1) for i in range(12)),
 min_weight_codeword=cwstr,min_weight_codeword_support_1based=[j+1 for j in range(41) if cwstr[j]=="1"])
exp={"14":160,"16":456,"18":699,"20":943,"22":931,"24":611,"26":233,"28":37,"30":25}
out["matches_expected_spectrum"]=out["spectrum"]==exp
out["target_constructed_d14"]= rank==12 and w>=14
print(json.dumps(out,indent=1)); json.dump(out,open("independent_check.json","w"),indent=1)
