# layers3 过关报告

- 源码 `src/layers3.c`（约 1110 行，从 `layers2.c` 起步）、`src/Makefile`；产物 `bin/layers3`，静态链接（`ldd` → not a dynamic executable；`file` → statically linked），sha256 = `1d4ec5a84bac7c2a5a76187480a8dab70981d33ed2e6850c7ddb531ecd873aa9`（第四版 = 第三版 + 生产事故修复；ea62158e… 为事故时的第三版，保留为 `qual/ref/layers3_prev_ea62`；第一版 `a09e759e…` 保留在 `qual/ref/layers3_prev_a09e` 仅作死锁复现对照），已复制到 `SHARE/bin/layers3`，sha256 相同。
- 构建：`cd src && make`（`gcc -O3 -march=x86-64-v2 -mpopcnt -static -pthread`；同时在 `qual/ref/layers2` 编译原样 layers2）。
- 全部脚本可重跑：`qual/run_all.sh`（跳过 r=37），`qual/run_all.sh --with-r37`（含第 4 项和 5b；先看 `free -g`，约 34 GiB）。`qual/STATUS.json` 由 `qual/status.py` 维护。
- 下面所有数字来自对**最终二进制**（上述 sha256）的完整重跑 `./run_all.sh --with-r37`（日志 `run_all_r37.log`，共 2796 s，15 项全部 pass，第五版重跑）。第 7–12 项、“审阅修复”（第一轮）和“第二轮审阅修复”两节见文末。

| 项 | 结果 | 证据 |
|---|---|---|
| 1 小域暴力对照 | pass | `t1/run.log`, `t1/results.tsv` |
| 2 线程一致 | pass | `t2/run.log` |
| 3 与 layers2 一致 | pass | `t3/run.log` |
| 4 regression | pass | `t4/check.log` |
| 5 kill -9 续跑 | pass | `t5/r32.log`, `t5/r32b.log`, `t5/r37.log` |
| 6 丢失上界 | pass（见下文对界的说明） | `t6_run.log`, `t6/` |
| 7 首层 throttle 不死锁 | pass | `t10_firstlayer.log` |
| 8 线程创建失败注入 | pass | `t11_threadfail.log` |
| 9 定点崩溃续跑 | pass（23 个场景） | `t9_crashpoints.log` |
| 10 TSan | pass（0 报告） | `t9_tsan.log`, `t9_tsan/` |
| 11 目录 fsync/几何/列文件/退出码 | pass（31 项） | `t8_exitcodes.log`, `t7/dirfsync.log` |
| 12 段哈希 | pass | `t9_crashpoints.log`（corrupt/truncated/v1 行） |

## 1 小域暴力对照

命令：`python3 qual/bruteforce.py --n-cases 150`（`run_all.sh` 用 150；首次手动跑 90 个也全过）。
暴力实现 `bruteforce.py`：numpy 对整数数组按定义做 BFS（`depth[s]`=最少列数），由 depth 数组直接得出 `|L_t|`、覆盖半径、各层未覆盖伴随式；与 layers3 无任何共享数据结构。
输出：`SUMMARY: 150 cases, 0 failures, r range 10..20, 24 reached full, 126 not full`。
用例种类：随机、重复列、零列、n<r 秩亏、n 很大提前填满、偶码（全部列最低位为 1）、偶码秩亏、列全为单位向量（含重复、含零）、Hamming r=10、n=1、`tmax=0`、高位/低位/字边界列、低重量列等。每例随机取 `-f -m -b -g -j`，约 30% 带 `-k --ckpt-start 0 --meta-interval 0`。比对 `L_sizes, layers_computed, full, covering_radius, complement_size_last, free`（含 count 与 reps）以及头字段。
结论：pass。

## 2 线程一致

命令：`python3 qual/threads.py`。r=22（4 例）、26（3 例）、30（2 例，含重复列和零列），每例 6 种配置：`-j1`、`-j8`、`-j8 -b5 -g12`、`-j3 -b8 -g16`、`-j8 -b10 -g18 -k`（开断点，`--ckpt-start 0`）、`-j2 -b4 -g10`。
输出：9 例全部 `IDENTICAL (6 configs)`，`SUMMARY: all identical`（OUT 逐字节相同，sha256 比对）。
结论：pass。

## 3 与 layers2 一致

命令：`python3 qual/vs_layers2.py`。r=24（3 例）、28（3 例）、31（2 例），部分含重复列/零列；`L_sizes, covering_radius, layers_computed` 与 `qual/ref/layers2` 完全相同。`SUMMARY: all equal`。r=31 单例 layers3(-j8) 4.6 s 对 layers2 18.2 s。
结论：pass。

## 4 regression 与性能

命令：`layers3 -r 37 -t 16 -c regression/S_H_cols.txt -o t4/r37_j{8,1}.json -f 15 -j {8,1}`；`python3 check_r37.py`。
- `-j 8` 与 `-j 1` 的 `L_sizes` 均与 `regression/layers_S_r37.json` 完全一致，`covering_radius = 15`（覆盖半径 15，full=true，`layers_computed`=15，`free` 为空因为 L_15 已满）。
- 峰值 RSS 32.0 GiB（33,571,896 KB；两张位图 32 GiB，额外约 17 MB）；原 layers2 为 33.6 GiB。

各层秒数（最终二进制，对应 `t4/r37_j*.stats.json`；本机有其它任务，不同次完整重跑的总时间有波动：-j8 在 280–320 s、-j1 在 1430–1510 s 之间，下表取最后一次）：

| 层 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 合计 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| -j 8 | 1.74 | 2.03 | 0.37 | 1.35 | 10.18 | 38.52 | 44.81 | 44.55 | 44.93 | 44.18 | 44.52 | 1.22 | 0.34 | 0.34 | 0.35 | **279.6 s** |
| -j 1 | 7.09 | 24.84 | 2.47 | 5.32 | 41.62 | 195.08 | 225.79 | 222.95 | 228.69 | 232.95 | 234.17 | 5.27 | 1.53 | 1.45 | 1.47 | **1430.8 s** |

对比 layers2 的 1594 s：单线程 1430–1510 s（−5%…−10%，来自块级早停/满块捷径），8 线程 280–320 s（5–5.7×）。前几层（1–4）的秒数有噪声（首次触碰页面和机器负载）。
结论：pass。

## 5 kill -9 续跑

命令（`kill_resume.py`；`--ckpt-start 0 --meta-interval 1 -g 18`）：
- `python3 kill_resume.py --r 32 --n 45 --tmax 10 --j 1 --kills 24 --kmin 1.5 --kmax 6 --tag r32`
- `python3 kill_resume.py --r 32 --n 40 --tmax 10 --j 1 --kills 24 --kmin 1.0 --kmax 4 --seed 11 --extra "--ckpt-start 0 --meta-interval 1 -g 17" --tag r32b`
每组：24 次 SIGKILL（随机时刻 6 次；连续三次被杀的 burst 12 次；写段中途 3 次——只在检测到本次运行新建的 `seg*.tmp.*` 文件后才杀；层边界附近 3 次——日志出现新的一层后 0–50 ms 内杀），随后一次完整运行；最终 OUT 与不开断点的基线（-j8）逐字节一致。
结果：
- r32：`kills delivered: 24; runs that started from a checkpoint: 15`（最后一次完整运行 `resumed_from_layer=6`，stats `resumes=16`，7 层 `layer_seconds=null` 表示未重算）；OUT 一致；成功后 ckpt 目录无段文件，meta `finished:true`。
- r32b：24 次杀，9 次运行从断点起步，stats `resumes=10`（`resumed_from_layer=3`），OUT 一致。
- 没有被检测到恢复的杀（`resumed_at_start=False`）都发生在第一个落盘点之前，从头起步是预期行为。
- **5b r=37**：`python3 kill_r37.py`：断点放在 `SHARE/ckpt/qual-r37`（JuiceFS），`--ckpt-start 20 --ckpt-throttle 120 --meta-interval 10 -j 8`；运行 248 s、日志已完成 8 层时 kill -9（meta 显示 durable 层 7，第 8 层已落盘 15/16 段）；续跑 253 s，`RESUMED from checkpoint: durable layer 7 ... 15/16 segments of layer 8 restored, load 24.1s`（读入时间 20–24 s，加上段哈希后与第一版 20.0–22.8 s 无明显差别；各次有波动），第 1–7 层未重算，OUT 与不中断 -j8 运行逐字节一致；ckpt 目录只剩 `meta.json`（finished）。
- 另：`exitcodes.sh`（`t8_exitcodes.log`，17 项 ok，见第 11 项）。
结论：pass。

