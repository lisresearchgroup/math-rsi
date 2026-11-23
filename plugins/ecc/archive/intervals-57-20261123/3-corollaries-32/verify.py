#!/usr/bin/env python3
"""Replay trace.json against the codetables snapshot shipped in inputs/.

Standalone: uses only the Python standard library and the files of this package.
The premise values recorded in the trace are not trusted; every step is re-checked
against this script's own running table U (U[n,k] = current upper bound for [n,k]).

Rule conditions (to = new bound, d = to+1 for the exact-distance rules):
  theorem   cell and excluded distance must be one of THEOREMS; needs U(cell) == excluded distance
  puncture  needs k <= n-1 and U(n-1,k) <= to-1
  shorten   needs k >= 2 and U(n-1,k-1) <= to
  subcode   needs k >= 2 and U(n,k-1) <= to
  parity    needs U(n,k) == d, d odd, U(n+1,k) <= d
  residual  needs U(n,k) == d, k >= 2, n-d >= k-1, U(n-d,k-1) < ceil(d/2)
  Y1        needs U(n,k) == d, k < n, W := U(n,n-k) with 1 <= W <= k,
            and U(n-w,k-w+1) < d for every w = 1..W
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
THEOREMS = {'T1': ((41, 14), 14), 'T2': ((47, 10), 20), 'T3': ((85, 9), 40)}


def main():
    snap = json.loads((HERE / 'inputs' / 'codetables-binary-20261122.json').read_text())
    U = {tuple(map(int, key.split(','))): value[1] for key, value in snap.items()}
    LB = {tuple(map(int, key.split(','))): value[0] for key, value in snap.items()}
    steps = json.loads((HERE / 'trace.json').read_text())['steps']
    bad = 0
    for s in steps:
        n, k = s['cell']
        to, rule, cur = s['to'], s['rule'], U[(n, k)]
        ok = to < cur
        if rule == 'theorem':
            ok = ok and THEOREMS.get(s.get('theorem')) == ((n, k), cur) and to == cur - 1
        elif rule == 'puncture':
            ok = ok and k <= n - 1 and U[(n - 1, k)] <= to - 1
        elif rule == 'shorten':
            ok = ok and k >= 2 and U[(n - 1, k - 1)] <= to
        elif rule == 'subcode':
            ok = ok and k >= 2 and U[(n, k - 1)] <= to
        else:
            d = to + 1
            ok = ok and cur == d
            if rule == 'parity':
                ok = ok and d % 2 == 1 and U[(n + 1, k)] <= d
            elif rule == 'residual':
                ok = ok and k >= 2 and n - d >= k - 1 and U[(n - d, k - 1)] < -(-d // 2)
            elif rule == 'Y1':
                ok = ok and k < n and 1 <= U[(n, n - k)] <= k
                ok = ok and all(U[(n - w, k - w + 1)] < d for w in range(1, U[(n, n - k)] + 1))
            else:
                ok = False
        if not ok:
            bad += 1
            print('BAD', s['id'], s['cell'], rule)
        U[(n, k)] = to

    cells = json.loads((HERE / 'cells.json').read_text())
    wrong = [r['cell'] for r in cells
             if U[tuple(r['cell'])] != r['new_ub'] or r['new_ub'] < LB[tuple(r['cell'])]
             or r['new_ub'] >= r['codetables'][1] or r['codetables'] != snap[f"{r['cell'][0]},{r['cell'][1]}"]]
    print(f'steps {len(steps)}, bad {bad}; cells {len(cells)}, mismatched {wrong}')
    print('OK' if not bad and not wrong and len(cells) == 32 else 'FAILED')
    sys.exit(0 if not bad and not wrong and len(cells) == 32 else 1)


if __name__ == '__main__':
    main()
