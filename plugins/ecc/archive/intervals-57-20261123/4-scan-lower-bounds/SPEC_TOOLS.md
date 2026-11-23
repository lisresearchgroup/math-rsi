# 工具规格（调度者定稿，2026-11-22）

本文件是三个实现任务和 Sol 独立实现的共同合同。上位说明是同目录 `SESSION_PROMPT.md`。

## 0. 路径

| 名字 | 路径 |
|---|---|
| CASE | `/home/user/math/aris4math_v2/cases/_scan-onestep` |
| SHARE | `/shared/scan-onestep`（Cluster 容器内挂载为 `/work`） |

只写 CASE 和 SHARE。`cases/72-36`、其它 case、`math-rsi/` 只读。`~/.cluster/config` 的内容不得出现在任何输出、日志、文件里。

CASE 内目录：`src/`（C 源码）、`bin/`（本机构建产物）、`tools/`（取矩阵与核对脚本）、`matrices/`、`qual/`（过关证据）、`sched/`（调度、打包、汇总）、`dash/`（看板）、`results/`、`hits/`。

SHARE 内目录：

```
bin/layers3            静态可执行文件
bin/run_pack.sh        Cluster 任务入口
H/<id>.cols            校验矩阵列整数（见 1）
packs/<pack>.tsv       每行: id<TAB>rho<TAB>tmax<TAB>free_from
raw/<id>.json          layers3 的结果（确定性，见 2.3）
raw/<id>.stats.json    计时等非确定性信息
ckpt/<id>/             断点
progress/<id>.json     心跳（见 2.5）
logs/<pack>/           入口脚本日志
done/<pack>.DONE       该包全部 id 都有 raw 结果
```

`id`：第一轮为 `<n0>-<k0>`（如 `135-98`）；第二轮变体为 `<n0>-<k0>.<tag>`，tag 只含 `[A-Za-z0-9_]`。

## 1. 数据约定

- 校验矩阵 H 为 ρ×n，GF(2)，秩 ρ。**列整数**：第 j 列的整数 `c_j = Σ_i H[i][j]·2^i`，i 从 0 起为行号。
- `.cols` 文件：n 个十进制列整数，空白分隔，按坐标顺序 j=0..n-1。
- 伴随式 v 是 `[0, 2^ρ)` 的整数；位图中 v 位于第 `v>>6` 个 64 位字的第 `v&63` 位。

## 2. layers3（任务 A）

精确分层：`L_0={0}`，`L_t = L_{t-1} ∪ ⋃_j (L_{t-1} ⊕ c_j)`。算到 `t=tmax` 或 `L_t` 填满为止。

起点是 `cases/72-36/work/v6/route-loop/PT3/layers2.c`（复制到 `src/` 再改，不改原件）。原件注释写 r≤37，代码判 r≤38；全部下标已是 `uint64_t`，这个上限来自当时本机 61 GiB 内存放不下两张 2^38 位的位图，不是算法限制。新程序支持 `10 ≤ r ≤ 41`，`n ≤ 4096`，`tmax ≤ 250`。

### 2.1 命令行

```
layers3 -r R -t TMAX -c COLS -o OUT.json
        [-j THREADS=在线核数] [-k CKPTDIR] [-p PROGRESS.json] [-s STATS.json]
        [-f FREE_FROM=TMAX+1] [-m FREE_MAX=1024]
        [-b BWLOG=10] [-g SEGLOG=27]
        [--ckpt-start SEC=120] [--ckpt-throttle SEC=360] [--meta-interval SEC=30]
```

退出码：0 成功并已写出 OUT；2 参数或输入错误；3 内存分配失败；4 I/O 错误。

### 2.2 计算

