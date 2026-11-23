#!/usr/bin/env python3
"""Build 12x41 generator matrix: cyclic [43,15,13] -> +parity [44,15,14] -> shorten at 1-based {42,43,44}.
Convention: coordinate i (1-based) = coefficient of x^(i-1); in the text file leftmost char = coordinate 1.
Parity bit = coordinate 44."""
EXP=[28,27,26,24,21,20,19,17,16,14,12,11,9,8,7,4,2,1,0]
g=sum(1<<e for e in EXP)   # bit j = coeff of x^j
def pmod(a,b):
    db=b.bit_length()
    while a.bit_length()>=db: a^=b<<(a.bit_length()-db)
    return a
xn1=(1<<43)|1
assert g.bit_length()-1==28
rem=pmod(xn1,g); print("deg g =",g.bit_length()-1,"; (x^43-1) mod g =",rem,"-> divides:",rem==0)
assert rem==0
n,k=43,15
rows=[]
for i in range(k):
    r=g<<i
    assert r.bit_length()<=n
    r|=(bin(r).count("1")&1)<<43      # parity bit at coordinate 44 (bit 43)
    rows.append(r)
# shorten at bits 41,42,43: kernel of message->those bits
dels=[41,42,43]
# eliminate: pivot on deleted coordinates
work=list(rows); piv=[]
for c in dels:
    p=next((j for j,r in enumerate(work) if (r>>c)&1 and j not in piv),None)
    assert p is not None
    for j in range(len(work)):
        if j!=p and (work[j]>>c)&1: work[j]^=work[p]
    piv.append(p)
kept=[work[j] for j in range(len(work)) if j not in piv]
assert len(kept)==12
mask=(1<<41)-1
for r in kept: assert r>>41==0
kept=[r&mask for r in kept]
txt="\n".join("".join(str((r>>j)&1) for j in range(41)) for r in kept)+"\n"
open("generator_12x41.txt","w").write(txt)
print(txt)
