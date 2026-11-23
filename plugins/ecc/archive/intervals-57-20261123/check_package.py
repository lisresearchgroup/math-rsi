#!/usr/bin/env python3
"""Check the MathRSI 57-interval trace package.  Standard library only; run inside this directory of the repository.

What is recomputed here
  - cells.csv: 57 rows, group counts 4/1/32/18/2, table intervals equal the codetables snapshot
  - group 1: the three corollaries follow from [43,10] <= 16 by puncturing / shortening;
             the lower-bound matrices in ../source/data are enumerated in full
  - group 2: [42,16] <= 12 is step of the corollary trace; the [42,16,12] matrix is enumerated in full
  - group 3: cells equal 3-corollaries-32/cells.json; 3-corollaries-32/verify.py is run
  - group 4: cells equal the closure of the verified hits in hits/INDEX.json; every hit matrix has
             the stated shape and full rank; the saved verification records say "true"
  - group 5: arithmetic of the two cells; the [41,12,14] and [42,12,15] matrices are enumerated in full
  - SHA256SUMS
What is NOT recomputed: the nonexistence computations of groups 1 and 5, and the exhaustive
distance verification of the hit matrices of group 4 (their saved records are only read).
"""
import csv
import hashlib
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FAIL = []


def check(ok, what):
    print(('ok   ' if ok else 'FAIL ') + what)
    if not ok:
        FAIL.append(what)


def span_min_weight(rows):
    """minimum weight and count of nonzero words of the span of integer rows (full enumeration)"""
    words = [0]
    for r in rows:
        words += [w ^ r for w in words]
    assert len(set(words)) == len(words), 'rows are dependent'
    best = min(bin(w).count('1') for w in words[1:])
    return best, len(words) - 1


def rank(rows):
    rows, r = list(rows), 0
    while rows:
        p = rows.pop()
        if p:
            r += 1
            low = p & -p
            rows = [x ^ p if x & low else x for x in rows]
    return r


def bits(path):
    return [int(line.strip()[::-1], 2) for line in path.read_text().split() if line.strip()], \
        len(path.read_text().split()[0])