- 位图按块处理（块 = `2^BWLOG` 个字），沿用 layers2 的置换加或运算。每块带三态标记：空、混合、满。输出块在 prev 中已满，或任一来源块已满，则直接置满；块在列循环中途变满可提前结束。
- 多线程用 pthreads，工作单元是连续若干块，按原子计数器领取。每个单元的 popcount 单独累计后求和，结果与线程数无关。
- 位图内存由各线程并行首次触碰；对位图调用 `madvise(MADV_HUGEPAGE)`（失败忽略）。
- 内存：两张位图加块标记和线程缓冲。r=40 时两张位图共 256 GiB，其余开销要求 < 1 GiB。不得再分配第三张位图大小的缓冲。

### 2.3 OUT.json（确定性）

内容只依赖 `R,TMAX,COLS,FREE_FROM,FREE_MAX`，与线程数、块/段大小、是否中断续跑无关，逐字节一致。先写 `OUT.json.tmp.<host>.<pid>`，fsync 后改名。

```
{
 "format": "layers3-v1",
 "r": R, "n": n, "tmax": TMAX,
 "cols": [c_0, ..., c_{n-1}],
 "L_sizes": [|L_0|, ..., |L_T|],
 "layers_computed": T,
 "full": true|false,
 "covering_radius": T | null,
 "complement_size_last": 2^R - |L_T|,
 "free_from": FREE_FROM, "free_max": FREE_MAX,
 "free": [ {"t": t, "count": 2^R-|L_t|, "reps": [按升序最小的 min(count,FREE_MAX) 个未覆盖伴随式]} ... ]
}
```

`free` 对每个 `FREE_FROM ≤ t ≤ T` 且 `L_t` 未满的 t 各一项，按 t 升序。数字一律十进制整数。键的顺序和空白固定。

### 2.4 断点（`-k CKPTDIR` 时启用）

用户要求：被抢占后不得从头重算；任何时刻被 `kill -9`，重启后丢失的计算时间不超过 10 分钟；续跑的 OUT 与不中断时逐字节一致。

- 位图切成段（段 = `2^SEGLOG` 个字，r 小时只有 1 段）。断点由段文件 `CKPTDIR/L<t>/seg<k>.bin` 和 `CKPTDIR/meta.json` 组成。段文件和 meta 都先写临时名、fsync、再改名。
- meta 记录：参数与列的指纹（r、tmax、n、列的 FNV-1a 64 位哈希、SEGLOG、FREE_FROM、FREE_MAX）、已算出的 `L_sizes` 和 `free` 项、最新完整落盘的层号 D、正在计算层 D+1 中已落盘的段号及每段 popcount、每个落盘段的 popcount。
- 时间策略：
  - 记 `durable_asof` 为这样的时刻：此前完成的全部计算都已落盘。
  - 计算第 t+1 层期间，若第 t 层尚未落盘且 `now - durable_asof ≥ ckpt-start`，后台写线程把 prev（此时只读）的全部段写盘；写完后更新 meta（D=t），再删除旧层目录。
  - 第 t 层已落盘后，第 t+1 层中整段算完的段随即入队写盘，meta 至少每 `meta-interval` 秒更新一次（有变化时）。
  - 存在“已算完但未落盘”的工作且其中最早的完成时刻距今超过 `ckpt-throttle` 秒时，计算线程暂停领取新单元，直到写线程追上。
  - 一张位图在被回收作下一层输出之前，针对它的写盘必须全部结束。
  - 写线程数 `--ckpt-writers`（默认 4），各写不同的段文件。
- 恢复：启动时若 CKPTDIR 有 meta 且指纹一致，读入第 D 层全部段和第 D+1 层已落盘的段，逐段核对文件长度和 popcount；D+1 层某段不符则丢弃该段重算，第 D 层不符则报错日志后从头算。指纹不一致：退出码 2，不覆盖。恢复后重建块标记。
- 成功写出 OUT 后删除 CKPTDIR 下的段文件，保留 meta（标记 finished）。
- 总时间短于 `ckpt-start` 的运行不写任何段。

### 2.5 PROGRESS 与 STATS

`-p`：每 ≤15 秒原子更新一次，同时充当心跳：

