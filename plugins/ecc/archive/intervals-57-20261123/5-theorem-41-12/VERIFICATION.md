# VERIFICATION — case 41-12（[41,12,≥15] 不存在性）

更新：2026-11-23。正文：`PROOF.tex`（唯一正文，TeX 原生）。台账：`PROOF_SKELETON.md`。规格：`FORMAL_SPEC.md` v3。

## 1. 本次 scope 与结论形态

完整原题：¬E(15)，即不存在二元线性 [41,12,≥15] 码。结论是计算机辅助证明，sound modulo 两条文献进口（I1、I2）；三条有限计算命题各有两套独立实现的全域结果。没有 Lean。

当前状态：**正式审计（Sol/xhigh，两轮）通过；MiniMax 补充审阅通过；Gemini 补充审阅因通道 429 未取得**（见 §6、§7）。FORMAL_SPEC 的验收条件因此还差 Gemini 一项，本 case **未标记完成**。

## 2. 原输入到结论的连接（各自由什么支持）

| 环节 | 命题 | 支持 |
|---|---|---|
| 偶码化 | E(15) ⟺ 偶 [42,12,≥16] | 解析（引理 even） |
| 对偶最小重量 | w∈{4,5,6} | 解析 + I1（引理 no39、dual） |
| 母码域 | K=C_S 是无零坐标偶 [42−w,13−w,16]；w=6 时无重复列 | 解析（引理 mother (a)–(d)） |
| 标准形 | 距离 ≥16 ⟺ 全部子集和的陪集深度条件 | 解析（引理 standard） |
| 运输 | 置换同时作用于母码与全部头 | 解析（引理 transport） |
| 目录覆盖 | 每个母码等价于目录某项 | I2 的类数 + 计算命题 1、2（命题 cover） |
| 有限谓词 | 头给出“解”（规范伴随式） | 解析（引理 label、bridge） |
| 全域为空 | 20709 个母码解集全空 | 计算命题 3 |

## 3. 进口

- **I1**：2006 JCMCC 发表版 Lemma 4（印刷 p.85，PDF 第 53 页），原文 “No linear [39, 10, 16] code exists.”；全文码均为二元（p.34），不限自正交。2026-11-22 重新取得发表版 PDF（`ref/lemma4-jcmcc-2006.pdf`，sha256 f037d7c7…）并读页图，记录 `work/20261122-imports/I1_reading.md`。原文证明依赖 Jaffe 在线表与一段未给出程序的扩张检查，本地没有重放。旁证（不是证明）：codetables 当前对 [39,10] 给出上界 15。
- **I2**：2025 Mathematics 13:2491 表 A5–A7 的类数 8170 / 17276 / 47；对象域按该文 §2（无零坐标，二元等价即坐标置换），重复列未被排除（Grok 审阅另核：[9,3,4] 8 类、[16,3,8] 12 类必含重复列）。原始分类计算没有在本地独立重做（重生成用的是同一程序，不算独立）。

## 4. 确定性检查

### 4.1 目录（计算命题 1、2）

| 目录 | 来源 | 码数 | 偶码 | 偶且无重复列 | hull 直方图 |
|---|---|---:|---:|---:|---|
| [38,9,16] | Zenodo 15771416 v1 中的作者文件 | 47 | 47 | 47 | {9:47} |
| [37,8,16] | GENERATION v1.1 重生成 | 17276 | 17254 | 16852 | {4:5, 6:77, 7:22, 8:17172} |
| [36,7,16] | GENERATION v1.1 重生成 | 8170 | 8096 | 3408 | {1:13, 3:53, 5:549, 6:71, 7:7484} |

