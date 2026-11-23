# Size-5 witnesses for relaxed 5-head sets (w=6, D=16, mother codes idx 1980 and 2004 of 36_7_16.2)

Files (this dir): `witness5_all.py` (generation, ~27 s), `replay_witness.py` (independent replay), `witness_1980.txt.gz`, `witness_2004.txt.gz`, `witness5_stats.json` (all statistics incl. K weight distributions, spot full weight distributions).
Run: `python3 work/20261123-witness5/witness5_all.py` and `python3 work/20261123-witness5/replay_witness.py work/20261123-assembly/r5/<idx>.gen work/20261123-witness5/witness_<idx>.txt.gz` (case dir).
Witness line: `s1 s2 s3 s4 s5 kmask weight`; kmask bit i = i-th RREF row of K (rows ordered by pivot), head rows all selected; weight = weight of the 42-bit codeword (= d5 + 6). kmask is the first (smallest) message achieving the minimum.

| | 1980 | 2004 |
|---|---|---|
| gen == catalog block (rows, same order) | yes | yes |
| pivots / free == JSON | yes / yes | yes / yes |
| pivots | 0,1,2,3,4,6,10 | 0,1,2,3,5,6,10 |
| K: even, min wt, weight dist (nonzero) | even, 16, {16:63, 20:63, 36:1} | same |
| sets = len(solution_list) = JSON c5 = solutions | 6912 | 1741824 |
| tuples strictly ascending / lexicographically strictly increasing (so distinct) | yes / yes | yes / yes |
| (a) sets violating size 1..4 thresholds (14,14,12,12) | 0 | 0 |
| sets with odd-weight subset xor (parity) | 0 | 0 |
| d5 histogram | {6: 6912} | {6: 1741824} |
| max d5; sets with d5>=10; sets with d5<10 | 6; 0; 6912 | 6; 0; 1741824 |
| explicit 42-bit codeword weight (all sets) | {12: 6912}, all nonzero, all == d5+6, all < 16 | {12: 1741824}, same |
| replay (independent script) | 6912 verified, 0 failed, hist {12: 6912}, 0.17 s | 1741824 verified, 0 failed, hist {12: 1741824}, 59 s |
| witness file sha256 | b1bb9cce86f07b04940362ed75dd216b2ae473d40135a679221f06302806c858 | 478ccc8a36cb954b50d3a15d929367cc83c43ead309bd8c5e010a2f72d30429a |
| generation time | 0.22 s | 26.2 s |

Aggregated depth histograms over the 31 subsets of every set (all sets of a code identical in pattern):
- size 1: all depth 14; size 2 (pairs): all depth 14, none 16 (0 of 10 pairs of any set have depth 16); size 3: all 12; size 4: all 12; size 5: all 6.
- Counts: 1980 -> 34560 / 69120 / 69120 / 34560 / 6912 subsets of size 1/2/3/4/5; 2004 -> 8709120 / 17418240 / 17418240 / 8709120 / 1741824.

Other facts:
- No genuine solution (no set with d5 >= 10); the STOP branch was not triggered.
- Spot check (first, middle, last set of each code): full weight distribution of the 12x42 code over all 4095 nonzero codewords is identical for the six sets: {12:1, 16:756, 20:1728, 24:1440, 28:165, 32:3, 36:2}; minimum 12 = d5+6.
- Every d5 equals 6 (a weight-6 coset-min vector), so every witness codeword has weight 12 in the 42-length code; no set has any other d5.
- Method: depth_T computed by brute force over the 128 K codewords with numpy (uint64, bitwise_count), x_s built directly from the free coordinates; no code from o6/o7/planted used.