```
{"host":..., "pid":..., "r":..., "n":..., "tmax":..., "threads":..., "start_unix":..., "now_unix":...,
 "resumed_from_layer": D|null, "layer": 正在算的层号, "layer_frac": 0..1, "L_sizes":[...已完成层...],
 "durable_layer": D, "durable_lag_sec": ..., "throttled": true|false, "state":"running|writing|done"}
```

`-s`：结束时写一次：总墙钟、各层秒数、线程数、峰值 RSS、写盘字节数与秒数、恢复次数（从 meta 累计）。

### 2.6 过关测试（放 `qual/`，每项留命令、输出、结论）

1. **小域暴力对照**：独立的 Python 暴力实现（按定义对整数集合做 BFS，不看 layers3 源码的数据结构），对 r∈[10,20] 的至少 60 个随机用例（含：有重复列、有零列、n<r 秩亏、n 很大提前填满、偶码、列全为单位向量等边角）逐层比对 `L_sizes`、`covering_radius`、`free` 的 count 与 reps。
2. **线程一致**：r∈{22,26,30} 各若干用例，`-j 1` 与 `-j 8`、不同 `-b`/`-g` 的 OUT 逐字节一致。
3. **与 layers2 一致**：r∈{24,28,31} 的随机码上 `L_sizes` 与原 `layers2` 相同。
4. **regression**：`regression/S_H_cols.txt`（r=37，tmax=16）的 `L_sizes` 与 `regression/layers_S_r37.json` 完全一致。本机 61 GiB，该用例占 33 GiB，同一时刻只能跑一个，跑前看 `free -g`。
5. **杀掉续跑**：r=30–32 的用例，用小的 `--ckpt-start 0 --meta-interval 1 -g 18` 等参数，在随机时刻 `kill -9`，重复至少 20 次（含连续多次被杀、写段中途被杀、层边界附近被杀），最终 OUT 与不中断运行逐字节一致；并从 stats 确认确实发生了恢复而不是从头重算。另做一次 r=37 的 regression 用例中途杀一次的续跑。
6. **丢失上界**：用限速手段（例如把 CKPTDIR 放在限速的目录，或用环境变量 `LAYERS3_TEST_WRITE_DELAY_US` 给每次 write 加延迟）验证 throttle 生效，`durable_lag_sec` 不超过 `ckpt-throttle + meta-interval +` 一个段的计算时间。

构建：`gcc -O3 -march=x86-64-v2 -static -pthread`（不得用 `-march=native`，Cluster 节点 CPU 型号未知；popcount 用 `-mpopcnt`）。产物 `bin/layers3`，`ldd` 显示 statically linked。

## 3. 取矩阵（任务 B）

对 `inputs/jobs.json` 的每个 `base=[n0,k0]`，从 Magma 在线计算器取 `BKLC(GF(2),n0,k0)` 的校验矩阵。

- 地址 `https://magma.maths.usyd.edu.au/xml/calculator.xml`，POST 表单字段 `input`，应答 XML，输出在 `<line>` 元素。实测（2026-11-22）：计算上限 60 秒，输入上限 50,000 字符，**输出约 20,000 字节后被截断**（头里出现 `<warning>The output is too long and has been truncated.</warning>`），单次来回约 11 秒，版本 2.29-10。
- 每个码输出一组行，建议：
  ```
  SetColumns(0);
  C:=BKLC(GF(2),n,k); H:=ParityCheckMatrix(C);
  print "B", n, k, Nrows(H), Ncols(H), BKLCLowerBound(GF(2),n,k), BKLCUpperBound(GF(2),n,k);
  print &cat[IntegerToString(Seqint([Integers()!H[i][j] : i in [1..Nrows(H)]],2),16) cat "," : j in [1..Ncols(H)]];
  print "E", n, k;
  ```
  列整数用十六进制省输出。按预计输出字节数装箱，每次请求留 25% 余量；以每个码的 `E` 行是否出现判断完整，不完整的码进下一轮更小的箱。
