# PROOF_AUDIT — case 41-12（累计日志）

正文 `PROOF.tex`；台账 `PROOF_SKELETON.md`。reviewer：gpt-6.1-sol / xhigh，经 `../_devbox/review.sh sol`（只读）。执行者（修复方）：claude-fable-5-2。跨家族。

## Round 1（2026-11-23 02:42–03:05）

- 提示：`reviews/prompts/20261123-sol-formal-audit.md`；输入哈希：`reviews/prompts/20261123-sol-formal-audit.inputs.sha256`。
- 原始回应：`reviews/20261123-024211-sol-formal-audit-r1-ergj3j0n/answer.md`；meta：exit 0，turn_completed，模型 gpt-6.1-sol，session `01a20490-db61-7a01-b1b5-2ea082c2526a`。
- raw verdict：**NEEDS_REVISION**，research_complete=false。

### 审阅者确认的内容（原文见 answer.md 的 checks）

- A–C、H：定义一致；各引理应用处的假设均有供给；Griesmer、球填充、mother(c)(d) 不等式、尾重与阈值逐个重算无误；无循环依赖。D–F 不适用。
- q1：归约覆盖任意秩 12 的 12×41 矩阵，无附加结构；w=6 的无重复列由 mother(d) 严格推出，w=4、5 未用该限制。
- q3：label、bridge 正确；O6_SPEC §2–§3 与正文定义逐条一致。
- q5：读了两套搜索实现的全部逻辑，深度计算精确、阈值正确、除升序外无剪枝、计数不溢出、解表未截断；自行重读 3408 个 𝒦_6 母码的两目录原始 JSON，17 个字段逐码无差异（ΣF=201323457，edges=85014245310，c3=64702964752，c4=33931020，c5=0）。
- q7：2067、2374、2592 各有一个重数 4 的重复列，不在主域。
- 反例红队：dual、mother(c)(d)、standard(ii)、transport、bridge、cover 各一次尝试，均未得到反例。另构造了一个 κ=0 的玩具，说明“只被 5 元和条件拒绝”的情形在代数上存在（用于 issue 3）。

### 问题与处理

| # | 严重度 | 问题 | 处理 | 状态 |
|---|---|---|---|---|
| 1 | MAJOR / GLOBAL | 命题 cover 把 I2 的“最优码”类数直接当作全部 [N,κ,16] 码的类数，少写了“≥17 不存在”这一步 | 进口 I2 改按原文表述为“最优 [n,k] 码”；命题 cover 的证明开头补：Griesmer（g(9,17)=40、g(8,17)=39、g(7,17)=38，不需 I1）排除 ≥17，目录给出实际的 16，故 d₂(N,κ)=16 | 已改（PROOF.tex 第 50、200 行） |
| 2 | MAJOR / LOCAL | 目录核对实现 A 的个体化颜色标记没有保证新鲜，穷尽性证明有形式缺口（实现 B 不受影响） | A 的精确搜索重写：精确签名的秩、个体化取最大颜色加一、无哈希、`--assert-fresh`；三份目录重跑，逐对判定与旧版相同；新增 330 对小码与全置换暴力对照 | 已改（`work/20261122-catalog/check/`，REPORT “Update 3”） |
| 3 | MAJOR / GLOBAL | 小域验证没有出现“严格只被 5 元和条件拒绝”的样例，不能排除两套实现共同的 τ(5) 错误 | (a) `--relax5` 变体在 𝒦_6 全部 3408 个母码上运行：3406 个 c5_relaxed=0；idx 1980（6912）与 2004（1741824）非零；(b) 这 1748736 个集合逐个给出实际 12×42 扩张码的重量 12 码字（5 元和深度恒为 6），可重放；(c) κ≥1 的严格 5 元单元实例（D=8 完整、D=10 部分） | 已做（`work/20261123-assembly/r5_K6_summary.json`、`work/20261123-witness5/`、`work/20261122-planted/relaxed5/REPORT_R5.md`；PROOF.tex 第 7 节新增一段） |
| 4 | CRITICAL / GLOBAL（程序性） | 正式审计与 MiniMax、Gemini 补充审阅在第 1 轮时尚未完成 | 第 2 轮复审完成（PASS）；MiniMax 审阅完成（PASS）；Gemini 三次调用共 11 次尝试全部 429，未取得 | **部分关闭**：Gemini 审阅缺失 |
| 5 | MAJOR / LOCAL | d₂(42,12)=15 的下界没有本地证据 | 显式 [42,12,15] 矩阵（Magma BKLC），`verify_code` 与独立实现均得秩 12、最小重量 15；正文计算命题“下界矩阵”加 (ii)，推论写成等式 | 已改（`work/20261123-lb42/`） |

