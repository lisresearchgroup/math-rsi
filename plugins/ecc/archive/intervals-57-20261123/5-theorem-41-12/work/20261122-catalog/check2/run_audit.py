#!/usr/bin/env python3
"""Reproduce the independent audit. Python 3 standard library + C++17 compiler.
Only the three specified inputs and this output directory are opened.
All persistent outputs and compiler temporary files are under check2/.
"""
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
import hashlib
import json
import math
import os
from pathlib import Path
import re
import subprocess
import sys
import time

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
SPECS = [
    ('work/20261122-catalog/zenodo/extracted/38_9_16.2', 38, 9, 47),
    ('work/20261122-catalog/qext/run_36_7_16/36_7_16.2', 36, 7, 8170),
    ('work/20261122-catalog/qext/run_37_8_16/37_8_16.2', 37, 8, 17276),
]
HEADER = re.compile(r'\s*\?(\d+)\s+(\d+)\s+(\d+)\s+(\d+)(?:\s+HULL=(\d+))?\s*')


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


def read_blocks(path, n, k, expected):
    """Second parser: explicitly consumes every line between headers and EOF."""
    data = path.read_bytes()
    lines = data.decode('ascii').splitlines()
    starts = [i for i, s in enumerate(lines) if s.lstrip().startswith('?')]
    blocks = []
    metadata = 0
    footer = []
    for pos, start in enumerate(starts):
        match = HEADER.fullmatch(lines[start])
        assert match, ('invalid header', path, start + 1)
        hk, hn, q, idx = map(int, match.groups()[:4])
        assert (hk, hn, q) == (k, n, 2)
        rows = lines[start + 1:start + k + 1]
        assert len(rows) == k
        assert all(re.fullmatch('[01]{%d}' % n, s) for s in rows)
        end = starts[pos + 1] if pos + 1 < len(starts) else len(lines)
        trailer = [s.strip() for s in lines[start + k + 1:end] if s.strip()]
        if trailer and re.fullmatch(r'[+-]?\d+', trailer[0]):
            # Decimal post-block metadata is not a generator row. Reject an
            # n-bit binary extra row even though it also parses as an integer.
            assert not re.fullmatch('[01]{%d}' % n, trailer[0])
            metadata += 1
            trailer = trailer[1:]
        if pos + 1 < len(starts):
            assert not trailer, ('unconsumed inter-block text', idx, trailer)
        else:
            assert len(trailer) == 2
            assert re.fullmatch(r'RES(?:\s+\d+)+', trailer[0])
            assert re.fullmatch(r'==\s+Elapsed time:\s*[0-9.]+s', trailer[1])
            footer = trailer
        blocks.append((idx, rows))
    assert len(blocks) == expected
    ids = [idx for idx, _ in blocks]
    assert len(set(ids)) == expected and sorted(ids) == list(range(1, expected + 1))
    return blocks, {
        'block_count': len(blocks),
        'total_generator_rows': len(blocks) * k,
        'all_row_lengths_correct': True,
        'idx_exactly_1_to_count_without_duplicates': True,
        'idx_in_increasing_order': ids == sorted(ids),
        'optional_integer_metadata_lines': metadata,
        'all_inter_block_lines_consumed': True,
        'footer_lines': footer,
        'crlf_line_endings': data.count(b'\r\n'),
        'input_sha256': hashlib.sha256(data).hexdigest(),
    }


def independent_metrics(audit, blocks):
    """Python check uses doubling enumeration, pivot dictionary, and hull
    cardinality (not the C++ Gram-matrix rank computation).
    """
    n, k = audit['n'], audit['k']
    records = {c['idx']: c for c in audit['codes']}
    checks = 0
    for idx, text_rows in blocks:
        rec = records[idx]
        rows = [sum((s[j] == '1') << j for j in range(n)) for s in text_rows]
        pivots = {}
        for row in rows:
            v = row
            while v:
                b = (v & -v).bit_length() - 1
                if b not in pivots:
                    pivots[b] = v
                    break
                v ^= pivots[b]
        words = [0]
        for row in rows:
            words += [v ^ row for v in words]
        assert len(set(words)) == 1 << k
        spectrum = Counter(w.bit_count() for w in words)
        columns = [sum(((r >> j) & 1) << i for i, r in enumerate(rows)) for j in range(n)]
        multiplicities = Counter(columns)
        hull_count = sum(all((w & r).bit_count() % 2 == 0 for r in rows) for w in words)
        assert hull_count > 0 and hull_count & (hull_count - 1) == 0
        computed = {
            'row_count': k,
            'row_lengths': [n] * k,
            'rank': len(pivots),
            'minimum_distance': min(w.bit_count() for w in words if w),
            'weight_spectrum_including_zero': [spectrum[w] for w in range(n + 1)],
            'zero_columns_zero_based': [j for j, c in enumerate(columns) if c == 0],
            'even': not any(w % 2 for w in spectrum),
            'repeated_columns': max(multiplicities.values()) > 1,
            'column_multiplicity_histogram': {str(x): y for x, y in sorted(Counter(multiplicities.values()).items())},
            'hull_dimension': hull_count.bit_length() - 1,
        }
        for name, value in computed.items():
            assert rec[name] == value, (idx, name, rec[name], value)
            checks += 1
    return {'codes_checked': len(blocks), 'field_comparisons': checks, 'mismatches': 0,
            'hull_method': 'enumerate C intersect C_perp, then log2 cardinality'}