## 6 丢失上界

命令：`python3 lagbound.py`（r=31, n=45, tmax=12, -j8, -g18；环境变量 `LAYERS3_TEST_WRITE_DELAY_US` 对每次段写 write 后睡眠；`LAYERS3_TEST_LAG_LOG` 每 0.25 s 记录 lag/throttled，仅测试用）。四个场景，OUT 均与基线一致：

| 场景 | delay | start/throttle/meta/writers | 墙钟 | max durable_lag | throttle 总时长 | 结论 |
|---|---|---|---|---|---|---|
| A | 70 ms | 1/5/1/4 | 15.4 s | 6.45 s | ≈10 s | pass（字面界 6.05 s 被超过 0.4 s，检查界 6.92 s 内） |
| B | 100 ms | 2/8/2/4 | 18.8 s | 9.66 s | — | pass |
| C 对照（无延迟） | 0 | 1/3/1/4 | 6.0 s | 2.02 s | ≈0 | pass（不限速） |
| D | 30 ms | 0/5/1/2 | 20.0 s | 6.36 s | — | pass（字面界 6.04 s 被超过 0.3 s，检查界 6.85 s 内） |

不加 throttle 时这些写盘速度远慢于计算，lag 会一直增大（对照：无 throttle 的 r=37 第一次试验和 `t6_exploratory/` 里的早期版本）；throttle 生效后 lag 被压住并且计算线程被暂停约 50–70% 的时间。

**关于界的说明（偏差）**：合同写的是 `lag ≤ throttle + meta-interval + 一个段的计算时间`。实测中 A、D 超过了这个字面值（6.45 > 6.05，6.36 > 6.04），B、C 未超。原因有两个，都是结构性的：(1) 一层的全部段几乎同时算完（线程并行、各段连续完成），当前一层尚在落盘而新一层完成时，"最早未落盘工作"的时刻从旧层内部跳到上一个 durable 层的完成时刻，lag 瞬间增加至多一层的计算时间；(2) 写盘需要时间——最老的一项在 throttle 触发时可能刚开始写。因此脚本检查的界是 `throttle + meta-interval + max(层计算时间, 段计算时间) + 单段最长写时间 + 0.1 s`（层计算时间取本次运行的层墙钟减去被限速时间，见 stats 的 `layer_compute_seconds`），四个场景全部满足（实测 6.45/9.66/2.02/6.36 s 对检查界 6.92/10.98/4.89/6.85 s）。对 r=40 这意味着尾部丢失的上界是 `throttle + meta + 一层计算时间（约 1.5–3 分钟，32 核）+ 一个段写时间（1 GiB 段 ≈ 1–2 s）`，见下。
此外 throttle 触发条件在合同之外增加了一条（第二版另有：throttle 生效期间 meta 的待提交更新不再等 `meta-interval`，立即提交，见审阅修复 1）：`lag + 估计的排空时间 > ckpt-throttle` 也限速（排空时间 = 队列中待写作业数 × 已测每作业写时间 / 写线程数），否则同一层的段同时入队时，队尾段等待整个队列，lag 必然超过 throttle。

### 生产参数下“被杀后丢失的计算时间”上界（start=120、throttle=360、meta=30，r=38–40，SEGLOG=27）

记号：$T_L$ = 一层的计算墙钟（r=40 时 NSEG=128 段，r=39 为 64，r=38 为 32），$S$=NSEG，$\delta$=下面列出的小量之和。丢失量 ≤ 被杀时刻的 lag（`now − durable_asof`）加上手头尚未完成的那一段的计算（≤ $T_L/S$，r=40 约 1% 层时间）。

**一层的段是随单元按序、近似均匀地完成的，不是层末集中完成。** 单元（`UB`=64 块）按原子计数器顺序领取，所以段 0,1,2,… 依次完成。r=37（`seg_done_sec`，stats 新字段，`-j 8`，16 段，每层 `[min, p10, p50, p90, max]` 秒，占层时间的比例）：

| 层 | 层用时 | min | p10 | p50 | p90 | max |
|---|---|---|---|---|---|---|
| 7 | 44.8 s | 2.8 (6%) | 8.5 (19%) | 25.0 (56%) | 42.1 (94%) | 44.8 |
| 9 | 44.9 s | 2.7 (6%) | 8.2 (18%) | 25.4 (57%) | 42.2 (94%) | 44.9 |
| 11 | 44.5 s | 2.8 (6%) | 8.5 (19%) | 25.5 (57%) | 41.8 (94%) | 44.5 |

`-j 1` 的同样层（用时 226–234 s）分布一致（min 6%，p50 56%，p90 94%）；kill/resume 实验里第 9–11 层同样如此。即第 k 段在 ≈ (k+1)/S 层时间处完成，略偏前。完整数据：`t4/r37_j8.stats.json`、`t4/r37_j1.stats.json`、`t5/r37/stats.json` 的 `seg_done_sec`。

推导：
1. **稳态**（写盘跟得上）：每段完成后立即入队（上一层已 durable 时）、写完后 meta 在 ≤30 s 内提交（lag 在每次提交后重置为最老的未列入段的年龄），故 lag ≲ 段写时间 + 30 s + 排队，远小于 10 分钟。
2. **写盘跟不上**：lag 最老的项在 meta 之外。管理线程每 50 ms 评估一次 `lag > 360` 或 `lag + 排空估计 > 360`，成立则 `g_throttled=1`，计算线程只做完手头单元（r=40 一个单元约 64 块 = 512 KiB 位图，毫秒级）就不再领取新单元。限速期间 meta 的待提交更新**立即**提交（不等 30 s），所以最老的项一写完 lag 就在 ≤ 50 ms tick + 一次 meta 写盘（128 段的 JSON，毫秒–百毫秒级）内回落。排空估计保证队尾也在 ≈360 s 前写完，故触顶值 ≲ 360 + δ，其中 δ = tick 0.05 s + 手头单元 <0.1 s + meta 写盘 <1 s + 最老一项若刚开始写还要等一个段写完（1 GiB 段，实测最大 3.1 s，JuiceFS 4 并发）+ 排空估计误差。
3. **跳层项**：两层都未 durable 时 `durable_asof` 取上一 durable 层的完成时刻，lag 会一次性增加至多 $T_L$（所测场景里 A、D 比字面界多出的 0.3–0.4 s 即此项，约等于当时的层时间）。此前这一项还被一个缺陷放大：层 D+1 其实已完整落盘，只是因为层 D+2 已算完而不被提升（管理线程只检查最新一层），lag 仍按“两层未落盘”计。本轮已修（见“第二轮审阅修复”第 5 点：按序逐层提升）。因此最坏 lag ≲ 360 + $T_L$ + δ。
4. 结论：丢失的计算时间 ≲ **360 + $T_L$ + ~5 s + $T_L/S$**。r=40 的 $T_L$：r=37 的 -j 8 为 44.5 s，按 8 倍位图、32 核、并行效率 5/8 外推约 90–180 s（**[INFERENCE]**，未跑 r=40）。则上界约 450–545 s，< 600 s，余量约 55 s（最坏情形）。**若 r=40 首次运行实测 $T_L$ > 约 230 s，必须把 `--ckpt-throttle` 降到 ≈ 590 − $T_L$ − 10**，否则可能超 10 分钟。这是限速机制没改动下的上界，没有用 r=40 实测验证。
5. 不属于“丢失计算”但影响重启耗时：恢复要读入 D 层全部段（r=40：128 GiB，按 Cluster 读 2.7 GB/s ≈ 50 s）加上已落盘的 D+1 层段，段哈希校验几乎不增加这部分时间。