def main():
    table = {tuple(map(int, k.split(','))): v for k, v in json.loads(
        (ROOT / '3-corollaries-32/inputs/codetables-binary-20261122.json').read_text()).items()}
    rows = list(csv.DictReader((ROOT / 'cells.csv').open()))
    cells = {(int(r['n']), int(r['k'])): r for r in rows}
    groups = {g: [c for c, r in cells.items() if r['group'] == str(g)] for g in range(1, 6)}
    check(len(rows) == len(cells) == 57, '57 distinct cells')
    check([len(groups[g]) for g in range(1, 6)] == [4, 1, 32, 18, 2], 'group sizes 4/1/32/18/2')
    check(all([int(r['codetables_lb']), int(r['codetables_ub'])] == table[c] for c, r in cells.items()),
          'table intervals equal the codetables snapshot')
    check(all(int(r['codetables_lb']) <= int(r['new_lb']) <= int(r['new_ub']) <= int(r['codetables_ub'])
              and (int(r['new_lb']), int(r['new_ub'])) != tuple(table[c]) for c, r in cells.items()),
          'every cell is a strict improvement inside the table interval')
    check(sum(r['new_lb'] == r['new_ub'] for r in rows) == 15, '15 cells are exact values')
    check(all((r['side'] == 'lower') == (r['group'] == '4') for r in rows), 'only group 4 changes lower bounds')
    U = lambda c: int(cells[c]['new_ub'])

    # group 1
    check(U((43, 10)) == 16 and U((44, 10)) == U((43, 10)) + 1 and U((44, 11)) == U((43, 10))
          and U((45, 11)) == U((44, 11)) + 1, 'group 1: corollaries of [43,10] <= 16 (puncture, shorten, puncture)')
    low = json.loads((ROOT.parent / 'source/data/lower-generators.json').read_text())['codes']
    for code in low:
        d, count = span_min_weight(code['rows'])
        cell = (code['n'], code['k'])
        check(d == code['distance'] and count == 2 ** code['k'] - 1 and d >= table[cell][0]
              and max(code['rows']).bit_length() <= code['n'],
              f"group 1: lower-bound matrix [{code['n']},{code['k']},{d}] enumerated ({count} words)")

    # group 2
    trace = json.loads((ROOT / '3-corollaries-32/trace.json').read_text())['steps']
    check(any(s['cell'] == [42, 16] and s['to'] == 12 for s in trace) and U((42, 16)) == 12,
          'group 2: [42,16] <= 12 is a step of the corollary trace (source theorem T1)')
    seed = json.loads((ROOT / '2-reduction-42-16/candidates/qr-seed-verified.json').read_text())
    d, count = span_min_weight(seed['matrix']['rows_int'])
    check(d == 12 and count == 65535 and max(seed['matrix']['rows_int']).bit_length() <= 42,
          'group 2: [42,16,12] matrix enumerated (65535 words)')

    # group 3
    cor = {tuple(r['cell']): r for r in json.loads((ROOT / '3-corollaries-32/cells.json').read_text())}
    check(set(cor) == set(groups[3]) and all(U(c) == cor[c]['new_ub'] for c in cor),
          'group 3: cells equal 3-corollaries-32/cells.json')
    run = subprocess.run([sys.executable, 'verify.py'], cwd=ROOT / '3-corollaries-32', capture_output=True, text=True)
    check(run.returncode == 0 and run.stdout.strip().endswith('OK'), 'group 3: 3-corollaries-32/verify.py replays 37 steps')

    # group 4
    index = json.loads((ROOT / '4-scan-lower-bounds/hits/INDEX.json').read_text())
    lb = {c: v[0] for c, v in table.items()}
    hits, sources = {}, 0
    for row in index['cells']:
        good = [s for s in row['sources'] if s['status'] == 'verified']
        hits[tuple(row['cell'])] = max(s['new_d'] for s in good)
        for s in good:
            d = ROOT / '4-scan-lower-bounds' / s['dir']
            n, k = row['cell']
            mat, width = bits(d / 'G.txt')
            a = json.loads((d / 'verify_A.json').read_text())
            b = json.loads((d / 'verify_B.json').read_text())
            ok = (len(mat) == k and width == n and rank(mat) == k
                  and all(x['d_ge_D'] is True and x['D'] == s['new_d'] and [x['n'], x['k']] == [n, k] for x in (a, b))
                  and json.loads((d / 'STATUS.json').read_text())['status'] == 'verified')
            sources += 1
            if not ok:
                check(False, f'group 4: hit {s["dir"]}')
    check(sources == sum(len([s for s in r['sources'] if s['status'] == 'verified']) for r in index['cells']) and sources > 0,
          f'group 4: {sources} hit matrices have the stated shape and full rank; saved verification records are true')
    lb.update(hits)
    changed = True
    while changed:
        changed = False
        for (n, k), d in list(lb.items()):
            for cell, value in (((n - 1, k - 1), d if k >= 2 else 0), ((n - 1, k), d - 1), ((n, k - 1), d),
                                ((n + 1, k), d + d % 2)):
                if cell in lb and lb[cell] < value:
                    lb[cell], changed = value, True
    improved = {c: d for c, d in lb.items() if d > table[c][0]}
    check(set(improved) == set(groups[4]) and all(int(cells[c]['new_lb']) == d for c, d in improved.items()),
          'group 4: 18 cells equal the closure of the verified hits (shorten, puncture, subcode, parity)')
    check(all((cells[c]['derived'] == '1') == (hits.get(c) != d) for c, d in improved.items()),
          'group 4: the derived flag marks exactly the values not attained by a hit matrix')

    # group 5
    check(U((41, 12)) == 14 == table[(41, 12)][1] - 1 and U((42, 12)) == U((41, 12)) + 1,
          'group 5: [41,12] <= 14 and its puncturing corollary [42,12] <= 15')
    for rel, n, dist in (('work/20261122-seed-e14/generator_12x41.txt', 41, 14),
                         ('work/20261123-lb42/generator_12x42.txt', 42, 15)):
        mat, width = bits(ROOT / '5-theorem-41-12' / rel)
        d, count = span_min_weight(mat)
        check(width == n and len(mat) == 12 and d == dist and count == 4095,
              f'group 5: lower-bound matrix [{n},12,{dist}] enumerated (4095 words)')

    # hashes
    bad = 0
    lines = (ROOT / 'SHA256SUMS').read_text().splitlines()
    for line in lines:
        digest, rel = line.split('  ', 1)
        if hashlib.sha256((ROOT / rel).read_bytes()).hexdigest() != digest:
            bad += 1
    listed = {line.split('  ', 1)[1] for line in lines}
    present = {str(p.relative_to(ROOT)) for p in ROOT.rglob('*') if p.is_file()} - {'SHA256SUMS'}
    present = {p for p in present if '__pycache__' not in p}
    check(bad == 0 and listed == present, f'SHA256SUMS: {len(lines)} files, {bad} mismatches')

    print('\nRESULT:', 'FAILED' if FAIL else 'OK')
    sys.exit(1 if FAIL else 0)


if __name__ == '__main__':
    main()
