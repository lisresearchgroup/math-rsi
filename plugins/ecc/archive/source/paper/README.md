# Nonexistence Results for Five Binary Linear Code Parameters

Manuscript revision of 2026-11-18. Body 7 pages, 18 pages total; official ICML 2026 style with the `preprint` option. PDF subject is set to `Preprint`.

`main.tex` with `sections/` and `references.bib` builds the current draft; `main.pdf` is the built copy. The site publishes this file as `readers/ecc/main.pdf` per [`site/public-files.json`](../../../../../site/public-files.json).

Evidence and reproducibility materials are in [`../paper-reproduction/`](../paper-reproduction/README-REPO.md); the manuscript cites them by relative path (`scripts/reproduce_case.py`, `formal/ecc43`, `formal/ecc42`, `provenance/ai-interventions.md`) with the base URL in Appendix A.

```sh
tectonic --keep-logs main.tex     # or latexmk -pdf main.tex
python3 ../paper-reproduction/scripts/check_data.py       # Python >= 3.10
python3 ../paper-reproduction/scripts/validate_paper.py   # needs PyMuPDF
```