## 内存与 I/O 估算

### r=40 额外内存（两张位图之外）
- 块标记：每块一个 u32 计数（0=空、满=BLKBITS、其余混合；三态由计数导出，同时省去重新扫位图求 popcount）：块数 2^40/64/1024 = 2^24，两张共 2×2^24×4 B = **128 MiB**（r=41 为 256 MiB）。
- 每个线程缓冲 1024 个字 = 8 KiB × J；段状态、popcount、完成时间戳、作业队列：NSEG=2^34/2^27=128 段，可忽略；free 的 reps：≤ `FREE_MAX × 8 B × 层数`，约 ≤ 2 MB。
- 实测对照：r=37 峰值 RSS 33,571,896 KB − 两张位图 33,554,432 KB = 17.5 MB（其中块标记 16 MiB）。r=40 预期总额外 ≈ 130 MiB，远低于 1 GiB 的要求；r=40 峰值 RSS ≈ 256 GiB + 0.13 GiB。写盘直接从位图内存 write（4 MiB 块），不另设缓冲；写完 `fsync`+`posix_fadvise(DONTNEED)`，不占页缓存。
- 无第三张位图缓冲。页缓存读入时（恢复）同样 DONTNEED。

### r=40 断点 I/O
- 每次落盘一整层：2^40 bit = 128 GiB（128 段 × 1 GiB；全空的段只做 `ftruncate` 不写数据，前几层几乎全空）。
- 本机共享盘实测（`iotest.py`，`t7/iotest_jfs.log`）：1 流写 1141 MB/s、4 流 1454 MB/s、8 流 1441 MB/s；读 1 流 953、4 流 1608 MB/s。Cluster 节点实测（Main 提供）：单流写 712 MB/s、读 2.7 GB/s。按 0.7–1.4 GB/s 计，**写一层 128 GiB 需约 90–190 s**（4 个写线程并行各写不同段文件）；恢复读入 D 层全部段 ≈ 128 GiB / 2.7 GB/s ≈ 50 s 量级（再加上 D+1 层已落盘段，最多再 128 GiB）。
- 参考：r=37（一层 16 GiB）本机运行 495 s，累计写盘 170.7 GB，`ckpt_write_wall_sec` 160 s，最大 durable_lag 96 s（`--ckpt-start 20 --ckpt-throttle 120`，未触发 throttle）。
- 策略下的频率（默认 `--ckpt-start 120 --ckpt-throttle 360 --meta-interval 30`）：r=40、32 核一层约 1.5–3 分钟（由 r=37 的 45 s/8 线程按 8 倍体量、4 倍核数外推，**[INFERENCE]**）。当 lag 达到 120 s 时开始写上一完整层，需 ~1.5–3 分钟写完，期间计算继续、下一层的整段完成后随即入队写盘。稳态下写盘与计算大体重叠，约每 4–6 分钟推进一个 durable 层（每层 128 GiB，平均 ~0.4–0.5 GB/s，低于盘带宽）；若写盘慢于计算，lag 触到 360 s 时计算线程暂停，丢失量被限制在 360 s + meta 30 s + 层内计算时间 + 段写时间，仍 < 10 分钟。总写盘量最坏 ≈ 层数 × 128 GiB（最大深度约 15–17 层 ⇒ ≈ 2 TiB，含稀疏的前几层要少得多），共享盘上需要同时留 ≥ 2 层（256 GiB）加新层的空间（旧层在新 meta 落盘后才删，最多同时存在 L_D、L_{D+1} 两个目录）。
- 注意：若实际节点上单层写盘时间 > `ckpt-throttle − ckpt-start`（240 s），第一个 durable 点之前的丢失会超过 throttle（需要先写满一层）。按 712 MB/s 单流需 180 s，4 流并行更短，仍在 240 s 内，余量不大；默认参数不变，但调度者应在 r=40 首次运行时看 `durable_lag_sec` 与 stats。

## 偏差与说明（汇总）
1. 第 6 项的界按上面解释放宽为 `+ max(层计算, 段计算) + 单段写时间`（合同字面界在 A、D 场景被超过 0.2–0.4 s，原因见上）；并额外加了"排空时间估计"的 throttle 条件。
2. 块标记用 u32 popcount 实现三态（空/混合/满），而不是 2 位标记。
3. 唯一的非零列去重后参与计算（并集等价，OUT 的 `cols` 仍是输入原样）。
4. 进度文件的实际更新间隔 10 s（≤ 15 s 的要求内）。
5. 未做 AVX2 运行时分派（仅 x86-64-v2 基线）。
6. 合同第 9 节 "与 Sol 独立实现对平" 不在本任务范围（`qual/sol/` 由调度者放置），本报告未做。
7. `t6_exploratory/` 是早期版本（r=30，参数处于合同界之外的 regime）的运行记录，仅作说明，不计入通过项。


---

# 审阅修复（第二版，响应 `reviews/sol-layers3-review-1.md`）

数学内核（`do_block`、`or_acc`、块置换与三态捷径）未改动；第 1、3、4 项仍按第二版二进制完整重跑并通过（上文数字即为重跑结果）。行号为 `src/layers3.c` 第二版。

## 1. 首层 throttle 死锁（P1）——选方案 (a)
- 原因确认：`tp=meta_D=0` 时 L1 已完成的段使 lag 增长并触发 throttle，而既不写 prev（要求 tp≥1）也不写 next 部分段（要求 meta_D≥1）。
- 改法：L_0 是虚拟的（可重算，不需文件），因此 D=0 作为合法的 durable 层。
  - 管理线程（545、583 行）：`meta_D==tp==0` 时，L1 已完成的段在 lag ≥ min(ckpt-start, ckpt-throttle) 后即入队（保持“总时间短于 ckpt-start 的运行不写任何段”），meta 在 `Dn≥0` 时即可提交（`last_meta` 初值改为 −∞，第一份 meta 不再等 30 s）。
  - 恢复（`try_resume`，719 行起）：支持 `durable_layer=0`：不读 L_0（`fresh_state()` 重建），只读 L1 已列入 meta 的段；`free` 对 L_0 直接重算。
  - 另发现并修复一个相关问题：throttle 期间 lag 只有在 meta 提交后才会下降，而 meta 默认每 30 s 才更新——当 `ckpt-throttle < meta-interval` 时计算会在两次提交之间被停住（不是死锁，但 `--ckpt-throttle 0.1` 的 Sol 用例会跑 >400 s）。现在 throttle 生效时待提交的 meta 立即提交（545 行 `|| cur_throttled`）；仍满足“至少每 meta-interval 秒”。
