# Reproduction package for the manuscript

Unpacked copy of `icml2026-five-cases-polish-v7-source.zip`, cited by the manuscript as the evidence location:

```
https://github.com/lisresearchgroup/math-rsi/tree/main/plugins/ecc/archive/source/paper-reproduction
```

- Manuscript sources and PDF: [`../paper/`](../paper/README.md)
- Contents: 172 systematic scan inputs and coordinate permutations, all 429,024 accepted cosets, both scanners, the pair-graph and witness-replay checkers, two pinned Lean 4.34.1 projects (no `.lake`), finite-data JSON, and validation records. See `BUILD.md` and `REPRODUCE.md` for the author-side packaging notes.
- `sections/`, `main.tex`, and `main.pdf` are the same revision as `../paper/`; edits belong in `../paper/`.
- The ~1.68 GB historical rejection streams are not distributed; per-case regeneration does not require them.

```sh
python3 scripts/check_data.py                        # Python >= 3.10
python3 scripts/check_saved_sets.py --manifest data/manifest_check.json
python3 scripts/reproduce_case.py --index 0 --run    # C++17, full 2^32 domain
python3 scripts/validate_paper.py                    # needs PyMuPDF
```
