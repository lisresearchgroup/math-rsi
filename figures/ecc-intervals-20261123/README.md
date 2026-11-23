# Shareable ECC interval figures with acceptance status

These adjacent-caption editions retain the complete original author figures as vector PDF content. A visible strip identifies the two pending rows, `[41,12]` and `[42,12]`, and distinguishes 13 accepted exact values from the source figure's 15 total, which include two pending values. The supplementary Gemini Carbon review has passed all six frozen questions under imported assumptions; the source project’s final acceptance of those two rows remains pending. The archived originals are unchanged.

The figures report 57 updates: 18 constructive lower-bound cells, 37 upper-bound updates and two further upper-bound cells pending acceptance. Comparison dates are the 2026-11-22 table snapshot and the 2026-11-23 package. These are package acceptance states, not claims of external peer review or novelty.

To regenerate, install `pypdf` and `reportlab` in a local environment, make `pdftoppm` available, and run:

```sh
python figures/ecc-intervals-20261123/add_status_caption.py --cjk-font /path/to/Chinese-capable-Unicode.ttf
```

The chosen TrueType font is embedded in the caption PDF. The PNGs are rendered from the composed PDFs at 110 dpi. The script locates inputs relative to itself; no research workspace or private path is required. Source PDFs are in `plugins/ecc/archive/intervals-57-20261123/figures/`.
