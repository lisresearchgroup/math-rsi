这是同一份正式审计的第 2 轮（proof-checker Phase 3：修复后复审）。你在第 1 轮提出 5 个问题（verdict NEEDS_REVISION）。下面是逐条处理与证据位置。请重新读取被修改的原件（不要只信本摘要），按第 1 轮同样的必查项复核受影响的部分，逐条判断每个问题是否真正消除，并检查修复是否引入新问题。仍然只读；可做轻量复算（例如重放见证）。

## 修复摘要

1. **(issue 1) 命题 cover 的依赖**：`PROOF.tex` 进口 I2 的表述改为原文的“最优 [n,k] 码”（第 50 行附近）；命题 cover 的证明开头新增一步：由 Griesmer 界（g(9,17)=40>38、g(8,17)=39>37、g(7,17)=38>36，不需要 I1）不存在 [N,κ,≥17] 码，而计算命题 1 给出实际的 [N,κ,16] 码，故 d₂(N,κ)=16，“最优 [N,κ] 码”就是全部 [N,κ,16] 码（第 200 行附近）。
2. **(issue 2) 目录核对实现 A 的精确搜索**：`work/20261122-catalog/check/catalog_check.py` 重写了精确搜索（`exact_refine_pair` / `equivalent`）：颜色是精确签名的稠密秩，个体化标记取“当前最大颜色 + 1”，搜索中不再使用任何哈希；新增 `--assert-fresh` 断言模式。三份目录全部重跑，旧结果保留为 `*.check.v1.json`，新旧每一对的判定完全相同（36_7_16：34 个同桶组、122 对全不等价；37_8_16：2 组、4 对全不等价）。新增小域对照 `small_control.py`/`small_control.json`：330 对同参数小码上精确搜索与遍历全部 n! 置换的暴力结果一致。说明见该目录 `REPORT.md` 的 “Update 3”。
3. **(issue 3) 5 元阈值路径**：
   - `work/20261122-planted/relaxed5/extsearch_r5.c`：o6 的变体，`--relax5` 只把 5 元成员集合换成全部偶伴随式（diff 见 `extsearch_r5.diff`，一行实质改动 `ethr[2]=-1`）；99 个小域 w=6 实例上与按定义枚举一致（`REPORT_R5.md`）。
   - 在 𝒦_6 全部 3408 个母码上运行（Cluster，结果 `/shared/ecc-41-12/out/r5_K6_w6/<idx>.json`，汇总 `work/20261123-assembly/r5_K6_summary.json`）：F_size、F_sha256、edges、c3、c4 与 o6 原运行逐码相同；c5_relaxed 在 3406 个母码上为 0，只有 idx 1980（6912）与 idx 2004（1741824）非零。
   - 这 1748736 个 5 元集的完整列表在 `work/20261123-assembly/r5/{1980,2004}.relax5.full.json`；独立见证在 `work/20261123-witness5/`（`witness5_all.py`、`replay_witness.py`、`witness_{1980,2004}.txt.gz`、`REPORT.md`、`witness5_stats.json`）：每个集合的 31 个子集和深度由生成矩阵直接重算，|T|≤4 条件全部成立，5 元和深度全部恰为 6（<10），并给出实际 12×42 扩张矩阵中重量 12 的码字；重放脚本两个文件全部通过。
   - κ≥1 的严格 5 元单元实例：`work/20261122-planted/relaxed5/REPORT_R5.md` 第 5 部分（D=8 完整运行：extsearch 与 ext2 的 c5 相同、relax5 多 32256，指定集合不在原程序解表而在 relaxed 表；D=10 部分运行；D=12/16 的玩具因 |F| 过大未能运行程序，只做了直接计算）。
   - `PROOF.tex` 第 7 节新增一段“5 元和条件的单独核对（w=6）”。
4. **(issue 4) 程序性**：本轮即正式审计的复审。MiniMax 与 Gemini 的补充审阅与本轮并行发起（Gemini 通道 2026-11-23 03:43 的连通性测试连续三次返回 429，见 `reviews/20261123-034349-gemini-gemini-ping-bfuw1s31/`；正式调用再试一次，结果如实记录）。请你只判断数学与证据；补充审阅是否齐备由调度者在 VERIFICATION.md 中如实记载，不需要你等待。
5. **(issue 5) d₂(42,12)=15 的下界**：`work/20261123-lb42/generator_12x42.txt`（来自 Magma `BKLC(GF(2),42,12)`，出处见 `PROVENANCE.md`）；`verify_code` 与独立实现均得秩 12、最小重量 15、相同重量谱（`REPORT.md`）。`PROOF.tex` 的计算命题“下界矩阵”增加 (ii)，推论相应写成 d₂(42,12)=15。

另：o7 在有重复列的补充域上又完成了 2374、2592（与 o6 一致），只剩 2067 在运行；这些不在主定理论域内，正文第 7 节已更新为“8095 个完成”。

## 请回答

- 对 issue 1、2、3、5：是否关闭（CLOSED / PARTIALLY / OPEN），依据是什么（你实际读了什么、算了什么）。
- 对新增内容做同样的必查：`PROOF.tex` 修改处的陈述是否准确；relaxed-5 变体是否只改了所述一处、是否可能改变 |T|≤4 的判定；`r5_K6_summary.json` 是否可由原始逐码 JSON 重算（请至少自行核对 3408 个文件的 c5 之和与两个非零下标）；见证是否成立（请自行重放：至少对 idx 1980 的全部 6912 行与 idx 2004 的若干千行，用你自己的代码由生成矩阵重建码字并核对重量 12；并自行重算若干集合的 |T|≤4 深度条件）；“3406 个母码 c5_relaxed=0 + 两个母码全部候选有低重见证”是否在逻辑上蕴含 𝒦_6 上解集为空，且这一步不依赖任何实现对 τ(5) 的处理。
- 命题 cover 新增的 Griesmer 步骤是否正确、是否确实不需要 I1。
- 计算命题“下界矩阵”(ii)：请自行读取矩阵文本做一次轻量全枚举（4095 个码字）核对秩与最小重量。
- 现在是否还有未解的 FATAL / CRITICAL / MAJOR 数学或证据问题。

## 输出格式

与第 1 轮相同的单个 JSON 对象（verdict、research_complete、final_status、issues、checks、counterexample_attempts、evidence_read、summary），另加字段 `"round1_issue_status": {"1": "...", "2": "...", "3": "...", "4": "...", "5": "..."}`。issues 只列本轮仍未解决或新发现的问题。关于 research_complete：若数学与证据层面已无未解问题，而唯一剩余事项是由调度者执行并记录的补充审阅（MiniMax、Gemini），请把 research_complete 设为 false 并在 final_status 中写明“数学与证据审计通过；待补充审阅记录”，verdict 可为 PASS。