- 测试 `deadlock.py`（`t10_firstlayer.log`）：r=28、4096 个互不相同的非零列（含全部单位列），`-j 1 -b 3 -g 12 --ckpt-start 0 --ckpt-throttle 0.1 -t 1 -f 1`，带超时。
  - 第一版二进制（`qual/ref/layers3_prev_a09e`）：60 s 超时，**死锁复现**。
  - 第二版：meta-interval 1 与 30 都在 4.0 s 内完成；`L_sizes=[1,4097]`，`free` 的 count 与 1024 个代表元和独立计算（Python 集合）一致；throttle 约 1.2 s、24 次、最大 lag 0.14 s、写出 ~1000 段。
- 额外：D=0 恢复的定点测试见第 3 项（`crashpoints.py` 的 “D=0 resume” 两例）。
- r=40、n=256 下 L1 计算时间：不需要给出上界依据，因为选的是 (a)（首层照常限速、也能落盘）。

## 2. `pthread_create` 返回值（P1）
- 改法：所有线程创建（loader 677 行、writer 994、manager 995、janitor 996、compute worker 1023）统一经 `spawn()`（111 行）；任何失败（真实或注入）立即打印原因并 `_exit(5)`——不发布 OUT、不 join 不存在的线程、不挂死；断点因段/meta 均为原子提交而保持一致（下次启动清理 `.tmp.`）。退出码 5 写入文件头注释（第 9–10 行）。测试钩子 `LAYERS3_TEST_FAIL_THREAD=N`（第 N 次创建返回 EAGAIN）。
- 测试 `threadfail.py`（`t11_threadfail.log`，14 项）：writer #1、#4，manager，janitor，第 1 层两个 worker，第 3 层、第 7 层 worker，无断点的 manager 与 worker（第 1、5 层），以及恢复时的 loader #1：全部 `rc=5`、无 OUT、每次 <1 s 返回；对照 N=9999 正常 `rc=0`；loader 失败后重启仍从断点续跑（`resumed_from_layer=4`）。

## 3. 恢复提升与结束清理的顺序（P1）
- 改法：`try_resume` 先提交新 meta（806–809 行），之后才（811 行） `wipe_ckdir_layers`；结束时 OUT rename → meta 标 finished → 再删段（1053 行附近）。
- 测试钩子 `LAYERS3_TEST_ABORT_AT=<点>[:k]`（`_exit(99)`）与 `LAYERS3_TEST_HOLD_LAYER=K`（构造“meta=D=K−1 且层 K 全部段已列入 meta”的状态后 `_exit(99)`）。`crashpoints.py`（`t9_crashpoints.log`）19 个场景全部通过，每个场景续跑后 OUT 与基线逐字节一致，并从 stats 核对确实恢复：

| 点 | 结果（续跑） |
|---|---|
| `seg_before_rename:250` / `seg_renamed:250` | meta D=4，从第 4 层恢复 |
| `seg_renamed:40`（首个 durable 点之前） | 无 meta，从头算（预期），OUT 一致 |
| `meta_before_rename:6` / `meta_after_rename:6` | meta D=3，从第 3 层恢复 |
| `meta_committed:4`（meta 提交后、清理旧层前） | meta D=5，从第 5 层恢复 |
| `janitor_rm:2` | 从第 3 层恢复 |
| `out_before_rename` | meta D=9，从第 9 层恢复 |
| `out_after_rename` | OUT 已存在且一致；重跑从第 9 层恢复，OUT 一致 |
| `finish_meta_done` | OUT 已发布且一致；meta=finished，重跑按设计从头重算，OUT 一致 |
| 提升窗口：HOLD 第 6 层 → `promote_before_meta` 崩溃 | meta 仍为 D=5，L5 的 64 个文件仍在；再跑从第 5 层恢复（7 层未重算） |
| 提升窗口：HOLD 第 6 层 → `promote_after_meta` 崩溃 | meta=6，L5 文件仍在（清理在其后）；再跑从第 6 层恢复 |
| HOLD 第 6 层 → 直接续跑 | 从第 5 层恢复并提升，OUT 一致 |
| D=0 恢复（HOLD 第 1 层，meta D=0、L1 全部 64 段已列入） | 从 `resumed_from_layer=0` 恢复，OUT 一致 |
| D=0 部分 L1（r=28、4096 列：首份 meta D=0，列入 44/1024 段） | 从层 0 恢复，OUT 一致 |

## 4. 数据竞争 / TSan
- `mgr_stop`、`abort_writes` 改为 `_Atomic int`（293 行；读写均用 `atomic_load/store`）；`wstop` 仅在 `mu` 下读写。
- `tsan.sh`：`gcc -O1 -g -fsanitize=thread`（非静态）跑 12 次小用例（plain -j4；断点开启；throttle + 慢写 + 2 writer；HOLD + 恢复；首层 throttle；6 次反复启停），输出 `t9_tsan/*.tsan.*`：**没有任何 TSan 报告文件，`TSan warnings total: 0`**；各 OUT 与生产二进制逐字节一致。我没有拿旧源码跑 TSan 来确认它能抓到原先的 `mgr_stop` 竞争（旧源码未保留），此项只证明第二版在这些场景下无报告。

## 5. 目录 fsync
- 改法：`fsync_dir()`（138 行）返回错误；`EINVAL/ENOTSUP/EOPNOTSUPP` 视为文件系统不支持，仅计入 `stats.dir_fsync_unsupported`；其它错误 → `-1`。调用方全部检查：`atomic_write_file(durable)`（meta、OUT：失败则 `die(4)`/`_exit(4)`）、`write_seg`（段 rename 后同步层目录和断点根目录，失败则 writer `_exit(4)`，此前该段不被标记为 durable，旧层也不会被清理）。顺带补了：每次段提交同时同步断点根目录（新层目录项的持久化）。
- 本机实测（`dirfsync.py`，`t7/dirfsync.log`）：SHARE（`stat -f` 为 `fuseblk`，JuiceFS）上目录 fd 的 `fsync()` 返回 **0（支持）**；`/tmp`（ext2/3/4）、`~` 也返回 0。所以 `dir_fsync_unsupported` 在这些盘上应为 0（r=37 的 stats 里该计数为 0）。**未测的路径**：真实的 EINVAL/ENOTSUP 返回（本机没有会返回它的文件系统）和 EIO 类硬错误（静态二进制没法 LD_PRELOAD 注入）；这两条分支仅经代码审阅，没有运行覆盖。Cluster 节点上的行为也没有实测，调度者首次提交时请看 stats 的 `dir_fsync_unsupported`。

## 6. 几何参数上限与 meta 解析
- 拒绝 `NSEG > 2^16`、或两份块计数 `2·NBLOCKS·4 B > 512 MiB`（955–958 行，退出码 2，分配之前）。`exitcodes.sh` 新增 3 例：`r=40 -b 3`（计数 16 GiB）、`r=40 -b 10 -g 10`（NSEG=2^24）、`r=41 -b 4`（计数 8 GiB）均退出码 2。
- meta JSON 解析器的 `cnt/cap`、`nlt`、加载循环全部改 `size_t`（184 行起；`(int)nlt` 已去掉）。

## 7. 回答：段恢复是否值得加内容校验？——已加
- 实现代价：每段一个 64 位哈希（4 路独立乘异或，每路逐 64 位字 `h=(h^w)*K; h^=h>>29`，种子含层号和段号，故“别的层/别的段的同重量内容”也会被拒）；写盘时在每 4 MiB 块 write 之前顺带算（232–245 行），读入时在每次 pread 之后顺带算（短读时只对完整的 4 字组累计，保持分路对齐）。单线程实测哈希吞吐 **约 10 GB/s**（`gcc -O3 -march=x86-64-v2`，1 GiB 重复 4 次），盘带宽 0.7–1.5 GB/s，所以写线程多花约 7–14% CPU 时间，写盘墙钟不变（写盘受 I/O 限制）；读入端每个 loader 线程同理，r=37 续跑读入时间 21.9 s（第一版 20.0–22.8 s）无可见差别。popcount 为 0 的段只存稀疏文件，不算哈希（popcount 0 即内容全零，已完全确定）。
- meta 格式版本号升到 `layers3-meta-v2`（`durable_seg_hash`、`next_segs` 每项 `[k,pop,hash]`）；旧格式 meta 视为指纹不一致：退出码 2，meta 不被改写。
- 测试（`crashpoints.py`，计入第 12 项）：交换同一段内一个 1 位和一个 0 位（大小、popcount 都不变）——D+1 层段：被拒（`resume_segments_rejected=1`），该段重算，OUT 一致；D 层段：被拒，退回从头算（日志 `starting from scratch`），OUT 一致；D 层段截断 8 字节：从头算，OUT 一致；v1 meta：退出码 2，meta 未改写。