def verify_pair_coverage(audit):
    buckets = defaultdict(list)
    for c in audit['codes']:
        buckets[c['invariant']].append(c['idx'])
    expected_pairs = {tuple(sorted((a, b))) for v in buckets.values()
                      for j, a in enumerate(v) for b in v[j + 1:]}
    records = audit['exact_pairs']
    actual_pairs = {tuple(sorted((r['idx_a'], r['idx_b']))) for r in records}
    assert len(records) == len(actual_pairs)
    assert actual_pairs == expected_pairs
    assert all(r['exhaustive'] for r in records)
    s = audit['summary']
    assert s['invariant_bucket_count'] == len(buckets)
    assert s['pairs_requiring_exact'] == len(records) == audit['exact_pairs_completed']
    assert s['pairs_excluded_by_invariant'] + len(records) == math.comb(s['count'], 2)
    assert not audit['unresolved_pairs']
    assert audit['equivalent_pair_count'] == sum(r['equivalent'] for r in records)
    assert audit['all_pairwise_inequivalent_proved'] == (audit['equivalent_pair_count'] == 0)
    return {'all_within_bucket_pairs_present_once': True,
            'all_pairs_accounted_for': True,
            'total_unordered_pairs': math.comb(s['count'], 2)}


def run_catalogue(spec, env):
    path, n, k, expected = spec
    stem = f'{n}_{k}_16'
    command = [str(BASE / 'audit'), path, str(n), str(k), str(expected), str(BASE / stem)]
    with (BASE / f'{stem}.stdout.log').open('w') as out, (BASE / f'{stem}.stderr.log').open('w') as err:
        result = subprocess.run(command, cwd=ROOT, env=env, stdout=out, stderr=err)
    assert result.returncode == 0, (stem, result.returncode)
    print(stem, 'C++ audit completed', flush=True)
    return command


def main():
    start = time.monotonic()
    env = dict(os.environ, TMPDIR=str(BASE))
    compiler = 'g++'
    version = subprocess.check_output([compiler, '--version'], text=True).splitlines()[0]
    commands = []
    with (BASE / 'compile.log').open('w') as log:
        for source, target in [('audit.cpp', 'audit'), ('test_exact.cpp', 'test_exact')]:
            cmd = [compiler, '-std=c++17', '-O3', '-Wall', '-Wextra', '-Wpedantic', str(BASE / source), '-o', str(BASE / target)]
            commands.append(cmd)
            subprocess.run(cmd, cwd=ROOT, env=env, stdout=log, stderr=log, check=True)
    with (BASE / 'exact_selftest.json').open('w') as out, (BASE / 'exact_selftest.stderr.log').open('w') as err:
        cmd = [str(BASE / 'test_exact')]
        commands.append(cmd)
        subprocess.run(cmd, cwd=ROOT, env=env, stdout=out, stderr=err, check=True)
    with ThreadPoolExecutor(max_workers=3) as pool:
        futures = [pool.submit(run_catalogue, spec, env) for spec in SPECS]
        commands += [f.result() for f in futures]
    audits = []
    for path, n, k, expected in SPECS:
        output = BASE / f'{n}_{k}_16.audit.json'
        audit = json.loads(output.read_text())
        blocks, parser_check = read_blocks(ROOT / path, n, k, expected)
        audit['independent_parser_check'] = parser_check
        audit['independent_python_metrics_check'] = independent_metrics(audit, blocks)
        audit['pair_coverage_check'] = verify_pair_coverage(audit)
        assert not audit['format_errors']
        assert audit['summary']['rank_histogram'] == {str(k): expected}
        assert audit['summary']['minimum_distance_histogram'] == {'16': expected}
        assert not audit['summary']['zero_column_failures']
        even_ids = [int(s) for s in (BASE / f'{n}_{k}_16.even_idx.txt').read_text().splitlines()]
        assert even_ids == sorted(c['idx'] for c in audit['codes'] if c['even'])
        assert len(even_ids) == audit['summary']['count_even']
        audit['input_sha256'] = sha256(ROOT / path)
        audit['audit_cpp_sha256'] = sha256(BASE / 'audit.cpp')
        audit['test_exact_cpp_sha256'] = sha256(BASE / 'test_exact.cpp')
        write_json(output, audit)
        audits.append(audit)
        print(n, k, 'Python metric and pair-coverage checks completed', flush=True)
    test = json.loads((BASE / 'exact_selftest.json').read_text())
    manifest = {
        'completed_at_local': datetime.now().astimezone().isoformat(),
        'compiler': version, 'python': sys.version,
        'commands': commands,
        'source_sha256': {name: sha256(BASE / name) for name in ['audit.cpp', 'test_exact.cpp', 'run_audit.py']},
        'inputs': {a['input']: a['input_sha256'] for a in audits},
        'elapsed_seconds': time.monotonic() - start,
        'catalogues': [{
            'n': a['n'], 'k': a['k'], 'summary': a['summary'],
            'all_pairwise_inequivalent_proved': a['all_pairwise_inequivalent_proved'],
            'exact_pairs_completed': a['exact_pairs_completed'],
            'equivalent_pair_count': a['equivalent_pair_count'],
        } for a in audits],
    }
    write_json(BASE / 'run_manifest.json', manifest)
    report(audits, test, manifest)
    print('REPORT.md written; all checks complete.', flush=True)