审阅者没有提出 FATAL 问题，也没有发现归约或搜索逻辑的数学错误。

## Round 2

- 提示：`reviews/prompts/20261123-sol-formal-audit-r2.md`（续第 1 轮会话）；输入哈希 `reviews/prompts/20261123-r2.inputs.sha256`（PROOF.tex sha256 5271395…；此后 PROOF.tex 未再改动）。
- 原始回应：`reviews/20261123-054242-sol-formal-audit-r2-xljug60d/answer.md`；meta：exit 0，turn_completed，模型 gpt-6.1-sol / xhigh，同一 session。
- raw verdict：**PASS**，research_complete=false，final_status “数学与证据审计通过；待补充审阅记录”。issues 为空。round1_issue_status：1 CLOSED，2 CLOSED，3 CLOSED，4 PARTIALLY，5 CLOSED。
- 审阅者本轮实际做的复核（evidence_read）：重读 PROOF.tex 修改处；读新版 `catalog_check.py` 与小域对照；读 relaxed5 的 diff 与报告；直接读取 3408 个 relaxed5 原始 JSON 并重算 c5 之和 1748736 与两个非零下标；用自己的代码重放 `witness_1980` 全部 6912 行与 `witness_2004` 前 5000 行（重建 31 个子集深度与 12×42 码字）；独立全枚举 [42,12,15] 矩阵的 4095 个码字。
- 审阅者指出的记录同步问题（非数学）：PROOF_SKELETON 当时未同步（已补第 9 节）；VERIFICATION 的审计状态当时未更新（已更新）。

## Phase 3.5 整体闭合

- 结论与定理陈述一致（¬E(15)，modulo I1、I2 与计算命题 1–3）；DAG 无环；全部义务或已证或显式列为进口/计算命题；分支 w∈{1,2,3}、{4,5,6}、≥7 穷尽；无 WLOG 之外的约化（坐标置换的运输在引理 transport 中证明）。
- 没有 FATAL/CRITICAL 数学修复，故不触发“盲审修复段”的独立第二审。第 1 轮后的实质修改有两处进入定理链：引理 mother(d) 在第 1 轮审计前已在正文中并被审；命题 cover 的 Griesmer 步骤在第 2 轮被复核。
- 假设变化：w=6 分支的母码域由“全部偶母码”收窄为“无重复列的偶母码”，依据引理 mother(d)（已证）；主定理陈述未变。

## 补充审阅（FORMAL_SPEC 要求；不属于 proof-checker 自身的判定）

| 审阅者 | 结果 | 记录 |
|---|---|---|
| MiniMax（MiniMax-M3.1-Flash，`review.sh flash`） | **PASS**（数学）；两条记录性意见：补充审阅归档、o7 补充域数字三处不一致（已统一） | `reviews/20261123-054242-flash-minimax-supp-qh07b_5j/` |
| Gemini（gemini-3.8-flash，`review.sh gemini`） | **未取得**：连通性测试（03:43，3 次）与两次正式调用（05:42、06:50，各 4 次）全部 HTTP 429 | `reviews/20261123-034349-gemini-gemini-ping-bfuw1s31/`、`reviews/20261123-054242-gemini-gemini-supp-rzki36b4/`、`reviews/20261123-064941-gemini-gemini-supp2-fwjjb46b/` |
| DeepSeek（deepseek-v4.1-flash，替代席，不等同于规格要求的 Gemini） | 数学判定成立；verdict NEEDS_REVISION，唯一问题是“缺 Gemini 审阅” | `reviews/20261123-055902-deepseek-deepseek-supp-tlo4gz7c/` |

## 当前判定

proof-checker 验收门：通过（零未解 FATAL/CRITICAL；每个定理/引理有显式假设与证明；反例轮已执行）。机器可读结果 `PROOF_AUDIT.json`，状态 `PROOF_CHECK_STATE.json`。

FORMAL_SPEC 的不存在性验收：**尚缺 Gemini 审阅一项**，因此本 case 不能标记完成。
