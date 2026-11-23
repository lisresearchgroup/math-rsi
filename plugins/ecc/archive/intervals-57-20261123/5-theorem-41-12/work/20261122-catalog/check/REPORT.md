# Catalog check report (CatalogCheck)

Tool: `catalog_check.py` (python3 + numpy 2.2.6; multiprocessing, default 3 jobs).
Usage: `python3 catalog_check.py CATALOG.2 N K D --out DIR [--jobs J] [--selftest S] [--pair-timeout SEC] [--no-exact]`

Per code: rows/row-length, GF(2) rank, full enumeration of 2^k-1 nonzero codewords (min distance, weight distribution),
zero columns, all-even flag, projective flag + column-multiplicity histogram, hull dim = k - rank(GG^T) vs `HULL=h`,
group order, equivalence invariant. `checks_pass` per code = k,n match, rank=k, d exact, no zero cols, hull matches header,
group order present. CRLF handled.

Invariant: colour refinement on codeword(2^k-1) x coordinate incidence; initial codeword colour = weight; alternating
updates; colours are 64-bit splitmix hashes of (old colour, SUM of mixed colours of incident vertices mod 2^64) - a multiset
hash, hence independent of coordinate order and basis; stops when class counts stop growing (cap 10 rounds; observed 3-5).
Final = SHA-256 of (sorted coordinate colours | sorted codeword colours). Distinct invariants => inequivalent (sound; hash
collisions could only merge, never split). Collision groups are decided by an exact individualise-and-refine backtracking search
(`equivalent()`): returns an explicit permutation (verified: every permuted generator row lies in the other code) or
exhausts the search tree (every branch pruned by refinement mismatch or failed verification).

## Self-test (all passed)
For each of up to 20 codes per catalog (all codes if fewer): 2 random (coordinate permutation + random invertible row
transform) copies -> invariant identical; and the exact search finds a permutation to a third random copy. Also, as a positive
control of the exact search, every member of every collision group was matched to a random equivalent copy (found: yes).
Known-different codes: 38_9_16 has 47 codes with 47 distinct invariants; 35_7_16 4/4 distinct.

## Results (json: `<catalog>.2.check.json` in this dir)
| catalog | expected | count | even | projective | hull hist (all) | distinct inv. | collision groups | exact result | all_checks_pass | pairwise-inequivalence proved |
|---|---|---|---|---|---|---|---|---|---|---|
| 38_9_16 | 47 [38,9,16] | 47 | 47 | 47 | {9:47} | 47 | none | - | true | true |
| 35_7_16 | 4 [35,7,16] | 4 | 4 | 4 | {7:4} | 4 | none | - | true | true |
| 36_8_16 | 2 [36,8,16] | 2 | 2 | 2 | {8:2} | 1 | [1,2] | exhaustive search (37 nodes): inequivalent (group orders 192 vs 1152 also differ) | true | true |
| 37_9_15 | 1229 [37,9,15] | 1229 | 0 | 1229 | {8:1229} | 1228 | [767,768] | exhaustive search (3 nodes): inequivalent | true | true |

No hull mismatches, no zero columns, d exact in all codes, no discrepancies with expectations (47 / 4 / 2 / 1229; [38,9,16]
hull 9 for all; [37,9,15] single common hull dim 8). Even-code hull histogram = all-codes histogram for the three even catalogs;
empty for 37_9_15 (no even codes). Runtime: 37_9_15 0.4 s total.
Observation: the refinement invariant alone does not separate 36_8_16 #1/#2 and 37_9_15 #767/#768; the exact search does.

Scale test: synthetic 17206-code file (37_9_15 x14, 511 codewords each, --no-exact): 22.5 s wall with 3 jobs
(analysis phase 3.7 s) -> 17276 x 255 and 8170 x 127 are well inside "minutes". (Synthetic file deleted; it flagged duplicate idx as expected.)