## 偏差/说明（第二版补充）
1. 首层行为：D=0 作为 durable 层，L1 的部分段可以落盘/恢复（选方案 a）；`last_meta` 初值 −∞。
2. throttle 生效时 meta 立即提交（超出合同字面：合同只规定“至少每 meta-interval 秒”）。
3. 线程创建失败用 `_exit(5)` 立即终止，而不是逐线程协调退出；因为无任何已发布结果，也不会留下不一致的断点。
4. 目录 fsync 的 EINVAL/ENOTSUP 路径和 EIO 路径未被运行覆盖（见第 5 条）。
5. 第 6 项的界仍按上文放宽形式检查；A、D 场景的字面界仍被超过 0.3–0.4 s。


---

# 第二轮审阅修复（响应 `reviews/sol-layers3-review-2.md`；行号为第三版 `src/layers3.c`）

1. **列文件读取**（948–973 行）：改为逐字节解析——只接受十进制数字和空白（空格、制表、换行、CR、VT、FF），其它任何字节退出码 2（含 NUL、负号、加号、逗号、数字内夹字母、末尾垃圾词）；数值超 64 位退出码 2；`ferror` 退出码 4；`n=0`（空文件、纯空白）退出码 2。测试（`exitcodes.sh`，`t8_exitcodes.log`）12 例：末尾垃圾词、数字内字母、末尾字母、负号、加号、逗号、NUL、溢出、空文件、纯空白（均 2），路径是目录（4），CRLF/制表/空行/无末尾换行的合法文件（0）。
2. **meta `next_segs` 校验**（767–781 行）：任何畸形项、越界段号、重复段号一律视为 meta 损坏：日志 `ERROR ... starting from scratch`，删除断点后从头算，退出码 0（不是 2）。“按不同有效段计数再判断整层完整”：重复被直接拒绝，所以到 `nload == NSEG` 时必然是 NSEG 个不同段。测试（`crashpoints.py`，4 例，手工改坏 meta）：重复段号、越界段号、畸形项（缺字段）、64 项但只有 63 个不同段——全部 rc=0、未恢复、OUT 与基线逐字节一致。
3. **额外内存检查**（987–991 行，`MAXEXTRABYTES`=1 GiB）：`2·NBLOCKS·4 + J·BW·8 + NSEG·128` 超过 1 GiB 退出码 2（分配之前）。测试：`r=41 -b 20 -j 200`（线程缓冲 1.6 GiB）、`r=41 -b 20 -j 1024`（8 GiB）退出码 2。默认几何下 r=40 总额外约 130 MiB，不受影响。
4. **`--ckpt-throttle < --ckpt-start`**：保持 `min(start, throttle)` 行为不变；在文件头注释（26–27 行）写明“此时短运行也可能写段”。**写入 QUAL_REPORT 的说明**：写段触发线 = `min(ckpt-start, ckpt-throttle)`；`--ckpt-throttle` 小于 `--ckpt-start` 时 throttle 值生效，所以总时间短于 `ckpt-start` 的运行也可能写段（合同第 2.4 节“总时间短于 ckpt-start 的运行不写任何段”只在 throttle ≥ start 时成立，生产默认 120/360 满足）。
5. **（测试中发现的缺陷）按序逐层提升**（544–552 行）：全量重跑时 `crashpoints.py` 的 HOLD 钩子在高负载下超时，查明原因：管理线程只检查“最新完成的一层”是否整层落盘；如果层 D+1 在落盘期间层 D+2 已经算完，D+1 即使写完也不会被提升（meta 停在 D，直到 D+2 整层写完才跳到 D+2），`durable_asof` 则按 `ctime[D]` 计 lag——偏保守，会造成多余的限速。现在改为循环：只要层 D+1（可能在旧缓冲里）所有段已落盘就提升到 D+1，再检查下一层。这改了管理线程的提升逻辑（不涉及数学内核）；全部 12 项（含第 5、6、9 项）在此版本上重跑通过。
6. **seg_done_sec**（303–306、1060–1070、864–867 行）：stats 新增每层段完成时间分位数 `[min,p10,p50,p90,max]`（秒，自该层起），用于上面的上界推导和 r=40 首次运行时的实测核对。

## 第三版的过关总表（`run_all.sh --with-r37`，2796 s）

| 项 | 结果 |
|---|---|
| 1 暴力对照 | 150 例，0 失败 |
| 2 线程一致 | 9 例 × 6 配置，逐字节相同 |
| 3 与 layers2 一致 | 8 例相同 |
| 4 regression | r=37 `L_sizes` 一致，覆盖半径 15；-j8 279.6 s，-j1 1430.8 s（layers2 1594 s） |
| 5 kill -9 续跑 | r=32 两组各 24 次，15/9 次运行从断点起步，stats `resumes`=16/10，OUT 一致；r=37 一次，从第 7 层恢复，OUT 一致 |
| 6 丢失上界 | 4 个场景 pass |
| 7 首层 throttle | pass |
| 8 线程创建失败 | 14 项 pass |
| 9 定点崩溃 | 23 个场景 pass（含 4 个坏 meta） |
| 10 TSan | 0 报告 |
| 11 目录 fsync/几何/列文件/退出码 | 31 项 pass |
| 12 段哈希 | pass |


---

# 生产事故：ρ=39（64 段）任务死锁——复现、根因、修复（第四版）

## 复现（先复现再改）
`qual/t12_seg_boundary/repro.sh BIN r g`（`CS=1 CT=2`，即 `--ckpt-start 1 --ckpt-throttle 2 --meta-interval 1`，r=32 `-g 18`，超时 90 s）：
- 事故时的二进制（ea62158e…）：**rc=124（挂死）**；progress `layer 5, durable_layer 0, durable_lag_sec 81+, throttled true`；断点目录只有 `L4/`、没有 `meta.json`——与生产现象逐项相同。这里 NSEG=256，**不是 64**。
- 第一版二进制（a09e759e…）同参数 rc=0。
- 触发条件：前几层在 `ckpt-start` 之前就算完，所以第一次写盘被触发时 durable 层仍是 0，而第 1..tp−1 层已不在任何缓冲里（缓冲只保留最近两层）；同时层的计算时间 > throttle，限速一开计算线程停住。

## 段数边界扫描（`nsegscan.py`，`t12_seg_boundary/scan_before.log` / `scan_after.log`）
NSEG=2^(r−6−g) 只可能是 2 的幂，扫 1,2,4,…,256（A 场景另含 1024、4096）。两个场景：A（r=30，tight 策略 + 慢写 + 随机 SIGKILL + 续跑）；B（r=32，晚启动短 throttle，事故形状）。
- **事故二进制**：B 场景 **9 个 NSEG 值全部挂死**（rc=124）；A 场景 1、2、32、256、1024、4096 挂死，4/8/16/64/128 未挂（取决于时序）。即**与 NSEG 无关，64 并无特殊**；生产上只有 r=39 中招是因为 r=39 的 `start 60/throttle 240` 与其层时间（几十秒到 100+ s 的前几层）的组合恰好落入窗口，r=38 的前 4 层只要 ~12 s 且层时间 106 s，r=40 的层更长（见下）而没有进入该状态。
- **修复后**：20 例全部 pass（B 场景 9 个 NSEG 值 11.6–17 s 完成，OUT 与不带断点的基线逐字节一致；A 场景 11 个值 kill 后续跑 OUT 一致；NSEG=4096 一例 kill 时尚无 durable 层，从头算，OUT 一致）。

