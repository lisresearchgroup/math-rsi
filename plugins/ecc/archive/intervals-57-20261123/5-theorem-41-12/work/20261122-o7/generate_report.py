#!/usr/bin/env python3
import collections,hashlib,json,platform,subprocess
from pathlib import Path
H=Path(__file__).resolve().parent
small=json.loads((H/'small/verification.json').read_text())
s=json.loads((H/'run_38_9/summary.json').read_text())
t=json.loads((H/'timing_36/result.json').read_text())
source=json.loads((H/'timing_36/source.json').read_text())
codes=[c for c in s['codes'] if not c.get('skipped_odd')]
freq=collections.Counter(c['F_size'] for c in codes)
bins=collections.Counter(100*(c['F_size']//100) for c in codes)
agg={'completed':s['completed'],'skipped_odd':len(s['codes'])-len(codes),'F_size_min':min(freq),'F_size_max':max(freq),'F_size_sum':sum(c['F_size'] for c in codes),'F_size_frequency':dict(sorted(freq.items())),'F_size_bins_100':{f'{a}..{a+99}':b for a,b in sorted(bins.items())},'edges_total':sum(c['edges'] for c in codes),'c3_total':sum(c['c3'] for c in codes),'solutions_total':sum(c['solutions'] for c in codes),'sum_engine_seconds':sum(c['seconds'] for c in codes),'max_F_seconds':max(c['stage_seconds']['F_total'] for c in codes),'solution_indices':s['solution_indices']}
(H/'aggregate.json').write_text(json.dumps(agg,indent=2)+'\n')
p=[]
def add(x=''):p.append(x)
add('# 独立母码陪集扩张搜索：第二实现计算报告')
if s['solution_indices'] or t['solutions']:
    add('\n## 优先：实际解及全枚举验距\n')
    for f in sorted(H.glob('**/*.solution.check.json')):
        add(f'### `{f.relative_to(H)}`\n```json\n{f.read_text().strip()}\n```')
        for mat in (f.with_name(f.name.replace('.check.json','.matrix')),f.with_name(f.name.replace('.check.json','.punctured.matrix'))):
            if mat.exists():add(f'`{mat.relative_to(H)}`\n```\n{mat.read_text().strip()}\n```')
add('\n## 1. 实际结果范围\n')
add(f'- 小域：{small["count"]} 个不同母码行空间，全部通过；非空 {small["nonempty"]} 个、空 {small["empty"]} 个。每项完整解表均未触及 100000 截断上限。')
add(f'- 38/9 目录：{s["catalog_count"]} 块，完成 {s["completed"]} 块，奇重跳过 {agg["skipped_odd"]} 块。edges 总数 {agg["edges_total"]}，c3/solutions 总数 {agg["solutions_total"]}。')
add('- 本报告只记录这些输入的计算；不核查目录分类覆盖，不作其它对象域的结论。未读取另一实现、probe 或 context；未调用模型/子代理。')
add('\n## 2. 独立算法与穷尽性\n')
add('输入按最左主元 RREF 取得 P、Q。全部 $2^\\kappa$ 个实际 N 位母码字用 Gray 顺序枚举，并计算母码真实最小距离。对每个码字 c，将表初值 `f[c_Q]` 更新为 `min(f[c_Q], wt(c_P))`（其它项为 63）。因此目标正是\n\n`depth(s) = min_{c in K} [wt(c_P) + Hamming(s,c_Q)] = min_{c in K} wt(x_s+c)`。')
add('逐个自由坐标执行二元 min-plus 变换 `(a,b) -> (min(a,b+1), min(b,a+1))`。处理了 t 个坐标后，表项等于对所有种子取最小、仅允许这 t 个坐标改变并支付其 Hamming 成本的值；由归纳，全部坐标处理后就是上述直接最小值。该算法是坐标张量 Hamming 距离变换，不是从零逐层添加校验矩阵列的伴随式 BFS，也不按重量/距离分层。AVX2 并行处理同一线程内的 32 字节。')
add('完整表大小 `2^rho` 字节；扫描全部偶 s，按定义记录 F、偶 depth 直方图及 SHA-256。扫描结束后把偶 depth 压缩到低 rho-1 位；遗漏的最高位由偶性唯一确定。压缩原地写入位置不大于读取位置，不覆盖尚未读取的偶项。成员表同样用低 rho-1 位索引。它不是删去等价类，而是偶域的双射编码。')
add('对每个 F 下标 i<j 恰好做一次 XOR 成员判定，建立前向邻接表。递增下标枚举候选集合，候选交集恰好要求全部 pair 条件。每次加入头时逐一检查所有包含新头且大小≥3的子集；旧子集已在父节点检查。每个无序集合有唯一递增序列，故通过条件的集合不被遗漏、也不重复。没有使用其它剪枝或对称约化。统计到 w-1；最终解按字典序输出，超 100000 时才截断显示而不截断计数。')
add('实际运行单个搜索进程单线程；目录同时最多两个搜索进程。F 计时包括初始化、距离变换、全域偶扫描、哈希及压缩；`seconds` 到全部搜索结束，不含 JSON 最后写盘/进程析构。')
add('\n## 3. 独立小域暴力验算\n')
add('`validate_small.py` 不用搜索器的图或高阶 XOR-depth 判据：独立用 Python 坐标位列表做 RREF，实际构造 x_s；逐个偶伴随式用全部实际母码字求 depth/F 并展开单头生成矩阵。失败的单头，其实际低重码字也存在于任何包含它的扩张，故可独立排除其全部超集；奇头由规格的偶性条件直接排除。在余下域上对每个 j=2..m 的全部无序 j 元子集独立展开真实 (κ+j)×(N+w) 矩阵，列举全部 2^(κ+j) 个消息/码字后求距离，无 pair/clique 剪枝。前 12 项 D=4 的 F 就是全部非零偶伴随式。所有母码真实距离均≥D。')
add('逐项比较：完整 F 元素、规范 SHA-256、P/Q、母码最小距离、完整偶 depth 直方图、edges、c3/c4/c5、solutions 和逐元素完整解表。最终测试的 33 个母码行空间互异（不是把同一码的不同 w 重复算作不同母码），全部有重复列。')
add('|idx|N|κ|ρ|w|D|F|edges|c3|c4|c5|solutions|结果|')
add('|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|:---|')
for c in small['cases']:
    vals=[c.get(k,'—') for k in ['idx','N','kappa','rho','w','D','F_size','edges','c3','c4','c5','solutions']]+['PASS' if c['pass'] else 'FAIL']
    add('|'+'|'.join(map(str,vals))+'|')
add(f'\n最终完整验证用时 {small["seconds"]:.6f} 秒；详细逐层展开次数在 `small/verification.json`，输入、F 和搜索结果分别保存在 `small/*.matrix`、`*.F`、`*.json`。无不一致。')
add('\n## 4. 47 码目录运行\n')
add(f'输入：`{s["catalog"]}`；SHA-256 `{s["catalog_sha256"]}`。')
add('|idx|F_size|edges|c3 / solutions|F 秒|总秒|')
add('|---:|---:|---:|---:|---:|---:|')
for c in s['codes']:
    if c.get('skipped_odd'):add(f'|{c["idx"]}|奇重跳过|—|—|—|—|')
    else:add(f'|{c["idx"]}|{c["F_size"]}|{c["edges"]}|{c["solutions"]}|{c["stage_seconds"]["F_total"]:.6f}|{c["seconds"]:.6f}|')
add('\n精确 F_size 频数及汇总：\n```json\n'+json.dumps(agg,indent=2)+'\n```')
add('另用 Python 实际位向量重新全枚举 47 个母码的全部非零码字，满秩、偶性、最小距离 16 与规范 P/Q 均一致，见 `real_mother_checks.json`。')
add('逐码完整 F_sha256 和阶段秒数在 `run_38_9/summary.json`，逐码完整输出在 `<idx>.json`。这些 w=4 任务按规格只统计到 c3，不输出 c4/c5。')
add('\n## 5. N=36 单进程计时\n')
add(f'取 qext 目录首个各行偶重码：`{source["catalog"]}`，idx={source["idx"]}，没有添加零坐标。输入快照 `timing_36/mother.matrix`；来源/输入哈希在 `timing_36/source.json`。该运行在 47 码全部完成后单独执行。')
add('完整统计量（包含阶段秒数）：\n```json\n'+json.dumps(t,indent=2)+'\n```')
add('另用 Python 对保存的 99057 个 F 元素逐一展开实际 36 位代表，在全部 128 个真实母码字上取最小值，全部 depth=14；元素有序无重复、哈希一致。见 `timing_36/dump_direct_checks.json`。这项补充检查只核保存成员，不作为独立全域完整性重跑。')
add('系统计时和最大 RSS：\n```\n'+(H/'timing_36/time.txt').read_text().strip()+'\n```')
add('\n## 6. 驱动器、复现与异常记录\n')
add('`run_catalog2.py` 标准库解析 CRLF/说明头/`HULL=`，按原 idx 运行；奇重行写 `<idx>.skipped_odd.json`。qext 现存文件不含 Zenodo 的块后整数，解析器额外兼容此变体。结果先写 `<idx>.json.tmp`，成功解析后 `os.replace`，失败不冒充完成。重启读取已有结果并核参数/输入快照，跳过搜索；最后原子写 summary。发现实际解时终止其它搜索并展开首解、全枚举验距和删最后坐标验距，保存矩阵、谱，然后停止。')
add('小域验证集强化为 33 个不同母码行空间时，目录在 16 个完成结果后手动暂停；无计算不一致。最终验证全部通过后恢复，同一最终搜索二进制跳过这 16 个已有结果。初次日志 `run_38_9.initial.log`、恢复日志 `run_38_9.log` 保留；恢复 summary 的 wall_seconds 只计恢复段，逐码 seconds 是各自真实运行计时。未报告暂停期间为计算用时。')
if (H/'driver_smoke/result.json').exists():add('驱动器 CRLF/头部说明/奇重跳过/原子结果与重启测试通过，见 `driver_smoke/result.json`。')
add('复现（在 case 根目录）：\n```bash\ng++ -O3 -march=native -std=c++17 -Wall -Wextra work/20261122-o7/ext2.cpp -o work/20261122-o7/ext2\npython3 work/20261122-o7/validate_small.py\npython3 work/20261122-o7/run_catalog2.py work/20261122-catalog/zenodo/extracted/38_9_16.2 4 16 work/20261122-o7/run_38_9 --jobs 2\n/usr/bin/time -v -o work/20261122-o7/timing_36/time.txt work/20261122-o7/ext2 work/20261122-o7/timing_36/mother.matrix 6 16 work/20261122-o7/timing_36/result.json --dump-F work/20261122-o7/timing_36/F.txt\npython3 work/20261122-o7/generate_report.py\n```')
add('编译器：`'+subprocess.check_output(['g++','--version'],text=True).splitlines()[0]+'`；CPU Intel Xeon 6982P-C；无第三方库。')
(H/'REPORT.md').write_text('\n'.join(p)+'\n')
print(json.dumps(agg,indent=2));print('N36',t['stage_seconds'], 'seconds',t['seconds'])
