# Explicit [42,12,15] code: construction and verification (SeedE14, work/20261123-lb42)

**Result: both implementations report rank 12 and exact minimum distance 15 (not 16 or more), with identical weight spectra.** No discrepancy.

## Provenance
See `PROVENANCE.md`. One Magma calculator request (HTTP 200, 2026-11-22T19:06:45Z), raw XML in `magma_reply1.xml`, exact input in `input.txt`:
```
SetColumns(0);
C := BKLC(GF(2),42,12);
C;
MinimumDistance(C);
GeneratorMatrix(C);
```
Magma reply header: `[42, 12, 15] Linear Code over GF(2)`; `MinimumDistance(C)` printed 15.

## Matrix (12x42, leftmost char = coordinate 1)
```
100000000000001001100110010001110101101001
010000000000100000000000111111110010101011
001000000000111001010101111001000100100011
000100000000111000011001001011001010001110
000010000000010101101010110100010000101110
000001000000001010110101011010101000010111
000000100000100101101001011010011100010100
000000010000010010110100101101101110001010
000000001000001101011010010110010111000101
000000000100100110011110111100000011111101
000000000010111110011010111000011100001000
000000000001010010101011001101111011101101
```
Canonical SHA-256 (verifier): `f1f0ce5948db3f6460f7c709a0b1aae160c9b1f8bc7ced743ca7694024d1b7fe`

## Commands
```
cd cases/41-12/work/20261123-lb42
python3 run_verify_code.py   # -> verify_code_output.json, verify_stdout.txt
python3 independent_check.py # -> independent_check.json, independent_stdout.txt
```
`verify_code(ExpandedCode(rows,n=42,k=12), target_distance=15, exact_dimension_limit=22, field=2, exact_after_probe_counterexample=True, collect_weight_distribution=True)`; row integer bit j = coordinate j+1.

## Side by side
| item | verify_code | independent (reads generator_12x42.txt only, no harness) |
|---|---|---|
| n | 42 | 42 |
| field | 2 | 2 |
| declared k | 12 | 12 |
| rank | 12 | 12 |
| status / proof_level | verified / exact | full enumeration |
| min distance | 15 | 15 |
| messages enumerated | 4095 | 4095 (distinct nonzero codewords 4095) |
| spectrum total | 4095 | 4095 |
| even code | n/a | False |
| witness | message int 1 (rows [1]), weight 15, 0-based support [0, 14, 17, 18, 21, 22, 25, 29, 30, 31, 33, 35, 36, 38, 41] | rows [1], codeword `100000000000001001100110010001110101101001`, 1-based support [1, 15, 18, 19, 22, 23, 26, 30, 31, 32, 34, 36, 37, 39, 42] |

Weight spectrum (nonzero):
- verify_code `report.weight_distribution`: 15:219, 16:360, 19:772, 20:912, 23:882, 24:676, 27:164, 28:96, 31:11, 32:3
- independent: 15:219, 16:360, 19:772, 20:912, 23:882, 24:676, 27:164, 28:96, 31:11, 32:3
- Identical: True (checked programmatically). Weights present: 15,16,19,20,23,24,27,28,31,32 (code is not even; min weight is 15, no weight below 15 or equal to 17/18 etc.).

verify_code message: "exact minimum distance 15 verifies target 15". Independent flag target_constructed_d15=True.
Both found the same witness (message = row 1, weight 15).
