# Seed [41,12,14] rebuild and verification (SeedE14, 2026-11-22)

Directory: `work/20261122-seed-e14/` (case 41-12). Nothing outside it was written.

## Files
- `construct.py` (+ `construct_output.txt`): builds the matrix; checks g | x^43-1 (remainder 0, deg g = 28).
- `generator_12x41.txt`, `convention.txt`: explicit matrix + convention (leftmost char = coordinate 1 = coeff of x^0; parity = coordinate 44; shortened at 1-based {42,43,44}). The 12-row basis is the output of Gaussian elimination on the three deleted coordinates, not systematic.
- `run_verify_code.py` -> `verify_code_output.json` (to_dict() plus `weight_distribution_explicit`, `weight_distribution_total`).
- `independent_check.py` (no harness import, reads only the matrix text) -> `independent_check.json`.

## Commands
```
cd cases/41-12/work/20261122-seed-e14
python3 construct.py
python3 run_verify_code.py
python3 independent_check.py
```
`verify_code(ExpandedCode(rows,n=41,k=12), target_distance=14, exact_dimension_limit=22, field=2, exact_after_probe_counterexample=True, collect_weight_distribution=True)`; row integer bit j = coordinate j+1. (`exact_dimension_limit=22`, the default, is >= 12.)

## Matrix (12x41)
```
10011101001101111011001011100100000000000
11010011101011000110101110010110000000000
11110100111000011000011100101111000000000
11100111010001110111000101110011100000000
11101110100101000000101001011101110000000
11101010011111011011011111001010111000000
11101000000010010110100100000001011100000
11101001001100110000011001100100101110000
11101001101011100011000111010110010111000
11101001111000001010101000001111001011100
11101001110001111110011111100011100101110
11101001110101000100000100010101110010111
```
SHA-256 (canonical, verifier): `5f20badc71af52ceb3685bb01818b6cd9f7ff1e66892d33233a45bc5c7da7793`

## Results side by side
| item | verify_code | independent |
|---|---|---|
| n | 41 | 41 |
| field | 2 | 2 |
| declared k | 12 | 12 |
| rank | 12 | 12 |
| status / proof_level | verified / exact | n/a (full enumeration of 4095 nonzero messages) |
| min distance | 14 | 14 |
| messages enumerated | exact_witness.examined = 4095 | 4095 (distinct nonzero codewords 4095) |
| even code | (not reported) | True |
| spectrum total | 4095 | 4095 |
| witness | message int 13 (rows 1-based [1, 3, 4]), weight 14, support (0-based) [0, 4, 5, 6, 8, 11, 15, 17, 21, 24, 26, 27, 28, 32] | message rows [1, 2, 4], codeword `10101001110111001010100000000001100000000`, support (1-based) [1, 3, 5, 8, 9, 10, 12, 13, 14, 17, 19, 21, 32, 33] |

Spectrum (weight:count)
- verify_code `report.weight_distribution`: 14:160, 16:456, 18:699, 20:943, 22:931, 24:611, 26:233, 28:37, 30:25
- independent: 14:160, 16:456, 18:699, 20:943, 22:931, 24:611, 26:233, 28:37, 30:25
- spec's expected spectrum {14:160,16:456,18:699,20:943,22:931,24:611,26:233,28:37,30:25}

verify_code message: "exact minimum distance 14 verifies target 14". Independent flags: matches_expected_spectrum=True, target_constructed_d14=True.

Note: the two implementations report different (both valid, weight-14) minimum-weight witnesses: verify_code's Gray-code enumeration found message 13 (rows 1,3,4), while the independent script keeps the first minimum in ascending message order (rows 1,2,4). This is a tie-breaking difference, not a discrepancy in distance or spectrum.

## Statement
Both implementations report rank 12 and exact minimum distance 14, with identical weight spectra (identical to the spec's expected spectrum, total 4095, all weights even). No discrepancy found. Raw outputs: `verify_code_output.json`, `independent_check.json`, `construct_output.txt`.
