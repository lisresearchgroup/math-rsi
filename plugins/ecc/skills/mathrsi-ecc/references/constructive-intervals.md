# Export the 18 constructive interval witnesses

The bundled `archive/intervals-57-20261123/cells.csv` has 18 improved lower-bound cells in group 4. Fifteen cells have accepted direct hits; five displayed values are derived, with two of those cells also having weaker direct hits. The exporter chooses an accepted direct generator or deterministically constructs the stronger displayed witness.

From the repository root:

```sh
python3 plugins/ecc/tools/export_interval_code.py --cell 73 43 --output-dir /tmp/ecc-73-43
```

The input archive defaults relative to the script, so the command also works from another directory when given the script's path. `--archive PATH` selects a different copy with the same layout. `--output-dir PATH` writes `G.txt` and `provenance.json`, replacing those two files if present. The generator has exactly K binary rows of length N; the leftmost character is coordinate zero. Provenance records its source, operation, rank and guaranteed distance. A guaranteed distance is a lower bound, not a claim about the optimum distance of all codes with those parameters.

Derived exports append the row parity for `[73,43,12]`, `[75,44,12]`, `[76,37,16]` and `[82,43,14]`. For `[77,46,11]`, the exporter deletes the final coordinate of the accepted `[78,46,12]` generator. These linear operations preserve dimension here: parity extension always does; puncturing does because the source has no weight-one codeword. An odd source distance d gains one under parity extension; puncturing loses at most one.

The exporter checks every output's shape and rank. Distance guarantees consume archived complete A/B verification records and these mathematical transformations; export does not repeat the expensive distance scans. The original five derived values had no separately supplied matrices; this tool constructs them on demand.

A small direct example is the [72,43] generator at [G.txt](../../../archive/intervals-57-20261123/4-scan-lower-bounds/hits/72-43/71-42-L/G.txt). Its distance is at least 11. Export it with `--cell 72 43`; use `--cell 73 43` for its parity extension, attaining distance at least 12. These improve the archived table intervals from `[10,14]` to `[11,14]` and `[12,14]`, respectively. Neither interval closes, and archived comparisons do not establish present-day novelty.
