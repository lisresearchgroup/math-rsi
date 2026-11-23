#!/usr/bin/env python3
"""Build the one-step extension scan list from the bounds tables.

Base code B = table code [n0,k0,d0], redundancy rho = n0-k0 (12..RHO_MAX).
  A-target (augment):  cell [n0,k0+1]   with lb = L.  If d0 >= L+1 and some coset of B has
                       minimum weight >= L+1, then B + <x> is an [n0,k0+1,>=L+1] code.
  L-target (lengthen): cell [n0+1,k0+1] with lb = L.  If d0 >= L+1 and some coset x+B has
                       minimum weight >= L, then {(c,0)} u {(x+c,1)} is an [n0+1,k0+1,>=L+1] code.
A target is listed only while it is open under the tightest upper bound available here:
codetables, the Bayreuth table, and derived-upper-bounds-20261122.json.
`need` is the smallest coset depth that gives a hit for this base; the run may stop at
max(need of its targets) or as soon as the bitmap is full.
Cost model: measured 1594 s, 33.6 GiB peak for rho=37, n=72, 16 steps, single thread
(regression/layers_S_r37.json), i.e. 1.38 s per column per step at rho=37, scaling with 2^rho.
"""
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
RHO_MIN, RHO_MAX = 12, 40


def load(name):
    return {tuple(map(int, k.split(','))): v for k, v in json.loads((HERE / name).read_text()).items()}


def main():
    table = load('codetables-binary-20261122.json')
    lb = {c: v[0] for c, v in table.items()}
    ub = {c: v[1] for c, v in table.items()}
    for c, v in load('bayreuth-q2-20261122.json').items():
        ub[c] = min(ub[c], int(v[0].split('-')[-1]))
    for row in json.loads((HERE / 'derived-upper-bounds-20261122.json').read_text()):
        c = tuple(row['cell'])
        ub[c] = min(ub[c], row['new_ub'])

    jobs = []
    for (n0, k0), d0 in sorted(lb.items()):
        rho = n0 - k0
        if k0 < 2 or not RHO_MIN <= rho <= RHO_MAX:
            continue
        targets = []
        a, l = (n0, k0 + 1), (n0 + 1, k0 + 1)
        if a in lb and lb[a] < ub[a] and d0 >= lb[a] + 1:
            targets.append({'type': 'A', 'cell': list(a), 'new_d': lb[a] + 1, 'depth': lb[a] + 1,
                            'closes': ub[a] == lb[a] + 1})
        if l in lb and lb[l] < ub[l] and d0 >= lb[l] + 1:
            targets.append({'type': 'L', 'cell': list(l), 'new_d': lb[l] + 1, 'depth': lb[l],
                            'closes': ub[l] == lb[l] + 1})
        if not targets:
            continue
        need = min(t['depth'] for t in targets)
        steps = max(t['depth'] for t in targets)
        jobs.append({'base': [n0, k0], 'd0': d0, 'rho': rho, 'need': need, 'max_depth': steps,
                     'targets': targets, 'mem_gib': round(2 * 2 ** (rho - 33), 3),
                     'est_cpu_h': round(1.38 * 2 ** (rho - 37) * n0 * steps / 3600, 3)})
    (HERE / 'jobs.json').write_text(json.dumps(jobs, indent=0))

    print('bases', len(jobs), 'targets', len({tuple(t['cell']) for j in jobs for t in j['targets']}),
          'closing', len({tuple(t['cell']) for j in jobs for t in j['targets'] if t['closes']}))
    for lo, hi in [(12, 33), (34, 37), (38, 38), (39, 39), (40, 40)]:
        sel = [j for j in jobs if lo <= j['rho'] <= hi]
        print(f'rho {lo}-{hi}: bases {len(sel)}, mem/run <= {2 * 2 ** (hi - 33):g} GiB, '
              f'cpu-h {sum(j["est_cpu_h"] for j in sel):.0f}, longest {max(j["est_cpu_h"] for j in sel):.1f} h')
    print('total cpu-h', round(sum(j['est_cpu_h'] for j in jobs)))


if __name__ == '__main__':
    main()