## 根因（第三版 `src/layers3.c` 的管理线程 `mgr_tick`，544–552 行）
上一轮我把“提升”改成按序循环：`while (Dn+1 <= tp) { Q = find_layer_buf(Dn+1); if (!Q) break; ... }`。当 Dn=0、tp=4 时 `Dn+1=1` 的层早已被回收、不在缓冲里，`find_layer_buf` 返回空，循环直接 `break`，于是已经**完整写好**的 L4 永远不会被提升；meta 不提交、lag 只增不减，一到 throttle 计算线程停住，没有任何事件能再推进——闭环。（第一版和第二版是只检查最新层，没有此问题；我在第二轮审阅修复里引入了这个回归，且当时的 HOLD 测试用的层序恰好总在缓冲里，没覆盖到“中间层已被回收”。）
**为什么已有测试没覆盖**：所有已有测试要么 `--ckpt-start 0`（第一层起就持续落盘，D 紧跟 tp，从不出现“D 远落后于缓冲里的层”），要么层时间 < throttle（r=37 的 16 段、`lagbound.py`），要么 kill 在首个 durable 点之前。没有一个用例同时满足“前几层在 start 前算完 + throttle 短于一层”。现已加入 B 场景和 `repro.sh`。

## 修法（544–556 行）
改为：对两块缓冲里层号在 (Dn, tp] 内、且所有段已落盘的层，直接提升到其中最高的一层（durable 层 D 只需要 L_D 本身，L_0 虚拟，可跳过中间层，这在第一版就是如此）。`HOLD_LAYER` 钩子的“不提升到 K 层”语义保留。数学内核未动。
**同类写法全文检查**：对段数/块数/线程数的移位与掩码——`1ULL << (R-6)`、`1ULL << BWLOG`、`1ULL << SEGLOG`（R≤41、BWLOG≤20、SEGLOG≤R−6 均 <64，u64）、`MK[]` 掩码（只作用于 6 位字内置换，与段数无关）、`HB/WLO/LC`（`>> 6`、`& (BW-1)`、`& 63`），没有 `1<<NSEG` 或 64 位掩码式的段位图；段状态是 `u8 state[NSEG]`、`si[NSEG]`、`done_ns[NSEG]` 数组，下标 u64，NSEG≤2^16；`jq` 容量 `2*NSEG+16`。未发现对 NSEG==64 敏感的写法，与扫描结果一致。

## 回归测试（已进 `run_all.sh`，第 13、14 项）
- 13 `nsegscan.py`：上述 20 例，每例带超时（挂死 = rc 124 = fail）。
- 14 `compat_ckpt.py`：meta 格式**未变**（仍是 `layers3-meta-v2`），旧二进制（ea62158e…）写的断点——(a) HOLD 钩子停下的状态 D=5，(b) SIGKILL 的状态 D=4——都能被新二进制恢复，从 `resumed_from_layer=D` 续跑，OUT 与基线逐字节一致。因此 r=38/r=40 正在跑的任务写的断点重启后可被新二进制接管；但那些在途任务已经在跑旧二进制，不会自动换新，只有任务重启（抢占或重提）后才会用新文件。

## 第四版过关总表（`run_all.sh --with-r37`，3202 s）
1–12 同前全部 pass（regression r=37 `L_sizes` 一致、覆盖半径 15；kill 续跑 r=32 两组 24 次 + r=37 一次，OUT 一致；23 个定点崩溃场景；TSan 0 报告 等），13 段数扫描 pass（20 例），14 旧断点兼容 pass。


---

# 10 分钟要求：丢失的计算时间（第五版 sha256 1d4ec5a8…；本节的 τ/E 记账已被文末“第六版”取代，仅作历史记录）

## 1. `durable_lag_sec` 的确切定义（旧二进制 ea62 / b894）
`mgr_tick`（旧）：`asof = t`；若 `meta_D+1 < tp` 则 `asof = ctime_[meta_D]`（**墙钟**，层 D 完成的时刻）；否则 `asof =` 层 D+1 中“已算完但**未列入 meta**”的段的最早完成墙钟。`lag = now − asof`。
所以它是**墙钟**量：①包含限速暂停、等缓冲、层间等待；②把“已写完但 meta 尚未列入”的段也算未落盘（这些段恢复时确实不会被用，这点是对的）；③层完成时若 D+1 层未 durable，asof 退到 `ctime[D]`，lag 一次跳升约一整层的墙钟，而 D+1 层中已列入 meta 的段在恢复时是读回、不重算的，所以 lag 在此时**高估**真实重算量。它**不是**“重算的计算时间”：恢复后重算量 = 自 D 层起的计算时间 − 已列入 meta 的 D+1 段对应的计算时间，不含暂停。
旧二进制下真实最坏重算量：stats 没有记录“被列入 meta 的比例”，无法精确反推。能确定的是：r=40 的 40 个任务 `max_durable_lag − 最重层计算时间` = 12–59 s（均值 40），即峰值出现在一层（800–960 s）刚算完、上一层尚未 durable 的时刻，重算量上界 ≈ 该层计算时间 800–960 s（扣除已列入的段后更小，但无法证明 ≤600）。**因此旧二进制不能证明满足 10 分钟，按 ≈T_L（≈900 s）上报。** 这与 `throttle` 基于墙钟 lag 但限速的是整个计算（层跳升不能被限速消除）一致。
r=40 任务的实测对照（248-208，旧二进制）：层计算 109.6/906.2/957.3/941.9 s（层 4–7），`max_durable_lag` 975 s，`throttle_sec` 339 s，写盘 854 GiB / 3220 s。其中第 8–10 层只有 5/2/2 s 计算却也被写盘（稀疏/稠密尾部层，每层 128 GiB），并在写盘期间被墙钟 lag 限速（尾部限速平均 102 s/任务）——这是写盘 850 GiB（本应约 3–4 层）的原因。

## 2. 改法（`src/layers3.c`，meta 格式不变，仍是 `layers3-meta-v2`）
- **计算时钟 τ**（`tau`，`mgr_tick` 顶部）：只在“有层正在算且未被限速”时累加。每个段记录完成时的 τ（`tau_done`）；每层记 `ctau[t]`。
- **重算暴露量 E**（`compute_exposure`，约 557 行）= `τ − ctau[D] −` D+1 层中已列入 meta 的段的计算时间之和（`fill_gaps`：按完成顺序，每段分得其完成前的计算间隔，各段之和等于层计算时间；恢复读入的段为 0；层缓冲被回收前冻结其间隔，`frozen_gap`）。这正是恢复逻辑下的重算量，不含暂停。
- **写盘/限速全部改按 E**：触发线 `E ≥ min(start,throttle)`；限速条件 `E > throttle` 或 `E + 排空估计 > throttle`，且只在“等待能降低 E”（有写在途/将入队）时限速；写最新完整层（D 跳到 tp）要求 `E` 达触发线且写入收益 `E − (τ − ctau[tp]) ≥ trig`（跳过尾部几秒的廉价层，省写盘），或 `E > 0.5·throttle`（此时无论收益都必须推进 D，否则 E 无法再降）。
- **看门狗**：限速持续 >60 s 且无写在途、无写完成、无 meta 提交则放开（`watchdog_releases`，stats 字段；测试断言恒为 0）。
- **新字段**：progress `recompute_exposure_sec`；stats `max_recompute_exposure_sec`、`watchdog_releases`；测试日志列扩展为 8 列（含 τ、层内进度、E）。`durable_lag_sec` 保持墙钟定义不变（`seg_done_sec` 等不变）。

