# Six mathematical research threads

[English entry](../README.md) · [中文入口](../README.zh-CN.md) · [Bilingual visual tour](../docs/HOMEPAGE.md) · [Domain routing](../docs/DOMAIN_ROUTING.md)

This page indexes all six research threads, summarizing what has been established and linking to each case's proofs, verification checks and runnable tools. Local HTML readers can be opened directly in a browser after cloning.

## Property B

**Hypergraph two-coloring:** concrete lower bounds for $m(5),\ldots,m(12)$ reach $35,67,131,267,543,1112,2275,4664$, and a uniform theorem gives a stronger explicit lower bound with an exponentially growing additive gain over the Radhakrishnan–Srinivasan baseline for every $k\ge12$.

The uniform $k\ge12$ theorem and $m(5)\ge33,34$ have end-to-end Lean proofs; $m(5)\ge35$ has a complete written proof with Lean formalization still in progress. The bounds for $k=6,\ldots,12$ rest on parameter-specific computer-assisted proofs; for $k=12$, an independent check covers the full parameter and trace domain and verifies 20 exact probability values.

[Case and per-parameter status](property-b/README.md) · [Offline reader](property-b/index.html) · [General theorem](property-b/readers/PROPERTY_B_GENERAL_BOUND.html) · [Lean reader](property-b/readers/PROPERTY_B_GENERAL_LEAN.html) · [Domain skill](../plugins/propertyb/skills/mathrsi-propertyb/SKILL.md)

## Error-correcting codes

**Four exact binary-code distances:** $d_2(43,10)=16$, $d_2(44,10)=17$, $d_2(44,11)=16$ and $d_2(42,16)=12$. The first three combine a complete 172-parent exclusion with matching constructions; $d_2(42,16)=12$ follows from a published 2020 theorem. The remaining case narrows to $16\le d_2(45,11)\le17$.

**Historical context.** Verhoeff's *Updating a table of bounds on the minimum distance of binary linear codes* (1985), [Appendix I, block (1,0), PDF p.45](https://pure.tue.nl/ws/portalfiles/portal/2264214/253220.pdf#page=45), listed $(43,10)$ at 16–17, $(44,10)$ at **16–18**, $(44,11)$ at 16–17 and $(45,11)$ at 16–18. Our exclusion settles the first three at 16, 17 and 16 and narrows $(45,11)$ to 16–17; see also CodeTables (checked 2026-11-12) for [43/10](https://www.codetables.de/BKLC/BKLC.php?q=2&n=43&k=10), [44/10](https://www.codetables.de/BKLC/BKLC.php?q=2&n=44&k=10), [44/11](https://www.codetables.de/BKLC/BKLC.php?q=2&n=44&k=11) and [45/11](https://www.codetables.de/BKLC/BKLC.php?q=2&n=45&k=11).

Lean reductions state their explicit literature, classification and computation premises, while reusable checkers cover concrete generator matrices and parent-code pair rejections. The plugin also includes a branch-organization walkthrough on the open $[72,36,\ge16]$ problem.

[Plugin and methods](../plugins/ecc/README.md) · [Actual checks and import boundaries](../plugins/ecc/evidence/IMPLEMENTATION.md) · [Node organization example](../plugins/ecc/skills/mathrsi-ecc/examples/node-research.md)

## Degree–Diameter

Our constructions reach **(10,4)=2,567**, **(11,5)=37,632**, **(12,5)=42,433** and **(16,4)=16,416** vertices. The 2026-11-16 diameter-five follow-up improves our (11,5) and (12,5) constructions by +1 and +31 (+1 and +81 above the Comellas table checked 2026-11-16).

Constructed on the 2026-11-11 v4-maintenance workflow with local degree–diameter updates (whose methods later informed v5 main maintenance), both D5 graphs regenerate deterministically: D12 preserves the 42,402-vertex source subgraph and runs breadth-first search from all 31 new vertices, while D11 takes core–core distances from the H9 theorem under its stated $\sigma/\pi$ identification and runs breadth-first search from all 161 peripheral and new vertices. End-to-end Lean proofs and independent refereeing for these D5 graphs remain open.

