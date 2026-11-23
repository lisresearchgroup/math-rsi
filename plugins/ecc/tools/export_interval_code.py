#!/usr/bin/env python3
"""Export an explicit binary code attaining an archived constructive lower bound."""
from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path

DEFAULT_ARCHIVE = Path(__file__).resolve().parents[1] / 'archive' / 'intervals-57-20261123'
# Each operation consumes a direct accepted hit, so no search or recursive closure is needed.
DERIVED = {
    (73, 43): ((72, 43), 'parity'),
    (75, 44): ((74, 44), 'parity'),
    (76, 37): ((75, 37), 'parity'),
    (77, 46): ((78, 46), 'puncture-last'),
    (82, 43): ((81, 43), 'parity'),
}


def rank(rows: list[str]) -> int:
    pivots: dict[int, int] = {}
    for row in rows:
        value = int(row, 2)
        while value:
            pivot = value.bit_length() - 1
            if pivot in pivots:
                value ^= pivots[pivot]
            else:
                pivots[pivot] = value
                break
    return len(pivots)


def export(archive: Path, cell: tuple[int, int], output: Path) -> dict:
    with (archive / 'cells.csv').open(newline='') as stream:
        bounds = {(int(r['n']), int(r['k'])): r for r in csv.DictReader(stream) if r['group'] == '4'}
    if cell not in bounds:
        raise ValueError('cell must be one of the 18 constructive cells in cells.csv')
    source_cell, operation = DERIVED.get(cell, (cell, 'direct'))
    index = json.loads((archive / '4-scan-lower-bounds/hits/INDEX.json').read_text())
    entry = next(r for r in index['cells'] if tuple(r['cell']) == source_cell)
    accepted = [s for s in entry['sources'] if s['status'] == 'verified']
    source = sorted(accepted, key=lambda s: (-s['new_d'], s['dir']))[0]
    source_dir = Path('4-scan-lower-bounds') / source['dir']
    rows = (archive / source_dir / 'G.txt').read_text().split()
    source_n, source_k = source_cell
    if (len(rows) != source_k or any(len(r) != source_n or set(r) - {'0', '1'} for r in rows)
            or rank(rows) != source_k):
        raise ValueError('source generator shape or rank is invalid')
    distance = int(source['new_d'])
    # Source acceptance includes two saved exhaustive checks; exporting does not rerun them.
    for name in ('verify_A.json', 'verify_B.json'):
        record = json.loads((archive / source_dir / name).read_text())
        if (record['d_ge_D'] is not True or record['D'] != distance
                or (record['n'], record['k']) != source_cell):
            raise ValueError(f'source acceptance record is inconsistent: {name}')
    if operation == 'parity':
        rows = [r + str(r.count('1') % 2) for r in rows]
        distance += distance % 2
    elif operation == 'puncture-last':
        if distance < 2:
            raise ValueError('puncturing requires distance at least two to preserve dimension')
        rows = [r[:-1] for r in rows]
        distance -= 1
    n, k = cell
    guarantee = int(bounds[cell]['new_lb'])
    if (distance < guarantee or len(rows) != k or any(len(r) != n for r in rows)
            or rank(rows) != k):
        raise ValueError('export does not attain the displayed bound with the required rank')
    provenance = {
        'cell': [n, k], 'guaranteed_distance_at_least': guarantee,
        'optimal_distance_claimed': False,
        'kind': 'direct' if operation == 'direct' else 'derived',
        'operation': operation, 'source_cell': list(source_cell),
        'source_generator': (source_dir / 'G.txt').as_posix(),
        'source_guaranteed_distance_at_least': int(source['new_d']),
        'rank_checked': k,
        'verification': 'Shape and rank checked during export; source distance uses archived exhaustive A/B acceptance records; derived distance follows the stated standard operation.',
    }
    output.mkdir(parents=True, exist_ok=True)
    (output / 'G.txt').write_text('\n'.join(rows) + '\n')
    (output / 'provenance.json').write_text(json.dumps(provenance, indent=2) + '\n')
    return provenance


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cell', type=int, nargs=2, required=True, metavar=('N', 'K'))
    parser.add_argument('--archive', type=Path, default=DEFAULT_ARCHIVE,
                        help='input archive directory (default: bundled intervals-57-20261123)')
    parser.add_argument('--output-dir', type=Path, required=True,
                        help='write G.txt and provenance.json here (replaces those files if present)')
    args = parser.parse_args()
    try:
        result = export(args.archive, tuple(args.cell), args.output_dir)
    except (ValueError, OSError, KeyError, StopIteration) as error:
        parser.exit(2, f'export failed: {error}\n')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
