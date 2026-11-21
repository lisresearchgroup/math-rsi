# MathRSI v7

The seven-dimensional Ruskey–Savage working proof now covers every matching. The Happy Ending manuscripts give smaller numbers of points sufficient to force convex octagons and nonagons and add a bound for decagons. Version 7 brings both methods into the existing route, proof and verification stages. The preceding release is [v6](https://github.com/lisresearchgroup/math-rsi/releases/tag/v6).

## Results by setting

| Problem | Earlier result | v7 snapshot |
| --- | --- | --- |
| Matching extension in the 7-cube | v5 covered every matching with at least 57 edges. The fixed v6 tag covered every matching with at least 56. | Every matching, including the empty and perfect matchings, lies on a Hamilton cycle through all 128 vertices. The author working proof first entered main in [#50](https://github.com/lisresearchgroup/math-rsi/pull/50). |
| Convex heptagon | ES(7) ≤ 77 in the preceding manuscript | ES(7) ≤ 77 |
| Convex octagon | ES(8) ≤ 319 in [Schroeder’s preprint](https://michaelschroeder.ai/research/ErdosSzekeres/companion) | ES(8) ≤ 294, a reduction of 25 points against that bound |
| Convex nonagon | ES(9) ≤ 1,148 in the preceding manuscript | ES(9) ≤ 1,100, a reduction of 48 points |
| Convex decagon | 5,645 from [Nassajian Mojarrad and Vlachos, Theorem 1.1](https://arxiv.org/pdf/1510.06255) | ES(10) ≤ 3,980, newly included in the project overview |

Here ES(m) denotes the least number of points in general position in the plane that guarantees a convex m-gon. Each Happy Ending entry gives an upper bound. The three latest bounds come from the [November 20 manuscripts in #52](https://github.com/lisresearchgroup/math-rsi/pull/52). Their structural arguments and mathematical imports await independent review. The [Q₇ case study](../case-studies/ruskey-savage-q7/README.md) records the author’s proof status, imports and local replay. Research on the full Q₇ theorem used a local adaptation of v3.

## What changes in the shared workflow

**Extend a prescribed input to a terminal object.** If a theorem accepts a whole range of large inputs, look for a finite extension that preserves every original requirement. Compare the possible terminal sizes with the theorem’s exact domain. For Q₇, adding disjoint edges preserves the matching. Counting forces every inclusion-maximal extension to have at least 45 edges, and the dense theorem starts at 46. This leaves one obstruction, an inclusion-maximal matching of size 45. Excluding it suffices for every smaller starting size too. This workflow first landed on main after the v6 tag. [Terminal-domain comparison](../base/skills/mathrsi-prove/references/actual-input-coverage.md)

**Retain the choices that can coexist.** When one representative per class gives a weak count, construct all admissible choices on the same input. Prove their union is a legal input to the capacity bound, count overlaps and record how much of the integer budget each extra choice consumes. In the nine-vertex Happy Ending calculation a hypothetical critical input leaves two units, while each unit of a particular deficit costs six. This forces that deficit to vanish, including every excess choice in the corresponding classes. The other two units may still be spent elsewhere. Earlier versions already tracked equality on the same object. The new instruction makes the multiplicity of choices usable even at a positive remaining budget. [Choice counting in the proof workflow](../base/skills/mathrsi-prove/references/critical-equality.md)

## What lives in each plugin

- The Hamilton plugin carries the face-pairing rules needed to join the two sides of a cube, the dense-layer dependencies, and the E38 calculation for the last maximal size. Two C++ implementations reproduced all 18,237,120 ordered cross-independent face pairs, with zero satisfying the necessary imbalance cap. The full theorem also uses earlier proof layers. [Methods](../plugins/hypercube-hamilton/skills/mathrsi-hypercube-hamilton/references/q7-closure-methods.md) · [E38 reproduction](../plugins/hypercube-hamilton/archive/q7-closure/README.md)
- The Happy Ending plugin constructs an induced set from every possible penultimate vertex of each last lock owner. Four nonnegative deficits on the same input feed one weighted budget. At eight vertices the budget alone gives the intermediate capacity at most 293. A further common-budget argument gives 292, and the chart and planar implications give ES(8) ≤ 294. [Method and worked bounds](../plugins/happy-ending/skills/mathrsi-happy-ending/references/nmrs-higher-bounds.md) · [Manuscripts and imports](../plugins/happy-ending/archive/nmrs-20261120/HANDOFF.md)

The Happy Ending portable checker now uses the transported partial red-hole cost specified by the manuscript. The corrected finite replay passed on macOS, including the supplied scalar data, arithmetic and two explicit colorings. Historical large SAT proofs are represented by their original receipts. The [verification record](../plugins/happy-ending/archive/nmrs-20261120/VERIFICATION.md) gives the scope of each check.