On the Comellas table checked 2026-11-16, (10,4) is 2,612 and (16,4) is 16,848, above our earlier constructions of 2,567 and 16,416. The 163-graph catalogue (across 44 parameter pairs, including intermediate orders and 49 completed concrete-graph Lean proofs) is the earlier snapshot from the (10,4) stage.

[Latest case and scope](degree-diameter/README.md) · [中文](degree-diameter/README.zh-CN.md) · [Bilingual latest reader](../development/homepage-redesign-20261105/site/dd-latest.html) · [Historical illustrated case](degree-diameter/index.html) · [Earlier v2 execution provenance](degree-diameter/evidence/execution_version.md) · [Plugin](../plugins/degree-diameter/README.md)

## Erdős Problem 86

**Finite and asymptotic $C_4$-free hypercube bounds:**
- **$Q_7$ ($n = 7$):** **`304`** — **304-edge construction verified; 304 upper bound as reported in the source package, not re-verified in this pass** (two explicit 304-edge $C_4$-free subgraphs checked in-repo; 21 raw `.cnf`/`.drup` traces were omitted in the upstream 2026-10-31 compilation).
- **$Q_8$ ($n = 8$):** **`682 ≤ ex(Q₈, C₄) ≤ 683`** — four 682-edge constructions verified in-repo; Theorem B rules out 684 edges via a same-subgraph 3-measure pullback over 83 active cuts and 25 imported $Q_6$ DRAT certificates (checked computationally and reviewed in the same model family; independent refereeing is pending, and $\mathrm{ex}(Q_8, C_4) \le 682$ remains open).
- **$Q_\infty$ (asymptotic):** **T3** $\le 681653995482306581 / 1152921504606846976 \le 0.5912405943$ and **T4** $\le 9701859764505653085708308080340303 / 16409326186106551516455239680000000 \le 0.5912405942$ ($m=1024$ degree potential via a 5-line hypergeometric tower), both proved and rechecked in 128-bit C++20, improving the v3 $Q_4$ bound ($< 0.59155154$) and the `0.60318` reference. Exploratory `0.5907` is an approximate fit (residual $\approx 3.9\times 10^{-4}$), an earlier `0.5899` claim was refuted and withdrawn, and $\pi_\square(C_4) = 1/2$ remains open.

[Per-setting case study & verification table](erdos-86/README.md) · [Bilingual public reader](../development/homepage-redesign-20261105/site/erdos-86-latest.html) · [Plugin and source map](../plugins/hypercube-extremal/README.md) · [Domain skill](../plugins/hypercube-extremal/skills/mathrsi-hypercube-extremal/SKILL.md)

## Ruskey–Savage Q6

**Every matching in $Q_6$ extends to a Hamilton cycle.** The stronger stored $P_6$ statement covers a Hamilton path from every free root to every opposite-parity target. This prescribed-endpoint $P_6$ theorem, combined with published lifting results, extends every matching in $Q_n$ using at most six coordinate directions.

The checked A10 replay rebuilds 1,024 forests, all 1,048,576 connectivity bits and rank 1,024, while the larger $P_6$ certificate streams are listed in inventory manifests rather than replayed here. The proof was reviewed in the same model family; independent refereeing is pending, there is no Lean formalization, and the general dimension-$n$ conjecture remains open.

[Plugin and mathematics](../plugins/hypercube-hamilton/README.md) · [Finite replay and whole-proof boundary](../plugins/hypercube-hamilton/evidence/IMPLEMENTATION.md) · [Domain skill](../plugins/hypercube-hamilton/skills/mathrsi-hypercube-hamilton/SKILL.md)

### Q7: every matching in the seven-dimensional cube

**The complete R7 author working proof covers every ordinary short-edge matching in the 128-vertex $Q_7$, including the empty matching and perfect matchings.** Each extends to a Hamilton cycle retaining every prescribed edge. The source project accepted the working proof on 2026-11-19 (`sound-modulo-imports · same-family · provisional`); external peer review is pending and there is no Lean formalization.

