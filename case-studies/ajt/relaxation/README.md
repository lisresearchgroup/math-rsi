# Exact obstructions to the real double-block Delsarte relaxation

There are exact rational false joint enumerators in dimensions 12 and 16. They give false enumerators in all positive multiples of these dimensions by convolution. These distributions certify that the specified real linear constraints cannot force a positive full-weight cell \(A_{n,n}\) in all dimensions. Their entries are rational formal counts.

## Constraints and witnesses

Let \(A_{i,j}\) index the input and output weights of a graph code, and let \(\mu_i=\binom ni4^i\). The two marginals of \(A\) equal \(\mu\), its origin is 1, and its other axis entries are zero. Let \(K_{r,i}=[z^r](1+4z)^{n-i}(1-z)^i\). The dual distribution is \(B=5^{-n}KAK^{\mathsf T}\). For a graph of a matrix \(L\), \(B_{r,s}\) would count vectors \(v\) with \(\mathrm{wt}(L^{\mathsf T}v)=r\) and \(\mathrm{wt}(v)=s\). Thus \(A\) and \(B\) have different indexing interpretations.

Each certificate has \(A=A^{\mathsf T}\ge0\), \(A_{n,n}=0\), and \(A_{i,j}=0\) in the positive cells satisfying
\[
i+j\le5
\quad\text{or}\quad
\min(i,j)=1,\ \max(i,j)\le5.
\]
Both have \(B\ge0\) with the same marginals and axes. They also enforce the following dual zeros.

| Dimension | Certificate | Additional dual zeros |
| ---: | --- | --- |
| 12 | [Exact rational entries](certificate-12.json) | \(B_{r,s}=0\) for \(1\le r,s\le 2\). In particular this checks the row-combination constraint from round 014 in the dual weight ordering. |
| 16 | [Exact rational entries](certificate-16.json) | The entire positive-cell forbidden set above also vanishes in \(B\). This is an extra restriction imposed directly on the relaxation. |

The stronger dimension-16 certificate does not require an implication from failure for \(L\) to failure for \(L^{\mathsf T}\). The proof only concerns the stated real relaxation. It does not address whether integral linear-code enumerators with further congruence or support constraints exist.

Each certificate stores \(A\) by a common denominator and its positive upper-triangle numerators. The origin is implicit. The verifier reconstructs all entries, forms \(KAK^{\mathsf T}\) over the integers before division, and checks axes, both marginals, the forbidden cells, and nonnegativity exactly. [Verifier](verify.py) · [Recorded output](VERIFIED.txt)

## Propagation to arbitrarily large dimensions

Write \(F_n(x,y)=\sum_{i,j} A_{i,j} x^i y^j\) for an admissible formal table, and \(G_n\) for its dual polynomial. The coefficient definition of \(K\) gives
\[
G_n(x,y)=
5^{-n}(1+4x)^n(1+4y)^n
F_n\left(\frac{1-x}{1+4x},\frac{1-y}{1+4y}\right).
\]
Therefore, for two such distributions, the dual of the product \(F_nF_m\) is \(G_nG_m\). The product coefficients are nonnegative, the origin and axes are preserved, and the \((1+4x)^n\) and \((1+4y)^n\) marginals multiply as required. The coefficient of \(x^{n+m}y^{n+m}\) is the product of the two top coefficients and vanishes.

For the stronger forbidden pattern, any nonzero supported cell has both indices positive and total degree at least 6. In a product, combining at least two nonzero cells gives both indices at least 2 and total degree at least 12. Combining one nonzero cell with the origin retains the original supported cell. Thus the pattern is preserved for the primal products and for dual products of the dimension-16 certificate. For dual products of the dimension-12 certificate, each nonzero cell already has one index at least 3, and addition of nonnegative indices preserves this property.

The standard-library-only replay below checks dimensions 12 and 16 and also their convolution squares, dimensions 24 and 32.

~~~sh
python3 verify.py --twice
~~~

[explore.py](explore.py) and [certify.py](certify.py) record how the seeds were found. HiGHS proposed strictly feasible values in normalized coordinates. Exact rational elimination then enforced the required equalities. The verification above does not use the optimizer or floating-point arithmetic.