- 串行发送，请求之间至少间隔 5 秒；429、503、超时退避重试至多 3 次。全部请求总数（含重试）不超过 400，超过就停下并写明原因。公共服务，不并发。
- 可断点续取：已成功的码不重发。
- 保存：`matrices/raw/req_<序号>.in`（发送的 Magma 输入）、`req_<序号>.xml`（原始应答）、`req_<序号>.meta.json`（HTTP 状态、耗时、UTC 时间、应答头中的 version/time）。
- 本地核对每个码：行数=ρ、列数=n0、GF(2) 秩=ρ；记录 Magma 的 `BKLCLowerBound`/`BKLCUpperBound`，与 `jobs.json` 的 `d0` 比较。
- 产物：
  - `matrices/H/<n0>-<k0>.cols`（第 1 节格式），并复制到 `SHARE/H/`。
  - `matrices/index.json`：每个码一项 `{id,n,k,rho,rank,ok,magma_lb,magma_ub,d0_table,d0_match,req,fetched_utc,sha256_cols}`。
  - `matrices/MISSING.md`：取不到、核对不过、或 `magma_lb != d0_table` 的格逐项列出及原因。不得悄悄跳过。
  - `matrices/progress.json`：`{total,done,failed,requests,last_utc,state}`，供看板读，取的过程中持续更新。

## 4. 调度、入口、汇总、看板（任务 C）

### 4.1 `bin/run_pack.sh <pack> [threads]`（在容器内运行，可重复执行）

- 读 `/work/packs/<pack>.tsv`。对每个 id：`/work/raw/<id>.json` 已存在则跳过；`/work/progress/<id>.json` 的 mtime 距今不足 180 秒且 host/pid 不是自己，则视为别的实例在跑，本轮先跳过；否则运行
  `layers3 -r rho -t tmax -c /work/H/<id>.cols -o /work/raw/<id>.json -k /work/ckpt/<id> -p /work/progress/<id>.json -s /work/raw/<id>.stats.json -f free_from -j threads`。
- 一轮扫完若仍有 id 无结果，睡 60 秒再扫，直到全部有结果，然后写 `/work/done/<pack>.DONE` 并以 0 退出。layers3 非零退出：记日志，继续下一个 id；同一 id 连续失败 3 次则整个脚本以非零退出。
- 日志写 `/work/logs/<pack>/<host>-<启动时间>.log`。只依赖 bash 和 coreutils。

### 4.2 打包 `sched/make_packs.py`

输入 `inputs/jobs.json`（第二轮另给清单）和 `matrices/index.json`（只打包 `ok` 的码）。每个基码 `tmax = max_depth-1`，`free_from = need-1`（need 是各目标 depth 的最小值）。分档（内存请求 = 两张位图 + 余量）：

| ρ | 内存请求 | 核数 | 每包 |
|---|---|---|---|
| ≤33 | 8 GiB | 8 | 按估算 CPU 小时均分成 4 包 |
| 34–36 | 24 GiB | 16 | 每包估算 ≤ 4 CPU 小时 |
| 37 | 40 GiB | 16 | 同上 |
| 38 | 72 GiB | 32 | 每包估算 ≤ 8 CPU 小时 |
| 39 | 136 GiB | 32 | 每包 1–2 个基码 |
| 40 | 264 GiB | 32 | 每包 1 个基码 |

核数和内存以 Cluster 冒烟结果为准，做成 `sched/tiers.json` 可改，不写死在代码里。输出 `SHARE/packs/*.tsv` 和 `sched/plan.json`（每包：name、round、ids、cores、mem_bytes、est_cpu_h）。

### 4.3 调度 `sched/scheduler.py`（不经模型，systemd --user 服务常驻）

