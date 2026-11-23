# Nonexistence Results for Five Binary Linear Code Parameters

Manuscript revision of 2026-11-18. Body 7 pages, 18 pages total; official ICML 2026 style with the `preprint` option. PDF subject is set to `Preprint`.

`main.tex` with `sections/` and `references.bib` builds the current draft; `main.pdf` is the built copy. The site publishes this file as `readers/ecc/main.pdf` per [`site/public-files.json`](../../../../../site/public-files.json).

Evidence and reproducibility materials are in [`../paper-reproduction/`](../paper-reproduction/README-REPO.md); the manuscript cites them by relative path (`scripts/reproduce_case.py`, `formal/ecc43`, `formal/ecc42`, `provenance/ai-interventions.md`) with the base URL in Appendix A.

Run from this `paper/` directory. Compile a temporary copy so neither the shipped PDF nor historical validation records are overwritten. The validator needs both the log and auxiliary file; Tectonic users must retain both with the two options below. Python >= 3.10 and PyMuPDF (`python3 -m pip install pymupdf`) are required for validation.

```sh
paper_build=$(mktemp -d "${TMPDIR:-/tmp}/ecc-paper.XXXXXX")
cp -R . "$paper_build/"
(cd "$paper_build" && latexmk -pdf -interaction=nonstopmode -halt-on-error main.tex)
# Alternatively: (cd "$paper_build" && tectonic --keep-logs --keep-intermediates main.tex)
python3 ../paper-reproduction/scripts/check_data.py
python3 ../paper-reproduction/scripts/validate_paper.py \
  --paper-dir "$paper_build" --output-dir "$paper_build/validation-current"
```

Reports are `pdf-check.json` and `pdf-text.txt` in the specified output directory. Without options, the validator retains its historical behavior: it reads the sibling `paper-reproduction/` tree and writes that tree's `validation/` directory. Use explicit paths when validating this manuscript copy.
