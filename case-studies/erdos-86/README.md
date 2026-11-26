# Erdős Problem 86: finite and asymptotic C4-free hypercube bounds

[Six-domain index](../README.md#erdős-problem-86) · [Bilingual reader](../../development/homepage-redesign-20261105/site/erdos-86-latest.html) · [v6 changes](../../docs/V6_CHANGES.md) · [Hypercube extremal plugin](../../plugins/hypercube-extremal/README.md)

Erdős Problem 86 asks for the maximum number of edges $\mathrm{ex}(Q_n, C_4)$ in a $C_4$-free subgraph of the $n$-dimensional hypercube $Q_n$, and conjectures that the asymptotic edge density $\pi_\square(C_4) = \lim_{n\to\infty} \mathrm{ex}(Q_n, C_4) / (n 2^{n-1})$ equals $1/2$.

## Results by setting and verification scope

| Setting | Bound | Verification and archive scope |
| --- | --- | --- |
| **$Q_7$ ($n = 7$)** | **`304`** | [Zhou et al., arXiv:2611.27284](https://arxiv.org/abs/2611.27284) exclude 305 edges, matching Minamoto’s 304-edge construction. The [companion release](https://github.com/zhelizhou/hypercube-c4/releases/tag/q7-artifacts-v0.1) supplies all 21 refutations. Two explicit 128-vertex, 304-edge $C_4$-free subgraphs (`A.edges`, `B.edges`) and the 2-hole orbit script `six_profiles_independent_audit.py` are verified in-repo ($\mathrm{ex}(Q_7, C_4) \ge 304$; constructions alone do not prove an upper bound). The upstream reduction manuscript (`ASTRA_主证明合订.md`) and certificate manifest are preserved in [`archive/q7-304/`](../../plugins/hypercube-extremal/archive/q7-304/README.md), while the 21 raw `.cnf`/`.drup` traces were already omitted in the upstream 2026-10-31 compilation. |
| **$Q_8$ ($n = 8$)** | **`682 ≤ ex(Q₈, C₄) ≤ 683`** | Four explicit 682-edge $C_4$-free subgraphs (`seed1..4.edges`) are verified in-repo ($\mathrm{ex}(Q_8, C_4) \ge 682$). Theorem B rules out 684 edges via a same-subgraph 3-measure pullback over 83 active inequalities and 25 $Q_6$ subcube imports (`PASS · same-family · provisional` whole-proof audit; exact rational safety margin `782808475930428709 / 4209067950080000000000 > 0` and C++17 complete enumeration of all `13,150,453` marked $Q_4$ completions verified in-repo in [`archive/q8-683/`](../../plugins/hypercube-extremal/archive/q8-683/README.md)). Primary goal $\mathrm{ex}(Q_8, C_4) \le 682$ remains **OPEN**. |
| **$Q_\infty$ (asymptotic)** | **`T3 ≤ 0.5912405943`**<br>**`T4 ≤ 0.5912405942`** | Unconditional bounds improving the `v3` $Q_4$ Gram bound (`< 0.59155154`) and the `0.60318` reference: **T3** $= 681653995482306581 / 1152921504606846976 \approx 0.5912405942282728\ldots \le 0.5912405943$ ($Q_4$ flag algebra + 35 triangle-free COP cuts + 29 cubic terms) and **T4** $= 9701859764505653085708308080340303 / 16409326186106551516455239680000000 \approx 0.5912405941884453\ldots \le 0.5912405942$ (adding the $m=1024$ generalized hypergeometric degree potential). Both C++20 128-bit verifiers recompile and pass over all `3,212,821` $Q_4$ orbits in [`archive/asymptotic-05912/`](../../plugins/hypercube-extremal/archive/asymptotic-05912/README.md). Conjecture $\pi_\square(C_4) = 1/2$ remains **OPEN**. |

*Display precision note:* Eight-digit `0.59124059` is a false downward truncation and is never used as an upper bound.

## Five-line unconditional hypergeometric tower for T4 ($n \ge 1024$)

1. For every $n \ge m = 1024$ and every $C_4$-free $G \subseteq Q_n$, sampling a uniform 4-face $F \cong Q_4$ and a uniform vertex $v \in V(F)$ has the exact same joint law as sampling uniform $v \in V(Q_n)$, uniform $S \in \binom{[n]}{1024}$, and uniform $T \in \binom{S}{4}$ spanning $F$ through $v$.
2. The induced local degree $\deg_{G[F]}(v)$ counts only edges incident to $v$ in directions $T$, depending solely on $(v, T)$.
3. Conditioning on $(v, S)$ with retained degree $d_S(v) \in \{0,\ldots,1024\}$, hypergeometric expectation gives $\mathbb{E}[\sum_{k=0}^4 b_k \mathbf{1}_{\deg=k} \mid v, S] = \Phi_{1024}(d_S(v)) / \binom{1024}{4} \ge \mu_{1024} / \binom{1024}{4}$.
4. Summing over the 16 vertices of $F$ by linearity of expectation requires no vertex independence and holds identically for all $n \ge 1024$: $\mathbb{E}_F[a + \sum_{k=0}^4 b_k h_k(G[F])] \ge a + 16\mu_{1024} / \binom{1024}{4}$.
5. Combining with the standard $O(1/n)$ flag-algebra sampling collision bound on $Q_n$ yields Theorem T4 unconditionally.

## Non-theorem boundaries and coevolution lessons

- **`0.5907` is not a theorem:** An exploratory completely positive fit around `0.5907` carries a nonzero feasibility residual of $\approx 3.9 \times 10^{-4}$ and is recorded only as an uncertified numerical diagnostic.
- **Retracted $Q_5$ `0.5899` lesson:** An early sampled-corpus $Q_5$ claim was refuted by the out-of-sample legal $C_4$-free graph `0x69966996699616682994` (scoring `0.5922454`) and a `6 × C(4,2) = 36` vs `6` quadratic normalization audit.
- **Primal–dual coevolution ([`cube_coevolve`](../../plugins/hypercube-extremal/tools/cube_coevolve/README.md)):** Separates the open proof goal ($\le 682$) from the counterexample target (`683`), rotates 4-channel normalized signed residuals, and refutes candidate cuts against the **entire** graph archive before exporting `empirical` obligations to exact proof.

## Provenance and runnable commands

Research ran with **MathRSI v3** plus local primal–dual coevolution; reusable methods and curated assets are integrated in `v6`. Runnable stdlib + C++17/20 reproduction commands and external-archive `INVENTORY.json` boundaries (where SHA-256 hashes identify external files without substituting for trace replay) are documented in [`plugins/hypercube-extremal/skills/mathrsi-hypercube-extremal/references/reproduction.md`](../../plugins/hypercube-extremal/skills/mathrsi-hypercube-extremal/references/reproduction.md).
