#!/usr/bin/env python3
"""Build the self-contained package for the 32 corollary upper bounds.

Baseline: codetables snapshot only.  Seeds: three published nonexistence theorems.
No Bayreuth entry and no local theorem is used.  Output directory: corollaries-32-20261122/
"""
import csv
import json
import shutil
import tarfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
PKG = HERE / 'corollaries-32-20261122'
SNAP = HERE.parent / 'binary-bounds-full-20261122.json'

THEOREMS = [
    {'id': 'T1', 'cell': [41, 14], 'excluded_d': 14,
     'ref': 'S. Bouyuklieva, I. Bouyukliev, Classification of Linear Codes by Extending Their Residuals, '
            'Mathematical Software – ICMS 2020, LNCS 12097, pp. 173–180, DOI 10.1007/978-3-030-52200-1_17',
     'where': 'Proposition 2', 'quote': 'Binary linear [41,14,14] codes do not exist.'},
    {'id': 'T2', 'cell': [47, 10], 'excluded_d': 20,
     'ref': 'S. Kurz, The [46,9,20]_2 code is unique, Advances in Mathematics of Communications 15(3) (2021) '
            '415–422, DOI 10.3934/amc.2020074, arXiv:1906.02621v2',
     'where': 'Lemma 3.4', 'quote': 'No [47,10,20]_2 code exists.'},
    {'id': 'T3', 'cell': [85, 9], 'excluded_d': 40,
     'ref': 'S. Kurz, The [46,9,20]_2 code is unique, Advances in Mathematics of Communications 15(3) (2021) '
            '415–422, DOI 10.3934/amc.2020074, arXiv:1906.02621v2',
     'where': 'Theorem 3.7', 'quote': 'No [85,9,40]_2 code exists.'},
]
OWN_OR_ANNOUNCED = {(43, 10), (44, 10), (44, 11), (45, 11), (42, 16)}


def fmt(c):
    return f'[{c[0]},{c[1]}]'


def derive():
    table = {tuple(map(int, k.split(','))): v for k, v in json.loads(SNAP.read_text()).items()}
    nmax = max(n for n, _ in table)
    U = {c: v[1] for c, v in table.items()}
    steps, last = [], {}

    def origin(c):
        return last.get(c, 'table')

    def lower(cell, new, rule, premises, extra=None):
        step = {'cell': list(cell), 'from': U[cell], 'from_origin': origin(cell), 'to': new, 'rule': rule,
                'premises': [{'cell': list(p), 'ub': U[p], 'origin': origin(p)} for p in premises]}
        if extra:
            step.update(extra)
        steps.append(step)
        U[cell] = new
        last[cell] = len(steps) - 1

    for th in THEOREMS:
        c = tuple(th['cell'])
        assert U[c] == th['excluded_d'], (c, U[c])
        lower(c, th['excluded_d'] - 1, 'theorem', [], {'theorem': th['id']})

    changed = True
    while changed:
        changed = False
        for n in range(1, nmax + 1):
            for k in range(1, n + 1):
                cell, before = (n, k), U[(n, k)]
                if k <= n - 1 and U[(n - 1, k)] + 1 < U[cell]:
                    lower(cell, U[(n - 1, k)] + 1, 'puncture', [(n - 1, k)])
                if k >= 2 and U[(n - 1, k - 1)] < U[cell]:
                    lower(cell, U[(n - 1, k - 1)], 'shorten', [(n - 1, k - 1)])
                if k >= 2 and U[(n, k - 1)] < U[cell]:
                    lower(cell, U[(n, k - 1)], 'subcode', [(n, k - 1)])
                while U[cell] >= 1:
                    d = U[cell]
                    if d % 2 == 1 and n + 1 <= nmax and U[(n + 1, k)] < d + 1:
                        lower(cell, d - 1, 'parity', [(n + 1, k)])
                    elif k >= 2 and n - d >= k - 1 and U[(n - d, k - 1)] < (d + 1) // 2:
                        lower(cell, d - 1, 'residual', [(n - d, k - 1)])
                    elif k < n and U[(n, n - k)] <= k and all(
                            U[(n - w, k - w + 1)] < d for w in range(1, U[(n, n - k)] + 1)):
                        lower(cell, d - 1, 'Y1', [(n, n - k)] + [(n - w, k - w + 1)
                                                                for w in range(1, U[(n, n - k)] + 1)])
                    else:
                        break
                changed |= U[cell] < before
    return table, U, steps, last


def cone(steps, idx):
    seen, stack = set(), [idx]
    while stack:
        i = stack.pop()
        if i in seen:
            continue
        seen.add(i)
        s = steps[i]
        for o in [s['from_origin']] + [p['origin'] for p in s['premises']]:
            if o != 'table':
                stack.append(o)
    return sorted(seen)


