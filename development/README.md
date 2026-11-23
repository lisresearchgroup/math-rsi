# Implementation and evolution records

[Repository entry](../README.md) · [Documentation](../docs/README.md) · [Research results](../case-studies/README.md)

Two tracks evolve together: shared **Base behavior** and broader/deeper **domain plugins**. Research evidence includes failures and partial work. These links lead to the existing implementation and review records; mathematical results keep the provenance recorded by each case.

## Versions and maintenance

| Stage | Base changes | Domain changes and original record |
| --- | --- | --- |
| v0 · pre-harness | Standalone research skills and problem workspaces; no Git tag. | Property B and ECC source research. [Actual transitions](workflow-redesign/REAL_PROJECT_TRANSITIONS.md) |
| v1 | Five solving stages, three-layer contract, adversarial route iteration, wiki reuse and optional Lean. | Property B and initial ECC. [Workflow design](workflow-redesign/REVIEW_DISPOSITION.md) · [Release validation](publish-v1/REPORT.md) |
| v2 | Added separate meta-evolve maintenance; rechecked evidence inheritance, baselines and common coverage in the existing workflows. | DD integration. [Changes](../docs/V2_CHANGES.md) · [Implementation](evolution/dd-v2-20261102/EVOLUTION.md) |
| v3 | Working-set/full-domain/best separation, marked-object transport, finite universal certificates and explicit Lean-premise audits. | Upgraded ECC; added hypercube extremal, hypercube Hamilton and Happy Ending. [Changes](../docs/V3_CHANGES.md) · [Implementation](evolution/v3-20261104/EVOLUTION.md) |
| v4 · historical release | Equality-chain structure, legal exchange and compatible witnesses at the original caller. | Happy Ending and DD deepening. [Changes](../docs/V4_CHANGES.md) · [Implementation](evolution/v4-20261108/EVOLUTION.md) · [Release](evolution/v4-20261108/RELEASE.md) |
| v4 · later main maintenance | Mandatory global progress reassessment compares the original gap and total cost. | ECC node ownership, exclusion reuse, shared computations and parent coverage. [Base maintenance](evolution/v4-global-reassessment-20261108/EVOLUTION.md) · [ECC maintenance](evolution/ecc-node-v4-20261111/EVOLUTION.md) |
| v5 · historical release | Controlled auxiliary choices, theorem reuse across known legal representations, and fixed/conditional finite-plan coverage. | Deeper hypercube Hamilton methods from Q7 research run with v3 (local adaptation). [Changes](../docs/V5_CHANGES.md) · [Implementation](evolution/v5-q7-20261114/EVOLUTION.md) |
| v5 · main maintenance · 2026-11-16 | Consume results before dispatch. [Dated DD follow-up](../docs/V5_CHANGES.md#dd-follow-up--2026-11-16) · [Implementation record](https://github.com/lisresearchgroup/math-rsi/blob/main/development/evolution/v5-dd-20261116/EVOLUTION.md); fixed v5 tag unchanged. | Existing pairs reach (11,5)=37,632 and (12,5)=42,433. Run: v4 + local updates. [Results and methods](../case-studies/degree-diameter/README.md) |
| v6 · historical release tag | Hardest-remainder split gating & net-new union coverage, primal–dual coevolution (`primal-dual-coevolution.md`), and repair-residual stopping. | $C_4$-free $Q_7/Q_8/Q_\infty$ + `cube_coevolve` (`hypercube-extremal`) and complete $Q_7$ E16 $\ge 56$-edge closure (`hypercube-hamilton`). [Changes](../docs/V6_CHANGES.md) · [Implementation](evolution/v6-c4free-rs7-20261117/EVOLUTION.md) |
| v6 · main maintenance · 2026-11-17 | Relaxation-ceiling exhaustion stopping and generative sparse integer dual verification (`(q, p, inc, exc, weight)` + `{0,1}` overload penalty). Fixed `v6` tag unchanged. | Happy Ending / $N(m,r,s)$ across $m = 7, 8, 9$ & general $m$: replayed $N(8,6,6)\le 61$ (`milestone9`), $N(9,8,8)\le 688$ & $D_9\le 458$ native-trace duals ($\to$ working $\mathrm{ES}(9)\le 1148$), signotope $N(8,8,8)\le 318$ transfer, and $m=7$ analytic $39/49$ + lock-block $\le 4$. Run: Trellis + ARIS + v3. [Follow-up](../docs/V6_CHANGES.md#happy-ending-nmrs-follow-up--2026-11-17) · [Implementation](evolution/v6-nmrs-20261117/EVOLUTION.md) |
| v6 · main maintenance · 2026-11-20 | After a dense theorem, check which inclusion-maximal extensions can still fall outside its scope. | Full seven-dimensional matching-extension working proof, with a portable replay of its final finite exclusion. [Proof, use and verification](evolution/q7-closure-20261120/EVOLUTION.md) |
| v7 | Count all compatible choices on one input and compare maximal extensions with the proved dense range. | Full Q₇ author working proof and Happy Ending bounds for convex 8-, 9- and 10-gons. [Integration](evolution/v7-q7-happy-ending/EVOLUTION.md) · [Release notes](../docs/V7_CHANGES.md) |
| v8 | Export the strongest witness for each setting, exercise rare rejection paths and retain the premises of each exclusion. | 18 constructive lower bounds, 32 new upper-bound deductions and two entries awaiting source acceptance. [Release notes](../docs/V8_CHANGES.md) · [Verification](../plugins/ecc/evidence/v8-20261123/REVIEW.md) |

Each release tag fixes the corresponding snapshot. Development continues on `main`. The [evolution workflow](../docs/EVOLUTION_WORKFLOW.md) explains how to make a scoped maintenance request.

## Validation and implementation

- [Validation record](VALIDATION.md): original bundle, helper, protocol and bounded mathematical checks, with commands and actual limits. Its dated entries are historical snapshots; consult the later version records above for adoption status.
- [v3 base changes](evolution/v3-20261104/base/BASE_CHANGES.md) and [actual use](evolution/v3-20261104/base/USE.md): concrete failure-to-action connections.
- [v4 scope](../docs/V4_CHANGES.md): actual counterexample/witness checks and ten DD edit reconstructions; static model review is distinguished from executed mathematics.
- [Initial review dispositions](REVIEW_DISPOSITION.md): source discussions and adopted fixes.
- [GitHub entry redesign](github-redesign-20261111/IMPLEMENTATION_STATUS.md): worktree ownership, presentation checks and PR handoff.

## Presentation sources

- [Current bilingual visual tour](../docs/HOMEPAGE.md): actual HTML remains at `homepage-redesign-20261105/site/index.html`.
- [Current and historical diagrams](../figures/mathrsi/README.md): FigureSpec, SVG, raster alternative and generation instructions.

Research archives remain at their original paths. This index neither restarts archived work nor upgrades its assurance status.