The proof joins E36 (every matching of at least 46 edges extends) with a maximality bound: double counting alone gives at least 45 edges in every inclusion-maximal matching, and E38 excludes exactly 45, yielding at least 46 without the older dense-layer theorems. Extend the original matching only by adding free cube edges to a maximal matching; a Hamilton cycle containing that larger matching also contains the original one. Two original C++ programs were run on Mac: **35,360 legal single faces and 18,237,120 ordered face pairs; zero pairs satisfy the directional necessary conditions for a maximal 45-edge matching**. This is a local E38 recomputation; some large older-layer certificates are omitted and the full imported proof chain was not replayed end to end.

**Run: v3 (local adaptation) → v6 `main` follow-up, 2026-11-20.** Fixed v5 (≥57 edges) and v6 (complete E16, ≥56 edges) snapshots are retained. Free-root paths $P_7$, seven-direction lifting and the general dimension-$n$ conjecture remain open.

[Q7 results, methods and evidence scope](ruskey-savage-q7/README.md) · [Bilingual public reader](../development/homepage-redesign-20261105/site/q7.html) · [Detailed proof guide & 26 appendices](https://github.com/lisresearchgroup/math-rsi/blob/main/plugins/hypercube-hamilton/knowledge/q7-closure-proof.md) · [Local recomputation entry](https://github.com/lisresearchgroup/math-rsi/blob/main/plugins/hypercube-hamilton/archive/q7-closure/README.md)

## Happy Ending

**Ordered rank-3 signotope capacities $N(m,r,s)$ and planar forcing corollaries ($m=7,8,9,10$ and general $m$):**

| Parameter | Current analytical working chain $Q_m/F_m/ES(m)$ | Earlier chain and evidence |
| --- | --- | --- |
| 7 | ≤75/76/77 | Historical b25 acceptance and checked E21 abstract witness retain their own scope. |
| 8 | ≤292/293/294 | Earlier ≤317/318/319 chain remains archived; planar ES(8)≤319 is Schroeder's preprint result. New ordinary 866≤56 and 858≤64 use historical fixed-CNF DRAT evidence and separate semantic bridges. |
| 9 | ≤1098/1099/1100 | Each is 48 below the earlier 1146/1147/1148 working chain, whose native-trace integer certificates remain available. |
| 10 | ≤3978/3979/3980 | New ordinary-row propagation and an integer obstruction to equality; no optimality claim. |

The new chains are same-session, unreviewed and unaccepted analytical manuscripts, with no Lean formalization. The corrected portable checker and its negative control were run on macOS, together with repository links and public staging checks; Linux execution remains pending. Finite arithmetic, color-table and receipt checks do not establish the structural and R7/R20 mathematical bridges or rerun historical DRAT proofs. [Verification scope](../plugins/happy-ending/archive/nmrs-20261120/VERIFICATION.md).

[Case summary & verification table](happy-ending/README.md) · [Bilingual public reader](../development/homepage-redesign-20261105/site/happy-ending-latest.html) · [Earlier `m = 7` reader](happy-ending/n7-20261103/START_HERE.html) · [Plugin & runnable checkers](../plugins/happy-ending/README.md)

## Research lineage and workflow feedback

Property B was researched with standalone ARIS tools and distilled into MathRSI v1. ECC continued using methods inherited through v1/v2 and deepened its formal reductions, matrix checks and portable certificates. Earlier Degree–Diameter work informed v2, which was then used to construct the 2,567-vertex $(10,4)$ graph. Erdős 86 ($Q_4$), $Q_6$ and earlier Happy Ending work informed v3; the later Happy Ending `m = 7` manuscripts and DD local-edit methods informed v4. Dense-matching $Q_7$ work ($\ge 57$ edges) on v3 fed v5, while subsequent $C_4$-free $Q_7/Q_8/Q_\infty$ coevolution, complete $Q_7$ E16 ($\ge 56$ edges), and the `m = 7, 8, 9` $N(m,r,s)$ runs (Trellis + ARIS + v3) fed v6 and its `main` maintenance. The full Q7 R7 author working proof, accepted in its source project on 2026-11-19 after v3 local adaptation, joins `v6` main maintenance on 2026-11-20; earlier release snapshots remain fixed.

[Version and maintenance records](../development/README.md) document each release's changes and verification checks. New studies run in their own [task workspace](../docs/WORKSPACE.md).

[MathRSI v7](../docs/V7_CHANGES.md) incorporates the methods from the Q₇ and Happy Ending follow-ups.