- 谓词：块数；每码秩 = κ、最小重量恰 16（全枚举）、无零列；两两坐标不等价（不变量分桶 + 同桶对穷尽精确判定，无未判定对）。
- 实现 A（Sonnet）：`work/20261122-catalog/check/catalog_check.py`，结果 `*.check.json`。实现 B（Sol，只凭规格另写）：`work/20261122-catalog/check2/audit.cpp` + `run_audit.py`，结果 `*.audit.json`。两者的偶码下标表逐字节相同；“偶且无重复列”的 [36,7,16] 下标表相同（3408）。
- A 的精确搜索在审计第 1 轮被指出个体化标记未保证新鲜（issue 2）。已改为“精确签名的秩 + 最大颜色加一”，不用哈希；三份目录重跑，每一对判定与旧版相同（旧结果留作 `*.check.v1.json`）；另有 330 对小码与全置换暴力的对照一致（`small_control.json`）。
- 旁证：重生成的 [35,7,16]（4 码）与 Zenodo 文件逐行相同；两份重生成目录的 hull 直方图与论文表 A5、A6 的行一致。
- 不覆盖：目录“没有漏类”来自 I2 的类数，不来自这些检查。

### 4.2 搜索（计算命题 3）

谓词：`work/O6_SPEC.md` §3 的解集为空（D=16；w=4,5,6）。

| 分支 | 母码数 | o6 完成 | o7 完成 | 逐码一致 | Σ\|F\| | Σedges | Σc3 | Σc4 | Σc5 | 解 |
|---|---:|---:|---:|---|---:|---:|---:|---:|---:|---:|
| w=4，𝒦_4 | 47 | 47 | 47 | 是 | 13565 | 15 | 0 | – | – | 0 |
| w=5，𝒦_5 | 17254 | 17254 | 17254 | 是 | 119757064 | 581749323 | 52176 | 0 | – | 0 |
| w=6，𝒦_6（无重复列） | 3408 | 3408 | 3408 | 是 | 201323457 | 85014245310 | 64702964752 | 33931020 | 0 | 0 |
| （补充，不进入主定理）w=6，有重复列 | 4688 | 4688 | 4688 | 是 | 370672302 (o6) | 143799186756 (o6) | 137045172064 (o6) | 2012240 | 0 | 0 |

- o6 = `work/20261122-o6/extsearch.c`（伴随式分层 + 升序穷尽）；o7 = `work/20261122-o7/ext2.cpp`（码字 min-plus 距离变换 + 邻接表穷尽）。互不共享代码；o7 的作者没有读 o6。
- 逐码比较字段：主元列、K 的最小重量、|F|、F 的 SHA-256、偶深度直方图、edges、c3、c4、c5、解数、解表。工具 `work/20261122-compare/compare_runs.py`（另行解析目录，重算奇偶与主元）。报告：`compare_38_9_w4.json`（全真）、`compare_37_w5.json`（全真）、`compare_36_w6.json`（8096 个偶码全部比较且一致；`compare_36_w6.partial.json` 是 00:10 的旧快照）、`work/20261123-assembly/w6_subset_compare.json`（3408 子集两实现全部完成且一致）。
- 补充行：o7 于 2026-11-23 07 时前完成了最后一个母码 2067（约 10 小时；F=143172，edges=498078720，c3=15210754560，c4=0，与 o6 一致）。至此 𝒦_6^+ 的全部 8096 个偶母码两实现逐码一致，`work/20261122-compare/compare_36_w6.json` 的 `all_even_codes_compared_identical` 为真。2067、2374、2592 都有一个重复 4 次的列，按引理 mother(d) 不属于 w=6 分支的母码域。`PROOF.tex` 第 7 节关于“o7 完成 8095 个”的一句是撰写时的状态；为保持与审计绑定的正文哈希一致，没有再改正文。
- 运行环境：w=4 本机与 Cluster 各跑一次（结果相同）；w=5、w=6 在 Cluster（8 核任务 22 个，台账 `work/20261122-cluster/ledger.txt`）。实耗：o6 约 15.2 + 74.2 CPU 小时，o7 约 24.9 + 270 CPU 小时（按各码 `seconds` 求和）；relaxed-5 约 25 CPU 小时。

### 4.3 实现上线前的小域对照