def hist(value):
    return ', '.join(f'{k}:{v}' for k, v in value.items())


def report(audits, test, manifest):
    lines = ['三份二元线性码目录独立核验（第二实现）', '', '核验日期：2026-11-22。', '']
    eqs = [(a, r) for a in audits for r in a['exact_pairs'] if r['equivalent']]
    if eqs:
        lines += ['**严重异常：发现不同 idx 的等价码。**', '']
        for a, r in eqs:
            lines += [f"[{a['n']},{a['k']},16] idx {r['idx_a']} → {r['idx_b']}，源坐标到目标坐标（0 起始）置换：`{r['permutation_source_to_target_zero_based']}`。", '']
    else:
        lines += ['**异常：未发现等价码对；格式、秩、最小距离、零列及已声明 HULL 均无失败。未判定码对为 0。**', '']
    lines += [
        '| 目录 | count | count_even | 偶且无重复列 | hull 直方图（全部） | hull 直方图（偶码） |',
        '|---|---:|---:|---:|---|---|',
    ]
    for a in audits:
        s = a['summary']
        lines.append(f"| [{a['n']},{a['k']},16] | {s['count']} | {s['count_even']} | {s['count_even_no_repeated_columns']} | {hist(s['hull_histogram'])} | {hist(s['even_hull_histogram'])} |")
    lines += ['', '| 目录 | 不变量桶 | 最大桶 | 不变量排除的对 | 精确判定的对 | 等价对 | 全部两两不等价已证 |', '|---|---:|---:|---:|---:|---:|---|']
    for a in audits:
        s = a['summary']
        lines.append(f"| [{a['n']},{a['k']},16] | {s['invariant_bucket_count']} | {s['largest_invariant_bucket']} | {s['pairs_excluded_by_invariant']} | {a['exact_pairs_completed']} | {a['equivalent_pair_count']} | {'是' if a['all_pairwise_inequivalent_proved'] else '否'} |")
    lines += [
        '', '三个目录所有块均有恰好 k 行、每行恰好 n 个二进制字符；idx 分别为 1..47、1..8170、1..17276，各无重复。全部 GF(2) 秩等于 k，所有非零码字均已枚举，所有最小距离均恰为 16，无零列。',
        f"非零消息枚举总数为 {sum(a['summary']['nonzero_messages_enumerated'] for a in audits):,}；分目录为 " + '、'.join(str(a['summary']['nonzero_messages_enumerated']) for a in audits) + '。逐码完整重量谱包含零码字，JSON 数组下标就是重量。',
        '', '**方法与穷尽性。**',
        '', '矩阵最左字符存为 bit 0。GF(2) 消元核秩；遍历所有 2^k 个消息生成码字并记录重量谱；直接核每一列及其重数。偶性由完整重量谱判定。hull 用 k − rank(G G^T) 计算。输入可选 HULL 字段只用作事后比较。',
        '', '分桶图有两类顶点：每个不同列向量一个顶点（初色为列重数），每个码字一个顶点（初色为重量，颜色范围与列顶点分开）。若码字在该列位置为 1 则连边。换基使列向量与消息作互为逆转置的重标号，内积不变；坐标置换只重排列及其重数。因此此带色关联图不依赖生成基及坐标编号。',
        '', '每轮将“旧颜色、已排序的邻居颜色多重集”作字典序排序，重新赋色，并记录所有签名的排序序列，直到颜色类数不再增加。等价码在每一轮的排序序列完全相同。程序将这些序列以及 n、k、秩、hull、完整重量谱送入固定的两个 64 位确定性摘要作桶键。不同摘要严格排除等价；相同摘要一律进入精确判定。摘要碰撞只会增加待判定对，结论不依赖无碰撞假设。局部颜色编号只作必要条件：真正等价的两图必给相应顶点同色。',
        '', '同桶码对采用 F2^k 上的可逆线性映射穷尽搜索。满秩矩阵 G_A、G_B 所定义码坐标等价，当且仅当某个 L ∈ GL(k,2) 将 G_A 的列多重集映到 G_B 的列多重集：坐标等价给出 G_B = R G_A P（R 可逆）；反向由列多重集相等配对各列得到坐标置换。',
        '', '搜索维护一个子空间上的线性双射。选一个尚不在子空间内的实际源列，遍历所有不在像子空间内、重数及细化颜色相容的实际目标列，并按线性性扩展整个新陪集。对扩展子空间的每个向量（包含不是实际列的向量）比较列重数与适用的列颜色。此剪枝均是任何完整等价映射的必要条件。源列满秩保证每层可增一维，最多 k 层到达全空间；每个可能的完整映射都经过其在每层的某个目标列分支。所有分支失败即严格不等价，无时间/节点截断。若成功，配对各列生成 p[j]（源坐标 j → 目标坐标 p[j]，0 起始），并重新运输所有码字与目标码字集合逐项比较。',
        '', 'Python 再按逐码桶键重建所有同桶无序对，检查 exact_pairs 恰好包含它们且每对一次；异桶对数与同桶对数之和等于 count*(count−1)/2。全部 125 个实际同桶对已判完，其逐对结论、搜索节点数及候选扩展数均在 JSON。',
        '', '**自测与独立复算。**',
        '', f"随机变换自测种子为 0x20261122ac02；三目录分别测试 " + '、'.join(str(a['selftest']['random_transform_tests']) for a in audits) + ' 个按 idx 范围均匀选取的码。每次随机置换全部坐标，并作 12*k 次随机行异或尝试（两行相同时跳过，每个实际操作均可逆）。全部不变量保持不变，精确搜索全部返回等价，所有返回的坐标置换均经完整码字集合复核。',
        '', f"额外小规模穷尽对照：枚举 F2^5 的全部二维及三维子空间，各 {test['distinct_subspaces_per_dimension'][0]} 个，共 310 个码。对每码遍历全部 5! 坐标置换，合计 {test['coordinate_permutations_enumerated']} 次置换；以变换后码字集合的字典序最小值独立判等。将精确搜索与此结果对照全部 {test['pairs_including_self']} 个含自身无序对：等价 {test['equivalent_pairs']} 对，不等价 {test['inequivalent_pairs']} 对，差异 {test['mismatches']}。该域包含零列及重复列，且所有真等价对的不变量相同。证据为 exact_selftest.json。", 
        '', '另用 Python 独立解析三份原文件并消费块间全部行、可选整数及尾部统计；用另一种主元字典消元及逐行倍增码字枚举，对全部 25,493 块重新核对 10 个逐码字段。hull 以全枚举 C ∩ C^⊥ 的基数取 log2 复算，不调用 C++ 的 Gram 秩算法。共 254,930 个字段比较，差异为 0。三个 even_idx.txt 与逐码偶性记录逐项一致且升序。',
        '', '**输入与复现。**', '', f"编译器：{manifest['compiler']}。实现仅使用 C++17 标准库和 Python 3 标准库。未调用模型或子代理。所有任务产物写入本 check2 目录；未读取任务列明的禁止目录。", '', '| 输入 | SHA-256 |', '|---|---|',
    ]
    for a in audits:
        lines.append(f"| `{a['input']}` | `{a['input_sha256']}` |")
    lines += ['', '在任务根目录执行：', '', '```sh', 'python3 work/20261122-catalog/check2/run_audit.py', '```', '', '源码：audit.cpp（逐码及精确搜索）、test_exact.cpp（坐标置换穷举对照）、run_audit.py（编译、运行、独立复算、覆盖核对、报告）。', '', '每目录的 .audit.json 含逐码记录、汇总、全部精确判定对及自测；.even_idx.txt 为偶码 idx；.stderr.log 为原生运行日志。run_manifest.json 记录命令、输入及源码校验和、工具版本；compile.log 记录编译输出。']
    (BASE / 'REPORT.md').write_text('\n'.join(lines) + '\n')


if __name__ == '__main__':
    main()