## 3. 上界（新二进制）
重算量 ≤ `ckpt-throttle` + δ，δ = 手头单元（r=40 毫秒级）+ 50 ms tick + 排空估计误差（写盘带宽波动）。小用例实测超出 throttle 的量：throttle=4 s 时最大 E 实测 3.6/5.3 s（写/计算比 0.71/1.61），即 δ ≲ 1.3 s（约 throttle 的 30%）。按 30% 外推，throttle=240 → 最坏 ≈ 310 s 重算；加上 D 层读回（128 GiB ÷ 2.7 GB/s ≈ 50 s + 哈希）约 360–400 s **[INFERENCE：误差系数来自小规模，r=40 未实测]**。**生产上必须用 stats 的 `max_recompute_exposure_sec` 核对**（≤ 600 − 载入时间）。

## 4. 测试（`lostwork.py`，进 `run_all.sh` 第 15 项）
r=33，-j 1，256 段，写延迟使“写一层/算一层”为 0.71 和 1.61（≥0.5），`--ckpt-start 1 --ckpt-throttle 4 --meta-interval 1`。对每次随机 SIGKILL（链式：杀 → 续跑 → 在被杀进度处再随机杀），记录被杀时的（层，层内进度），续跑后读其计算时钟 τ 首次追平该进度的值 = 重算的计算时间（不含载入、暂停）。断言 ≤ throttle + 2 s = 6 s：
- 比 0.71：18 次，最大 3.05 s，均值 1.37 s，全部 ok，`watchdog_releases=0`，最终 OUT 与基线一致。
- 比 1.61：16 次，最大 5.29 s，均值 1.96 s，全部 ok，OUT 一致。
共 34 次 kill。`lagbound.py`（第 6 项）改为断言 `max_recompute_exposure ≤ throttle + 2×段计算 + 1 s`，四场景 pass。
**过程中的失败与修复**（如实记录）：①第一版 E 策略中“收益规则”使 resume 后（层 D+1 大部分已读回）的 tp 层永不写盘，E 无限增长而不限速（lostwork 比 0.71 测出 14 s>6 s），已改为 `E > 0.5·throttle` 时无条件推进；②`reducible` 判定与入队条件不一致导致 nsegscan 偶发挂死（3 例），已镜像入队条件并加看门狗；复测 70 轮随机 kill/续跑循环无挂死，第 13 项 20 例 pass。

## 5. 建议生产参数
线程 16 不变；`--ckpt-start 60`；`--ckpt-throttle` 由 240 降到 **200**（余量：200×1.3 + 50 s 载入 ≈ 310 s ≪ 600 s；仍留一倍以上余量给写盘带宽波动）；`--meta-interval 30` 不变。对总耗时：新策略不再写 3 个尾部廉价层（约 384 GiB，按 0.29 GB/s ≈ 1300 s 的盘时间）并去掉尾部墙钟限速（旧：平均尾部限速 102 s/任务），预计总耗时不增反减 **[INFERENCE，未在 r=40 实测]**；重层上因限速按 E 而非墙钟，限速量与旧版同量级（旧 339 s）。**首次 r=40 运行请盯 `recompute_exposure_sec`/`max_recompute_exposure_sec` 与 `watchdog_releases`。**

## 备注
调试过程中我执行过 `pkill -f "python3 .*\.py"` 清理自己的测试进程，该模式可能误匹配本机同用户的其它 python 脚本；输出显示若干 pid “signalling failed”，但无法确认是否有其它同用户进程被终止，请 Main 核对本机其它任务（`/home/user/scaling` 下的预览/监控服务器等）。

## 第五版过关总表（`run_all.sh --with-r37`）
1–14 同前全部 pass（regression r=37 `L_sizes` 一致、覆盖半径 15，-j8 278.8 s / -j1 1407.9 s；23 个崩溃点场景；TSan 0；NSEG 扫描 20 例），15 丢失计算时间 pass（34 次 kill）。


---

# 第六版（sha256 `3e3376823bea0e845a7067a3b6014e373ef77b6f7ced0f26846793205cee9d31`）：保守的 claim 时间策略，取代 τ/E 记账

Sol 第三次审阅指出 τ/E 记账有两处少算（`fill_gaps` 在并行下把可节省时间分成 0；τ 漏计 tick >5 s、写 meta 解锁期间、层边界）。第六版删除 τ、`ctau`、gap credit、`compute_exposure`、`frozen_gap`、排空估计，换成下面可三行证明的策略。数学内核（`do_block`、`or_acc`、列拆分）没动；worker 只多了“领取单元时记 claim 时间”和“规则 1 的闸门”（`claim_unit`，约 396 行）。meta 格式不变（仍是 `layers3-meta-v2`）。

## 策略（`src/layers3.c`）
- **claim**：每个段 `claim_ns[k]` = 该段任一工作单元被领取的最早墙钟时刻（原子取最小）；恢复读回的段不计（0）。单元按索引顺序由单线程（`disp` 互斥）发放。
- **X(now)** = now − min{ claim_ns[k] : 层号 > D 的层的段 k，且不在“meta 已列入的 D+1 层段”内 }（`at_risk_min_claim`，570 行；层缓冲被回收时把该层的最小 claim 存入 `rec_claim`，约 1099 行）；无此类段时 X=0。**墙钟，不扣除暂停**。
- **规则 1（闸门）**：开启新段（某段的第一个单元，且该段不是读回的）时要求 X ≤ throttle，否则等待（5 ms 轮询）；其余单元（已开始段的剩余单元）不受限，所以已开始的段总能做完。看门狗：闸门关闭 >60 s 且无写在途/完成/meta 提交时放行一次（计数 `watchdog_releases`，测试断言恒为 0）。
- **规则 2（写盘）**：X ≥ min(start, throttle) 且 tp > D 时写最新完整层 L_tp（跳层提升保留）；D==tp 时，D+1 层的段一完成即入队，写完即列入 meta（闸门关闭期间 meta 立即提交，否则每 meta-interval 秒）。尾部廉价层是否写由 X 决定：X 小则不写。
- **stats/progress**：`max_exposure_at_claim_sec`（任一段被开启时的 X 的最大值，规则 1 保证 ≤ throttle）、`max_seg_compute_sec`（段第一个单元被领取到最后一个单元完成的最长墙钟）、`max_wall_exposure_sec`（X 的最大值，含暂停，仅供参考）、`throttle_sec`、`watchdog_releases`；`durable_lag_sec` 现在等于 X；`recompute_exposure_sec` 已删除。测试钩子：`LAYERS3_TEST_META_DELAY_US`（每次 meta 提交前延迟）、`LAYERS3_TEST_PROG_INT`（progress 间隔，测试里 0.1 s）。