def sentence(s, sid):
    """Chinese one-line rendering; sid maps original step index -> label."""
    def src(o):
        return '码表' if o == 'table' else sid[o]
    n, k = s['cell']
    c, d_old, d_new = fmt(s['cell']), s['from'], s['to']
    if s['rule'] == 'theorem':
        th = next(t for t in THEOREMS if t['id'] == s['theorem'])
        return (f"{c} ≤ {d_new}。码表给出 {c} ≤ {d_old}；{th['id']}（{th['where']}）排除距离恰为 {d_old} 的码。")
    p = s['premises'][0]
    pc, pu, po = fmt(p['cell']), p['ub'], src(p['origin'])
    own = f"{c} ≤ {d_old}（{src(s['from_origin'])}）"
    if s['rule'] == 'parity':
        return (f"{c} ≤ {d_new}。已有 {own}，{d_old} 为奇数。距离恰为 {d_old} 的码加一位奇偶校验得 "
                f"[{n + 1},{k},{d_old + 1}]，与 {pc} ≤ {pu}（{po}）矛盾。")
    if s['rule'] == 'shorten':
        return (f"{c} ≤ {d_new}。{fmt(s['cell'])[:-1]},≥{d_new + 1}] 码缩短一位得 "
                f"[{n - 1},{k - 1},≥{d_new + 1}]，与 {pc} ≤ {pu}（{po}）矛盾。")
    if s['rule'] == 'puncture':
        return (f"{c} ≤ {d_new}。{fmt(s['cell'])[:-1]},≥{d_new + 1}] 码穿孔一位得 "
                f"[{n - 1},{k},≥{d_new}]，与 {pc} ≤ {pu}（{po}）矛盾。")
    if s['rule'] == 'subcode':
        return f"{c} ≤ {d_new}。[{n},{k},≥{d_new + 1}] 码的 {k - 1} 维子码与 {pc} ≤ {pu}（{po}）矛盾。"
    if s['rule'] == 'residual':
        return (f"{c} ≤ {d_new}。已有 {own}。距离恰为 {d_old} 的码对一个最小重量码字取残码得 "
                f"[{n - d_old},{k - 1},≥{(d_old + 1) // 2}]，与 {pc} ≤ {pu}（{po}）矛盾。")
    if s['rule'] == 'Y1':
        rest = '；'.join(f"w={i + 1}：{fmt(q['cell'])} ≤ {q['ub']}（{src(q['origin'])}）"
                        for i, q in enumerate(s['premises'][1:]))
        return (f"{c} ≤ {d_new}。已有 {own}。设存在距离恰为 {d_old} 的码，其对偶码是 [{n},{n - k}] 码，"
                f"最小距离 w ≤ {pu}（{pc} ≤ {pu}，{po}）。在一个重量 w 的对偶码字的支撑上缩短得 "
                f"[{n}−w,{k}−w+1,≥{d_old}] 码，而对每个 w 都有矛盾：{rest}。")
    raise ValueError(s['rule'])


