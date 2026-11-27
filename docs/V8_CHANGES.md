# MathRSI v8 · Better binary codes and tighter distance bounds

For 18 choices of code length and dimension, you can now download a generator matrix for a code with a better guaranteed distance than the 22 November 2026 CodeTables snapshot. For 32 other settings, published nonexistence theorems imply a stronger upper bound. These two advances answer different questions. A construction shows what a code can do. An upper bound tells us what every code of the given size must fall short of. [Explore the bilingual results](https://lisresearchgroup.github.io/math-rsi/ecc-intervals.html)

## Codes you can use

One matrix encodes 43 information bits in 72 bits. Its minimum distance is exactly 11, so it can correct any five bit flips under minimum-distance decoding. The old table's lower bound of 10 guaranteed four. For this setting, the optimal distance is now known to lie between 11 and 14. Add a parity bit to this same code and its minimum distance becomes 12 at length 73. Across the 18 settings, ten gain one guaranteed correctable error. [Download the matrices](https://lisresearchgroup.github.io/math-rsi/ecc-intervals.html#lower)

The scan produced 22 matrices at 15 distinct settings. At 13 of the 18 final settings, a direct hit attains the reported lower bound. For the other five, the strongest result comes from parity extension or puncturing. Two of those five also had a weaker direct hit. You can export the strongest matrix for any of the 18 settings locally. [Exporter and worked example](../plugins/ecc/skills/mathrsi-ecc/references/constructive-intervals.md)

## Distances that can be ruled out

For length 52 and dimension 25, a distance-12 code was already known. The new deduction rules out distance 13 or higher, which settles the optimal distance at 12. This is one of nine optima settled by a family of 32 deductions. The 37-step chain uses three published nonexistence results and 54 previously recorded table bounds. Each step names its premises. [Read the derivations](../plugins/ecc/archive/intervals-57-20261123/3-corollaries-32/DERIVATIONS.md)

| Entries tracked against the dated snapshot | Settings | Exact optima supported at release |
| --- | ---: | ---: |
| Earlier upper bounds from v0 and v2 | 5 | 4 |
| New constructive lower bounds | 18 | 0 |
| New upper bounds from published theorems | 32 | 9 |
| Additional upper bounds awaiting final source-project acceptance | 2 | pending |
| **Total** | **57** | **13 confirmed, 2 pending** |

The last two entries concern a single computer-assisted exclusion of a binary [41,12,15] code and its consequence at [42,12]. Their proposed optima are 14 and 15 respectively. The proof used a v6 research setup. Gemini Carbon completed the supplementary technical review during v8 integration. The source project's final acceptance remains open. [Release checks and scope](../plugins/ecc/evidence/v8-20261123/REVIEW.md) · [Shareable results figures](../figures/ecc-intervals-20261123/README.md)

## What changed in the workflow

- **Deliver the witness at the reported setting.** If a neighboring code gives a better construction, perform the transformation, check that it preserves the necessary properties and return the resulting object. [Proof workflow](../base/skills/mathrsi-prove/references/actual-input-coverage.md)
- **Exercise rejection rules that the normal run seldom reaches.** Relax one condition to produce near misses and use an independent calculation to show why the original rule rejects them. Catalogue completeness and full search coverage are separate mathematical obligations. [Verification workflow](../base/skills/mathrsi-verify/SKILL.md)
- **Retain the premises of propagated bounds.** The ECC plugin separates a supplied matrix, an imported theorem and a dated table entry. This lets a reader reproduce an upper-bound deduction or recover a constructive witness for one setting. [ECC plugin](../plugins/ecc/README.md)

PR #56 updates the original five-parameter paper and its reproducibility instructions. PR #57 supplies the interval ledger, code matrices, derivations and scan records. Results are compared with the archived table snapshot. [Manuscript update](https://github.com/lisresearchgroup/math-rsi/pull/56) · [Evidence archive](https://github.com/lisresearchgroup/math-rsi/pull/57)

## AJT follow-up · 27 November 2026

Using v8, the team proved the Alon–Jaeger–Tarsi conjecture in dimensions 10 and 11 over the five-element field. The dimension-11 proof extracts a relation among five coordinates of the same matrix and counts again with those coordinates marked. The ECC plugin now explains how to reuse that step for graph codes. The shared route workflow also records what to do when a table of counts loses too much information: test its limits with an exact rational example, then return to the matrix for a relation the table omitted. These updates landed on main after the v8 release. [Paper and Lean proofs](../case-studies/ajt/README.md) · [ECC method](../plugins/ecc/skills/mathrsi-ecc/SKILL.md#ajt) · [Route workflow](../base/skills/mathrsi-route-loop/SKILL.md)