- o6：61 例（w=2..6，D∈{4,6,8}，含重复列、含 d(K)<D），与 `brute.c`（展开真实扩张矩阵、全枚举码字）逐项一致；分层与暴力深度在 ρ=18..20 的 3 例一致。`work/20261122-o6/validation/REPORT.md`。
- o7：33 例与 `validate_small.py` 一致。`work/20261122-o7/REPORT.md`。
- 交叉：24 个由扩展 Golay 码子码构造的带已知解实例（D=8；w=6 的 8 例 c5>0）与 182 组随机小母码运行，o6、o7、真实矩阵判定程序、按定义枚举四方一致。`work/20261122-planted/REPORT.md`。该报告同时指出：测试中没有出现“严格只由 5 元和条件造成的拒绝”。针对这一点的补充检查见 §4.4。
- 真实规模交叉：47 个 [38,9,16] 与全部 w=5、w=6 母码上两实现逐码一致本身就是最大规模的对照。

### 4.4 5 元和条件的单独核对（审计 issue 3）

- 变体 `work/20261122-planted/relaxed5/extsearch_r5.c --relax5`（只把 5 元成员集合换成全部偶伴随式；99 个小域 w=6 实例与按定义枚举一致）在 𝒦_6 的 3408 个母码上运行（Cluster，4 个 8 核任务）。F_size、F_sha256、edges、c3、c4 与 o6 原运行逐码相同。`c5_relaxed`：3406 个母码为 0；idx 1980 为 6912，idx 2004 为 1741824。汇总 `work/20261123-assembly/r5_K6_summary.json`。
- 这 1748736 个 5 元集的见证（`work/20261123-witness5/`，独立脚本）：|T|≤4 的条件全部成立；5 元和深度全部恰为 6；每个集合有实际 12×42 扩张矩阵的一个重量 12 码字；`replay_witness.py` 重放 6912 + 1741824 行全部通过。抽查 6 个扩张码的重量谱均为 {12:1, 16:756, 20:1728, 24:1440, 28:165, 32:3, 36:2}。
- 含义：𝒦_6 上“无解”= 3406 个母码没有通过 1–4 元条件的 5 元集 + 2 个母码的全部候选有显式低重码字。这不依赖两套实现对 τ(5) 的处理。注意：`c5_relaxed` 的搜索本身是单实现（o6 变体）；它的 1–4 元部分与 o6/o7 双实现结果逐码一致（c4 相同），第 5 层只是在同一递归上多取一层。
- 严格 5 元拒绝的单元实例（κ≥1）：D=8 完整运行（extsearch 与 ext2 的 c5 相同 1694720016，relax5 多 32256；指定集合不在原程序解表、在 relaxed 表），D=10 部分运行（仅 extsearch）；D=12、16 的玩具实例 |F| 过大，程序未能运行，只做了直接计算。`work/20261122-planted/relaxed5/REPORT_R5.md`。

### 4.5 下界矩阵（计算命题 4）

`work/20261122-seed-e14/generator_12x41.txt`：`verify_code`（target_distance=14，exact）与独立实现均得秩 12、最小重量 14，重量谱 {14:160,16:456,18:699,20:943,22:931,24:611,26:233,28:37,30:25}。

`work/20261123-lb42/generator_12x42.txt`（矩阵出自 Magma 在线计算器 `BKLC(GF(2),42,12)`，出处不作为证据）：`verify_code`（target_distance=15，exact）与独立实现均得秩 12、最小重量 15，重量谱 {15:219,16:360,19:772,20:912,23:882,24:676,27:164,28:96,31:11,32:3}。用于 d₂(42,12)≥15（审计 issue 5）。

## 5. 局部审阅（非正式审计）

- Grok（grok-4.7）对抗审阅归约草稿与 O6_SPEC：`VERDICT: PASS`，三处措辞建议已改。`reviews/20261122-193252-grok-grok-reduction-d2_x3uj6/`（meta：exit 0，turn_completed，模型 grok-4.7）。审的是 `work/PROOF_DRAFT.md`（引理 0–6），其中 (d) 当时标为“不进入主证明”，Grok 仍核了它的算式。

## 6. 正式审计（proof-checker）