- 每 120 秒一轮：对 plan 中每个包，按状态机 `new → submitted → running → done | resubmit | stuck` 推进。
  - 提交命令见 `SESSION_PROMPT.md` 第 7 节，`--name scan1-<pack>`，命令 `bash /work/bin/run_pack.sh <pack> <cores>`，`--restart-policy OnEvicted --retry 20`。
  - 用 `jobctl jobs get <id> -o json` 取状态。任务结束而 `SHARE/done/<pack>.DONE` 不存在：重新提交，同一包重提超过 10 次标记 `stuck` 并停止重提。
  - 同时在途（排队加运行）的包数上限和各档并发上限放 `sched/limits.json`，可热改。
  - 存在 `sched/STOP` 文件时不提交新任务（已在途的不动）。
- **CPU 小时台账** `sched/state/ledger.json`：每轮对处于运行状态的任务累加 `cores × 距上轮秒数 / 3600`；按包、按轮分别记。累计 ≥ 18,000 时自动创建 `sched/STOP` 并写事件。
- 每轮调用汇总（4.4），并写 `sched/state/status.json`（看板的唯一数据源之一）。
- **事件**：`sched/state/events/<UTC时间>-<类型>.json`，类型含 `hit`、`round1_done`、`round2_done`、`budget`、`stuck`、`pending_too_long`（某包排队超过 6 小时）。另提供 `sched/wait_event.sh`：阻塞到出现新的未确认事件后打印并退出（供调度者会话挂起等待，不轮询模型）。
- 任何输出都不得包含 `~/.cluster/config` 的内容；jobctl 的原始输出落盘前过滤含 token/secret/key 的行。

### 4.4 汇总 `sched/collect.py`

对 `SHARE/raw/<id>.json` 中尚未汇总的，结合清单里该基码的 `targets` 写 `CASE/results/<id>.json`：

```
{"id":..., "base":[n0,k0], "d0":..., "rho":..., "round":1,
 "L_sizes":[...], "layers_computed":T, "full":..., "covering_radius":T|null,
 "d0_check": {"t_max_checked": m, "ok": bool},   # |L_t| == Σ_{i≤t} C(n0,i) 对所有 t ≤ floor((d0-1)/2) 且 t ≤ T 成立 ⟺ d(B) ≥ 2m+1
 "targets":[{"type","cell","new_d","depth","closes","hit": bool, "uncovered_count": |V \ L_{depth-1}| 或 0,
             "one_short": bool   # full 且 covering_radius == depth-1
           }],
 "raw": "SHARE 相对路径", "raw_sha256": ...}
```

命中判定：目标所需深度 D，`hit ⟺ D-1 ≤ T 且 |L_{D-1}| < 2^ρ`。若 `T < D-1` 且未满，标 `incomplete`（不应出现，出现即事件）。命中时把该基码的 raw 结果、cols、目标信息复制到 `CASE/hits/pending/<id>/` 并发 `hit` 事件。`d0_check.ok == false` 也发事件。

### 4.5 看板 `dash/server.py`（systemd --user 服务常驻，监听 `0.0.0.0:18780`）

单页，自动刷新（前端每 10 秒取 `/api/status`）。服务端后台线程每 30 秒刷新缓存，不在请求线程里扫共享盘；对 raw/progress 目录做增量读取。内容：

- 顶部：当前阶段（准备／第一轮／第二轮／完成）、最后刷新时间、CPU 小时累计与 2 万上限的进度条、命中数（醒目）。
- 取矩阵进度（读 `matrices/progress.json`）。
- 过关状态（读 `qual/STATUS.json`，若存在：各项 pass/fail/pending）。
- 按 ρ 分档的进度表：基码总数、已完成、运行中、排队、未命中、命中、只差一层的目标数。
- Cluster 任务表：包名、任务号、状态、核数、内存、重启次数、已运行时长、该包完成数/总数。
- 正在运行的基码：id、ρ、n、当前层/tmax、层内进度、最新 `|L_t|/2^ρ`、落盘层、durable_lag、心跳年龄（超过 3 分钟标红）。
- 命中清单与验收状态（读 `hits/`）；事件列表（最近 50 条）。
- 最近完成的 30 个基码：id、覆盖半径、各目标所需深度、结论。

页面不显示任何凭据；只读，不提供任何写操作接口。不用外部 CDN（内网可能无外网）。
