# 查新报告：不存在二元线性 [41,12,≥15] 码

2026-11-23。原始抓取在本目录。这是检索结论，不是数学证据。

## 待查结果

不存在二元线性 [41,12,≥15] 码，故 d₂(41,12)=14、d₂(42,12)=15（公开表为 14–15、15–16）。方法：对偶最小重量 4/5/6 三分支 + 已分类母码 + 陪集相容性穷尽。

## 核心声明与最接近的已有工作

1. d₂(41,12) 上界 15→14 — 最接近：码表现行上界 15（由 [39,10] 上界缩短得到）。没有找到给出 14 的来源。
2. d₂(42,12) 上界 16→15 — 最接近：码表现行上界 16（Griesmer 界）。没有找到给出 15 的来源。
3. 方法 — 最接近：上海创智学院李帅团队 2026-11-07 公告的 (43,10) 证明（对偶重量 4 的缩短 + 172 类母码 + 陪集无和性）。本结果是同一方法在另一组参数上的应用，多了 w=5、6 两个分支和三到五元子集条件。方法本身不新，参数结论是新的。

## 检索到的材料

| 来源 | 日期 | 与本结果的关系 |
|---|---|---|
| codetables.de [41,12]、[42,12] 页面（`codetables_41_12.html`、`codetables_42_12.html`） | 抓取于 2026-11-23 | 仍为 14–15、15–16 |
| Magma V2.29-10 在线计算器 BKLC 上下界（`magma_bounds.xml`） | 2026-11-23 | 14/15、15/16 |
| 上海创智学院公告 | 2026-11-07 | 参数为 (43,10)、(44,10)、(44,11)、(45,11)、(42,16)，不含 (41,12)、(42,12) |
| Bouyuklieva–Bouyukliev，ICMS 2020（`residuals_pmc.html`） | 2020 | 无 [41,14,14] 等；全文无 [41,12]/[42,12] |
| Bouyukliev–Bouyuklieva–Kurz，arXiv:2002.07826（`lincode_2002.07826.html`） | 2020 | 全文无 [41,12]/[42,12] |
| Bouyuklieva–Dzhumalieva-Stoeva，Mathematics 13:2491 | 2025 | 分类范围 k≤10、n≤40 |
| Kurz，arXiv:2610.39870v2（`kurz_so_2610.39870.html`） | 2026-11-17 | 维数 ≤9 的自正交码；全文无 [41,12]/[42,12] |
| Tang–Fan，arXiv:2611.24997（`tang_fan_2611.24997.html`） | 2026-11-18 | 无 [65,9,29]；全文无 [41,12]/[42,12] |
| LinCodeEvolve，arXiv:2609.37056（`lincodeevolve.html`） | 2026-09-29 | 7 个下界构造，长度 50–240。**更正**：该文把 [41,12] 列为搜索目标之一（表中一行：已知下界 14，其搜索只到 12），没有声称 15，也没有不存在性证明。初稿写“全文无 [41,12]”是我的抓取脚本漏了，由 Astra 指出，已对本地文本 `../../../45-11/ref/lit-c29/arxiv-2609.37056.txt` 第 418 行附近核实 |
| Feulner，Classification and nonexistence results for linear codes with prescribed minimum distances，DCC 70 (2014)（本地预印本 `../../../50-16/ref/feulner-nonexistence-preprint.txt`） | 2014 | 方法上最接近的先例（从对偶最小重量出发缩短到母码再扩张）；其二元参数表无 [41,12,15]、[42,12,16]（Astra 指出；我只核了本地预印本中无 “41,12” 字样，未取 Springer 终版） |
| Hill–Traynor，IEEE TIT 36 (1990) | 1990 | 据 Astra：处理过邻近的 [41,12,16] 不存在性；未涉及 [41,12,15]。我没有取原文核对 |
| Maruta–Tochiyama–Yasufuku，On the minimum length of binary linear codes，DCC 2026，doi:10.1007/s10623-026-01947-2（`maruta_dcc2026.html`） | 2026 | 只读到摘要（全文需订阅）：研究达到 Griesmer 界的码，D_{2,12}=3392 等，针对很大的 d。[41,12,15] 的 Griesmer 长度是 37，不在其讨论的范围内；摘要页无 [41,12]/[42,12]。全文未核 |
| generalised.si（`generalised_si.html`） | 2026-11-16 | 5 个下界构造，长度 111–174 |
| Kiermaier–Wassermann–Zwanzger，arXiv:1503.03394 | 2015 | 无关参数 |
| Bouyukliev–Jacobsson，arXiv:1006.0109 | 2010 | 最小距离 8、10，无关参数 |

检索式（网络搜索，均无直接命中）：`"[41,12,15]" OR "[42,12,16]" nonexistence`；`"d_2(41,12)"`、`"n(12,16)"`；Kurz/Bouyukliev/Bouyuklieva nonexistence；2026 年 binary linear code nonexistence；中文“(41,12) 上界 不存在 码表”。

## 结论

- 没有找到任何已发表论文或预印本包含本结果。两个权威表（codetables.de、Magma 数据库）今天仍把这两格列为开放。
- 评分 7/10。建议：PROCEED。
- 可核实的差别：把 d₂(41,12)、d₂(42,12) 的上界各降 1，使两格闭合。
- 风险：这一方向近一个月很活跃（创智学院 11-07、Kurz 11-17、Tang–Fan 11-18），而且 [41,12] 本身已被 LinCodeEvolve（9 月）列为显式搜索目标，存在别人同时在做的可能；这不否定新颖性，但意味着时间敏感。

## 没有查的地方

- 未发表的私人通信、码表维护者手里尚未上线的更新（codetables 的这两页最近修改记录是 2001 年）。
- Semantic Scholar / OpenAlex 的引用链没有系统查（谁引用了 2006 JCMCC 论文或 2025 hull 论文）。
- MinT 数据库查询参数没有对上，未取得有效结果。
- 中文数据库（知网等）与会议论文集只靠通用搜索，未专门检索。
- IEEE ISIT/ITW 2026、WCC、AAECC 等会议的录用论文没有专门检索；MathSciNet、zbMATH 没有查（Astra 列为盲区）。

## Phase C：独立审阅者复核

Astra（gpt-6-astra，`review.sh astra`，只读；记录 `reviews/20261123-110935-astra-novelty-b2qf66ou/`，exit 0、turn_completed）。结论：没有找到包含本结果的已发表论文或预印本；评分 7/10；`RECOMMENDATION: PROCEED`。它补充了 Feulner 2014、Hill–Traynor 1990、Maruta 等 2026 三项相邻工作，并纠正了我对 LinCodeEvolve 的描述（见上表）。它建议的定位：

> 本工作不是提出新的通用分类算法，而是利用现有的缩短到母码再扩张的思路和 2025 年的母码分类，完成了此前未完成的 [41,12] 与 [42,12] 两个具体参数格。