def main():
    table, U, steps, last = derive()
    listed = [tuple(r['cell']) for r in json.loads((HERE / 'novelty_cells.json').read_text())
              if r['cell'][0] <= 162]
    expected = {tuple(r['cell']): r['new_ub'] for r in json.loads((HERE / 'novelty_cells.json').read_text())}
    targets = [c for c in listed if c not in OWN_OR_ANNOUNCED]
    assert len(targets) == 32
    for c in targets:
        assert U[c] == expected[c], (c, U[c], expected[c])
    assert U[(43, 10)] == table[(43, 10)][1], 'local [43,10] theorem must not be needed'

    cones = {c: cone(steps, last[c]) for c in targets}
    used = sorted(set(i for v in cones.values() for i in v))
    sid = {i: f'S{j + 1}' for j, i in enumerate(used)}

    if PKG.exists():
        shutil.rmtree(PKG)
    (PKG / 'inputs').mkdir(parents=True)
    shutil.copy(SNAP, PKG / 'inputs' / 'codetables-binary-20261122.json')

    trace = []
    for i in used:
        s = dict(steps[i])
        s['id'] = sid[i]
        s['from_origin'] = 'table' if s['from_origin'] == 'table' else sid[s['from_origin']]
        s['premises'] = [{'cell': p['cell'], 'ub': p['ub'],
                          'origin': 'table' if p['origin'] == 'table' else sid[p['origin']]}
                         for p in s['premises']]
        s['text'] = sentence(steps[i], sid)
        trace.append(s)
    cells = []
    table_used = {}
    for c in targets:
        chain = [sid[i] for i in cones[c]]
        th = sorted({steps[i]['theorem'] for i in cones[c] if steps[i]['rule'] == 'theorem'})
        tab = set()
        for i in cones[c]:
            s = steps[i]
            if s['from_origin'] == 'table':
                tab.add((tuple(s['cell']), s['from']))
            for p in s['premises']:
                if p['origin'] == 'table':
                    tab.add((tuple(p['cell']), p['ub']))
        for entry in tab:
            table_used.setdefault(entry, []).append(fmt(c))
        lo, hi = table[c]
        cells.append({'cell': list(c), 'codetables': [lo, hi], 'new_ub': U[c], 'closed': U[c] == lo,
                      'theorem': th, 'chain': chain, 'steps': len(chain), 'uses_Y1': any(
                          steps[i]['rule'] == 'Y1' for i in cones[c]), 'table_entries': len(tab)})
    (PKG / 'trace.json').write_text(json.dumps({'theorems': THEOREMS, 'steps': trace}, ensure_ascii=False, indent=1))
    (PKG / 'cells.json').write_text(json.dumps(cells, ensure_ascii=False, indent=1))
    with (PKG / 'cells.csv').open('w', newline='') as f:
        w = csv.writer(f)
        w.writerow(['n', 'k', 'codetables_lb', 'codetables_ub', 'new_ub', 'closed', 'theorem', 'steps',
                    'uses_Y1', 'table_entries_used', 'chain'])
        for r in cells:
            w.writerow([*r['cell'], *r['codetables'], r['new_ub'], int(r['closed']), '+'.join(r['theorem']),
                        r['steps'], int(r['uses_Y1']), r['table_entries'], ' '.join(r['chain'])])
    with (PKG / 'table_entries_used.csv').open('w', newline='') as f:
        w = csv.writer(f)
        w.writerow(['n', 'k', 'codetables_ub', 'used_by_cells'])
        for (c, u), who in sorted(table_used.items()):
            w.writerow([c[0], c[1], u, ' '.join(who)])

    md = ['# 32 格上界的逐步推导', '',
          '记号：`[n,k] ≤ d` 表示任何二元线性 [n,k] 码的最小距离不超过 d。“码表”指 codetables.de 2026-11-22 快照的上界；'
          '`S<i>` 指下面的第 i 步。规则的证明见 README.md。', '', '## 源头定理', '']
    for th in THEOREMS:
        md.append(f"- **{th['id']}**：{th['ref']}，{th['where']}：“{th['quote']}”")
    md += ['', '## 全部步骤（按推导顺序）', '']
    for s in trace:
        md.append(f"- **{s['id']}**　{s['text']}")
    md += ['', '## 各格的推导链', '']
    by_id = {s['id']: s for s in trace}
    for r in cells:
        c = fmt(r['cell'])
        lo, hi = r['codetables']
        new = f"{lo}" if r['closed'] else f"{lo}–{r['new_ub']}"
        md += [f"### {c}：{lo}–{hi} → {new}", '',
               f"源头 {'、'.join(r['theorem'])}；{r['steps']} 步；用到 {r['table_entries']} 条码表上界。", '']
        for j, x in enumerate(r['chain'], 1):
            md.append(f"{j}. （{x}）{by_id[x]['text']}")
        md.append('')
    (PKG / 'DERIVATIONS.md').write_text('\n'.join(md))

    for name in ('bounds-progress-20261122.png', 'bounds-progress-20261122.svg'):
        shutil.copy(HERE / name, PKG / name)
    shutil.copy(HERE / 'package_verify.py', PKG / 'verify.py')
    shutil.copy(HERE / 'REPORT.md', PKG / 'novelty-search-record.md')
    rows = ['| 格 | 码表区间 | 新上界 | 新区间 | 源头 | 步数 | 经过 Y1 |', '|---|---|---:|---|---|---:|---|']
    for r in cells:
        lo, hi = r['codetables']
        rows.append(f"| {fmt(r['cell'])} | {lo}–{hi} | {r['new_ub']} | "
                    f"{lo if r['closed'] else f'{lo}–' + str(r['new_ub'])}{'（闭合）' if r['closed'] else ''} | "
                    f"{'、'.join(r['theorem'])} | {r['steps']} | {'是' if r['uses_Y1'] else ''} |")
    fill = {'TABLE': '\n'.join(rows), 'CLOSED': sum(r['closed'] for r in cells),
            'Y1': sum(r['uses_Y1'] for r in cells), 'NTABLE': len(table_used),
            'THEOREMS': '\n'.join(f"- **{t['id']}**：{t['ref']}，{t['where']}：“{t['quote']}”" for t in THEOREMS)}
    fill.update({t['id']: sum(t['id'] in r['theorem'] for r in cells) for t in THEOREMS})
    readme = (HERE / 'package_README.md').read_text()
    for key, value in fill.items():
        readme = readme.replace('{{' + key + '}}', str(value))
    assert '{{' not in readme and f'全部 {len(trace)} 个步骤' in readme and f'重放 {len(trace)} 个步骤' in readme
    (PKG / 'README.md').write_text(readme)
    shutil.copy(Path(__file__), PKG / 'build_corollary_package.py')

    print('steps used', len(trace), 'cells', len(cells), 'closed', sum(r['closed'] for r in cells),
          'with Y1', sum(r['uses_Y1'] for r in cells), 'table entries', len(table_used))
    print('by theorem', {t['id']: sum(t['id'] in r['theorem'] for r in cells) for t in THEOREMS})
    print('step counts', sorted(r['steps'] for r in cells))


if __name__ == '__main__':
    main()
    with tarfile.open(HERE / 'corollaries-32-20261122.tar.gz', 'w:gz') as tar:
        tar.add(PKG, arcname=PKG.name)