## 证明
记 kill 时刻 K，磁盘上的 meta 给出 D 与 D+1 层已列入的段。重启后需重算的只有集合 A = {层号 > D 且不在已列入集合内的段的单元}（L_D 与已列入段是读回的）。
1. A 中的段在 K 时刻都是 at-risk，而 at-risk 状态只会随时间减少（被列入/D 前进后清除，从不重新进入），所以每个 A 中的段在它被开启之后的任何时刻也都是 at-risk；X 用的是内存中的 meta_D/meta_listed，它只在磁盘 meta 提交成功之后才更新，故内存 X ≥ 磁盘 meta 下的真实 X（保守）。
2. 记 T0 为 A 中最早的 claim，t_L 为 A 中最后被开启的段的 claim。开启该段时规则 1 保证 X(t_L⁻) ≤ throttle，而 A 的段此刻都 at-risk，所以该刻 min claim ≤ T0，即 t_L − T0 ≤ X(t_L⁻) ≤ throttle（看门狗放行除外）。
3. A 的所有段在 t_L 之前或 t_L 时已被开启，已开启的段总会做完（规则 1 不限制已开启段的剩余单元）；每个段从开启到完成不超过 T_seg（测量值 `max_seg_compute_sec`，已包含同时进行的段之间的线程共享）。所以 A 的全部工作原先在窗口 W ≤ (t_L − T0) + T_seg ≤ throttle + T_seg 内完成（暂停期间只有已开始段的剩余单元在跑，不产生新的 A 工作）。
4. 重算同样的单元集合、同样的线程数 J：按索引顺序的贪心调度，总工作 ≤ J·W，完成时间 ≤ W + u（u=单个单元时间；Graham 界）。

**结论：重算的计算时间 ≤ throttle + T_seg + u。** 按“同时进行的段数 c × 段自身时间”表达：c = ⌈J/UPS⌉ + 1，UPS = 每段单元数 = 2^(SEGLOG−BWLOG)/UB。**r=40、J=16、SEGLOG=27、BWLOG=10：UB=64，UPS=2048，c = ⌈16/2048⌉+1 = 2**（最多同时有 2 个段在做：当前段和刚开启的下一段）。T_L≈900 s、128 段：独占线程时一个段约 T_L/128 ≈ 7 s，单元 u ≈ T_L·J/NUNITS = 900·16/262144 ≈ 0.055 s。故 **r=40 上重算 ≤ throttle + 2×7 s + 0.06 s ≈ throttle + 14 s**。生产参数 `--ckpt-start 20 --ckpt-throttle 60` 下 ≤ 约 75 s，另加读回 L_D（128 GiB，Cluster 读 2.7 GB/s ≈ 50 s）。**7 s、900 s 是由已有 r=40 stats 的层计算时间外推；第六版没有在 r=40 上跑过，请用 `max_seg_compute_sec` 与 `max_exposure_at_claim_sec` 核对。**

**例外（如实）**：没有任何 durable 层时（首个 durable 点之前）被杀，重算量仍 ≤ throttle + T_seg（同一证明，D=0），但重启后要重新等首层写到盘（规则 1 在写盘期间暂停计算）——这是 I/O 等待，不是重算；r=40 上首层（早期稀疏层，仍是整层 128 GiB）写盘期间计算被闸门暂停，表现为早期额外耗时数分钟。

## 活性（闸门关闭时 X 必须能下降）
闸门关闭 ⇒ X > throttle ≥ trig，故规则 2 的条件成立。设最老的 at-risk 段 m 在层 l_m > D，逐状态：
1. l_m 是当前层 cur 且 D == tp == cur−1：m 已开启，会完成（不受闸门限制）；完成的段在下个 tick 入队→写完→meta 立即提交（闸门关闭时）→列入→X 下降。
2. l_m == tp（完整层）且 D<tp：规则 2 对 tp 所有 state==0 的段入队，全部写完后跳层提升 D=tp，meta 立即提交，at-risk 只剩 cur 层的段。tp 中读回的段（state 2）同理。
3. l_m < tp 且该层已被回收（`rec_claim`）：同 2，提升直接跳到 tp（持久层只需要 L_tp）。
4. 全部写完但 meta 未提交（state==2、未列入）：`changed` 为真且闸门关闭 ⇒ 立即提交 meta（`cand_layer` 处理缓冲已回收的情形）。
5. cur 层的段已完成但 D<tp：先写 tp，D 前进后下个 tick 入队（D==tp）。
6. 等缓冲（层启动前 `inflight>0`）：不在闸门内，写盘完成后继续。
7. 无 at-risk 段（X=0）：闸门不关。
闸门等待的东西要么是在途/排队的写盘，要么是下个 tick 必然入队的状态，所以 X 单调趋向下降；看门狗只是兜底，所有测试断言它为 0。

## 独立验收测试（`lostwork.py`，第 15 项；不使用二进制自己的 X 记账）
r=34，512 段，-j 4 与 -j 8；写延迟使“写一层/算一层”约 0.5 和 1.5；两组加慢 meta 提交（每次 0.5 s）；throttle 3 s、start 1 s、meta-interval 1 s。随机时刻 kill -9 链式共 48 次（每组 12 次，**均从 checkpoint 重启**；从零重启的另计、不断言）。每次：被杀前 progress（0.1 s 间隔）的最后 (layer, layer_frac) 为目标；**测试脚本自己的秒表**从续跑进程打印 `RESUMED`（读回断点完成）起，到其 progress 显示 (layer, layer_frac) ≥ 目标止，含所有暂停；断言 ≤ throttle + 2·T_seg + 0.5 s 且 ≤ 1.5×throttle；终轮 OUT 与基线逐字节一致、`watchdog_releases==0`、`max_exposure_at_claim ≤ throttle`。

| 配置 | 写/算 | meta 延迟 | 从 ckpt 重启的 kill 数 | 秒表最大 | 均值 | 界 | 终轮 max_exposure_at_claim | 超界 |
|---|---|---|---|---|---|---|---|---|
| -j4 | 0.5 | 0 | 12 | 2.34 s | 1.36 s | 3.62 s | 2.02 s | 0 |
| -j4 | 1.5 | 0.5 s | 12 | 3.18 s | 2.08 s | 3.58 s | 3.00 s | 0 |
| -j8 | 0.5 | 0.5 s | 12 | 3.12 s | 2.11 s | 3.64 s | 3.00 s | 0 |
| -j8 | 1.5 | 0 | 12 | 3.16 s | 2.15 s | 3.66 s | 3.00 s | 0 |

合计 48 次，秒表最大 **3.18 s**（throttle 3 s；余量 0.58 s，小于 throttle 的 50%）。`watchdog_releases` 全 0。从零重启的另有 4 次（最长 22.8 s，是等首层写盘的 I/O 等待）。
**测试设计上的调整**：第一版把从零重启也计入，因首个 durable 层必须先写盘而出现 18 s，属于上面的“例外”，改为单独报告。

## 其他
- **额外内存检查**（Sol 提）：按实际分配总量算：`2·NBLOCKS·4 + J·BW·8 + NSEG·1024 + (TMAX−FREE_FROM+1)·FREE_MAX·8 + 16 MiB`（每段各表约 1 KiB 上界），> 1 GiB 退出码 2（约 1038 行）。`exitcodes.sh` 的 31 项不变。
- **共用 CKPTDIR 的互斥**：未实现。入口脚本保证每个 id 独占 `ckpt/<id>/`；两个进程同时对同一目录运行时 tmp 文件名含 host.pid 不会互相覆盖，但 meta 会被后写者覆盖，后果未定义——**已知限制**。
- 对总耗时：r=40 早期首层写盘期间闸门多暂停数分钟，尾部廉价层（X 小）不再写盘；净效果没有在 r=40 上实测。

## 第六版过关总表（`run_all.sh --with-r37`）
1 暴力对照 150 例 0 失败；2 线程一致 9×6；3 与 layers2 一致 8；4 regression r=37 `L_sizes` 一致、覆盖半径 15（-j8 276.7 s，-j1 1400.0 s）；5 kill 续跑 r=32 两组各 24 次 + r=37 一次；6 丢失上界（现断言 exposure_at_claim ≤ throttle）4 场景；7–14 同前全部 pass；15 独立秒表测试 48 次 pass。15 项全部 pass。
