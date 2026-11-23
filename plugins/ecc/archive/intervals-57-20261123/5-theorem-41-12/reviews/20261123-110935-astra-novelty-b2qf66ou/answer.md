## 结论

截至本轮检索，**没有找到已发表论文或预印本已经包含“不存在二元线性 `[41,12,≥15]` 码”或等价“不存在偶 `[42,12,16]` 码”的具体结论**。因此没有满足 Verdict Limits 所要求的 ABANDON 条件。

新颖性应拆开评价：

- **具体结果：新颖性较强。** 现有码表仍为 `[41,12] = 14–15`、`[42,12] = 15–16`，没有公开关闭这两个区间（见 [41,12] 码表](</home/user/math/aris4math_v2/cases/41-12/work/20261123-novelty/codetables_41_12.html:11>)、[42,12] 码表](</home/user/math/aris4math_v2/cases/41-12/work/20261123-novelty/codetables_42_12.html:11>)）。
- **方法新颖性较弱。** “按对偶最小距离缩短到母码，再枚举延拓”已有明确先例；不宜把它表述成全新的分类算法。
- **可核实的结果差别：** 本工作首次在现有材料中把 `[41,12]` 的上界从 15 降到 14，并把 `[42,12]` 的上界从 16 降到 15；技术上还把此前类似的 `w=4` 路线扩展到 `w=5,6`，覆盖全部 20,709 个偶母码候选。

## 最接近的已有工作

| 来源 | 重叠 | 差别 |
|---|---|---|
| Feulner, *Classification and nonexistence results for linear codes with prescribed minimum distances*, DCC 70 (2014) | 最接近的方法学先例。其 Construction Y1 从对偶最小重量母码出发，分类后添加对偶列，并用等价类拒绝保证完备性。[预印本摘要](</home/user/math/aris4math_v2/cases/50-16/ref/feulner-nonexistence-preprint.txt:7>)明确这样描述。 | 其二元参数表没有 `[41,12,15]` 或 `[42,12,16]`；Table 1/2 的二元条目是 `[35,10,13]`、`[43,17,12]`、`[57,30,12]` 等。[表格](</home/user/math/aris4math_v2/cases/50-16/ref/feulner-nonexistence-preprint.txt:352>) |
| Bouyuklieva–Bouyukliev, ICMS 2020 | 同样使用 residual/母码分类和延拓检查；证明了若干其他参数的不存在性。 | 没有 `[41,12]` 或 `[42,12]`；其目标参数和本工作的三分支深度条件不同。 |
| Bouyuklieva–Dzhumalieva-Stoeva, *Optimal Linear Codes and Their Hulls* (2025) | 直接提供 `[38,9,16]`、`[37,8,16]`、`[36,7,16]` 的分类类数，是本工作的关键文献进口。 | 论文没有给出 `[41,12,15]` 或 `[42,12,16]` 的不存在性。 |
| 上海创智学院李帅团队 2026 年公告 | 这是最接近的参数级竞争工作：同样使用对偶重量 4、已分类母码和陪集无和性。 | 公告涉及 `(43,10)`、`(44,10)`、`(44,11)`、`(45,11)`、`(42,16)`，没有本题两个参数；本工作还必须处理 `w=5,6`。 |
| Hill–Traynor, IEEE TIT 36 (1990) | 处理过邻近的不存在性 `[41,12,16]`。 | `[41,12,16]` 比本题目标强一档，但该论文没有证明 `[41,12,15]` 或偶 `[42,12,16]`。 |

因此最诚实的定位是：

> 本工作不是提出新的通用分类算法，而是利用现有的 Y1/residual 思路和 2025 年母码分类，完成了此前未完成的 `[41,12]` 与 `[42,12]` 两个具体参数格。

## 本轮发现的一个检索遗漏

Phase B 对 LinCodeEvolve 的描述过强。其预印本确实直接出现了 `[41,12]` 目标行，报告已有下界 14，并记录了一个距离只有 12 的搜索基线；但它**没有**声称距离 15，也没有不存在性证明。[原文表格](</home/user/math/aris4math_v2/cases/45-11/ref/lit-c29/arxiv-2609.37056.txt:418>)。

这不是结果重叠，但说明 `[41,12]` 已成为 2026 年近期工作的显式目标，存在并行竞争风险。

## 仍需补查的盲区

1. **Maruta–Tochiyama–Yasufuku 的 DCC 2026 期刊版**  
   *On the minimum length of binary linear codes*, DOI `10.1007/s10623-026-01947-2`。目前只核对到摘要级；摘要提到 `D₂,12 = 3392`，应取得全文并搜索 `[41,12]`、`[42,12]`、`16-divisible` 和相关表格。

2. **上海创智学院团队的后续正式稿**  
   应查李帅团队作者主页、SII 技术报告、arXiv、CNKI、万方及会议论文集，确认公告是否已有未公开或刚提交的扩展稿。

3. **Feulner 2014 的最终出版版与作者页面**  
   本地已读完整预印本并核对参数表，但仍应取得 Springer 最终版，排除表格或附录在最终版本中发生变化。

4. **作者和数据库渠道**  
   点名应查：Markus Grassl、Iliya Bouyukliev、Stefka Bouyuklieva、Sascha Kurz、Thomas Feulner、D. B. Jaffe、Maruta–Tochiyama–Yasufuku 的个人主页；MathSciNet、zbMATH、Google Scholar、Semantic Scholar、OpenAlex、Crossref。

5. **会议渠道**  
   应专门检查 IEEE ISIT 2026、IEEE ITW 2026、WCC/ICMS 2026、AAECC 2026 的录用论文和摘要，而不能只依赖通用搜索。

6. **MinT 数据库**  
   现有抓取查询到了其对偶 OA 视图，不是 `[n,k,d]` 目标格的直接查询；因此不能把当前 MinT 结果当作有效的独立确认。

综合评分：**7/10**。结果本身有清晰、可验证的参数级差别；方法应诚实地定位为现有 residual/Y1 框架在新参数上的完整实现。  

RECOMMENDATION: PROCEED