## Pending catalogs (not yet complete at time of writing)
`qext/run_36_7_16/36_7_16.2` and `qext/run_37_8_16/37_8_16.2` exist but are 0 bytes, no `run.json` -> NOT run.
Commands (from `/home/user/math/aris4math_v2/cases/41-12`):

    python3 work/20261122-catalog/check/catalog_check.py work/20261122-catalog/qext/run_36_7_16/36_7_16.2 36 7 16 --out work/20261122-catalog/check --jobs 3
    python3 work/20261122-catalog/check/catalog_check.py work/20261122-catalog/qext/run_37_8_16/37_8_16.2 37 8 16 --out work/20261122-catalog/check --jobs 3

Compare `hull_hist_all` with published 13,53,549,71,7484 (36_7_16, 8170 codes) and 5,77,22,17172 (37_8_16, 17276 codes);
`collision_groups` / `exact_resolution` / `unresolved_pairs` in the json totals; use `--pair-timeout` (default 300 s per pair)
if large collision groups appear. Output files: `36_7_16.2.check.json`, `37_8_16.2.check.json`.

## Update: parser accepts both formats; 36_7_16 run
Parser: `HULL=h` and the trailing group-order line are optional (absent -> `hull_claimed`/`group_order` = null, hull_match = null, not a mismatch).
The four earlier catalogs were re-run: per-code records and totals identical (only new summary keys added). Even / even-projective idx lists are now written for every catalog (`<name>.even_idx.txt`, `<name>.even_projective_idx.txt`).

36_7_16 (qext/run_36_7_16, 8170 codes, LF, no HULL, no group order; 14 s with 3 jobs): count 8170, even 8096, projective 3454, even&projective 3408,
hull hist all {1:13, 3:53, 5:549, 6:71, 7:7484} (matches published), even {1:13, 3:53, 5:546, 7:7484}, min dist {16:8170}, zero-column failures none,
distinct invariants 8110, 34 collision groups (94 codes; sizes 2x22, 3x5, 4x5, 5x1, 10x1), all 122 compared pairs decided by exhaustive search: inequivalent
(0 equivalent, 0 unresolved; max 21457 nodes), positive control found a permutation for all 94 members; all_checks_pass true; non-even codes 74 (38 distinct weight distributions).
Command for 37_8_16 (not run: no run.json yet):

    python3 work/20261122-catalog/check/catalog_check.py work/20261122-catalog/qext/run_37_8_16/37_8_16.2 37 8 16 --out work/20261122-catalog/check --jobs 3

## Update 3: exact search rewritten hash-free (v2); catalogs re-checked
Old results kept as `*.check.v1.json` (38_9_16, 36_7_16, 37_8_16), old script as `catalog_check.v1.py`.
`equivalent()` now uses `exact_refine_pair()`: colours are dense integer ranks of exact signatures (own rank + per-colour incidence count vectors,
sorted distinct rows via np.unique), A/B signature multisets compared exactly each round, individualisation colour = max(coordinate colour)+1 (fresh by
construction), no hash anywhere in the search; exhaustiveness argument is in the `equivalent()` docstring. `--assert-fresh` asserts freshness at every individualisation
(all three re-runs used it; counts in json `assert_fresh_checks`: 20 / 34467 / 65). The SHA-256 invariant (hash) is only used as a sound sufficient condition for inequivalence.
Small-domain control (`small_control.py`, `small_control.json`): 60 small codes (n 5..8, k 2..4, 30 with zero columns, all with repeated columns; 30 are random equivalent copies of the others),
1770 pairs, 330 same-shape pairs compared exact search vs brute force over all n! permutations: 330/330 agree (82 equivalent, 248 inequivalent), 0 disagreements;
plus 12/12 positive controls at n=9,10.
Re-run (v2) results: 38_9_16 (no collisions), 36_7_16 (34 groups, 122 pairs all inequivalent_exhaustive, 100 s), 37_8_16 (17276 codes; 2 groups, 4 pairs all inequivalent; 3 s):
all per-code records/totals identical to v1, no decision changed, even idx lists byte-identical.
