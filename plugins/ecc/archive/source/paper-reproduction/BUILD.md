# Build and finite checks

This directory uses the unmodified official ICML 2026 style, downloaded from https://media.icml.cc/Conferences/ICML2026/Styles/icml2026.zip on 2026-11-03. The preprint layout is 10pt Times, with two columns in the main text; the author list appears on the title page. T1 encoding is explicit for compatibility with Tectonic/XeTeX. The template's preprint option prints a preprint notice rather than asserting conference review.

From this directory:

```sh
latexmk -pdf -interaction=nonstopmode -halt-on-error main.tex
# Alternative, used for this draft:
tectonic --keep-logs --keep-intermediates main.tex
python3 scripts/check_data.py
```

Python >=3.10 is needed for integer bit_count. The data checker does not require third-party packages and does not repeat the exhaustive coset searches or pair stream replay. Fresh local logs are in validation/; historical summaries are labeled as such.

The portable source zip contains LaTeX, the official style files, literal generators, all172 normalized scan inputs and accepted lists, both original scanners, pair checkers, portable Python drivers, pinned Lean sources, and a verification summary. See REPRODUCE.md for complete per-case regeneration. The full 1.68 GB rejection streams remain in the local evidence tree. Their exact locations and advanced reproduction commands are intentionally in the separate LOCAL_EVIDENCE_MAP.md, not in anonymous manuscript text.

The PDF is a writing draft in ICML format. External theorem imports and computational assumptions remain explicit. Using the format does not assert that the work has been submitted to or accepted by ICML.