- reviewer：gpt-6.1-sol / xhigh，经 `review.sh sol`，只读。提示 `reviews/prompts/20261123-sol-formal-audit.md`，输入哈希 `reviews/prompts/20261123-sol-formal-audit.inputs.sha256`。
- 第 1 轮（02:42）：NEEDS_REVISION，5 个问题（4 MAJOR + 1 程序性 CRITICAL），无 FATAL，未发现归约或搜索逻辑的数学错误。`reviews/20261123-024211-sol-formal-audit-r1-ergj3j0n/`。
- 修复：命题 cover 补 Griesmer 步骤；目录核对实现 A 的精确搜索重写；relaxed-5 全域运行 + 1748736 个显式见证 + 单元实例；显式 [42,12,15] 矩阵。逐条见 `PROOF_AUDIT.md`。
- 第 2 轮（05:42，续同一会话）：**PASS**，issues 为空，第 1 轮的 1、2、3、5 CLOSED，4 PARTIALLY（等补充审阅记录）；research_complete=false。审阅者自行重算了 relaxed-5 汇总、重放了见证、全枚举了 [42,12,15] 矩阵。`reviews/20261123-054242-sol-formal-audit-r2-xljug60d/`。
- 产物：`PROOF_AUDIT.md`、`PROOF_AUDIT.json`（verdict PASS，reason all_proofs_complete，绑定 PROOF.tex sha256 5271395…）、`PROOF_CHECK_STATE.json`、`PROOF_SKELETON.md`。没有生成 `proof_audit_report.tex` 与 HTML 渲染（本机无 TeX 引擎；未做）。

## 7. 规格要求的补充审阅

FORMAL_SPEC：“完整证明经 proof-checker 正式审计，并由 MiniMax 与 Gemini 审阅”。

| 审阅者 | 调用 | 结果 | 记录 |
|---|---|---|---|
| MiniMax-M3.1-Flash | `review.sh flash`，05:42 | **PASS**。自述独立复算：三份目录全码统计、4 个母码的 numpy min-plus 深度变换（F_size、F 哈希、直方图、edges、c3/c4 与 o6/o7 一致）、见证重放（1980 全部 + 2004 抽 3000）、两个下界矩阵、全部逐码 JSON 汇总。两条记录性意见已处理。 | `reviews/20261123-054242-flash-minimax-supp-qh07b_5j/` |
| Gemini-3.8-flash | `review.sh gemini`，03:43（连通性测试）与 05:42（正式） | **未取得**：7 次尝试全部 HTTP 429 Too Many Requests。06:50 第三次调用（4 次尝试）同样全部 429。三次调用合计 11 次尝试，无一成功。10:54 再做一次连通性测试（`reviews/20261123-105407-gemini-gemini-ping2-qr0lhkxy/`），仍是 429。 | `reviews/20261123-034349-gemini-gemini-ping-bfuw1s31/`、`reviews/20261123-054242-gemini-gemini-supp-rzki36b4/`、`reviews/20261123-064941-gemini-gemini-supp2-fwjjb46b/` |
| DeepSeek-v4.1-flash（替代席；用户 11-21 在 72-36 指定它顶替 Gemini 的全局重评席位，本 case 的规格没有改） | `review.sh deepseek`，05:59 | 数学判定成立（自述逐条重推并复算）；verdict NEEDS_REVISION，唯一问题是规格要求的 Gemini 审阅缺失。 | `reviews/20261123-055902-deepseek-deepseek-supp-tlo4gz7c/` |

审阅者的“自述复算”没有逐项核对其命令记录（meta 中 commands 字段为空），按自述记录。

## 8. 当前原题状态与下一步

数学与证据：¬E(15)、d₂(41,12)=14、d₂(42,12)=15 的证明已装配，Sol/xhigh 正式审计通过，三家非 Anthropic 模型（Sol、MiniMax、DeepSeek）独立判定数学成立，Grok 审过归约草稿。sound modulo I1、I2。

验收：FORMAL_SPEC 要求的 Gemini 审阅未取得，**不能标记完成**。下一步：Gemini 通道恢复后重跑 `bash ../_devbox/review.sh gemini $PWD $PWD/reviews/prompts/20261123-supplementary-review.md gemini-supp`，或由用户决定是否接受 DeepSeek 作为替代。`CASE.json` 的最终状态由用户或外层脚本发布。

在途：无（Cluster 上本任务没有运行或排队中的作业）。
