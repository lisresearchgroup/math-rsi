# 证明包（候选成果，待外层轮末检查与跨家族审阅）
# case 42-16 — 二元线性 [42,16] 码：不存在性方向 ¬E(13)，故 d_2(42,16)=12

状态：**候选**。本会话（Flash 主执行）不宣布完成、不改 `CASE.json` 的 status、不打 milestone。
本包供外层 `round_check.py` 的唯一一次 fresh GPT-6 Astra/xhigh 只读检查，以及 FORMAL_SPEC 要求的
proof-checker 审计与跨家族（Grok/Gemini）审阅使用。

---

## 0. 结论（待验收）

1. **¬E(13)**：不存在二元线性 [42,16,≥13] 码。
2. 合���本 case 已独立复算的下界 $d_2(42,16)\ge 12$，得 **$d_2(42,16)=12$**。
3. 推论：不存在偶 [43,16,14] 码；且 $d_2(43,16)\le 13$（任意 [43,16,≥14] 穿孔一位即得 [42,16,≥13]）。
4. 本结论**不依赖**本 case 原先的 U1/U2/U3 叶子（Jaffe / van Pul）：主定理只用一条新的外部 import 与一条自证归约。

形式化写法：记 $E(t)$ =「存在二元线性 [42,16,$\ge t$] 码」。

---

## 1. 记号

- $d_2(n,k)=\max\{d(C): C \text{ 二元线性 } [n,k,d] \text{ 码}\}$。
- 「偶码」= 全部非零码字重量为偶的码。
- $G$ 为 $k\times n$ 生成矩阵；第 $j$ 列为 $g_j\in\mathbb F_2^k$；坐标线性泛函 $x\mapsto (xG)_j$ 对应 $u\mapsto u\cdot g_j$。
- 穿孔（puncture）：删去坐标并取像；缩短（shorten）：先限制到该坐标为 0 的子码，再删去该坐标。
  缩短保持线性、保持「距离不减」，且若所选两个坐标泛函线性无关，维数恰降 2。

---

## 2. 外部 import（唯一一条；已回原文逐字核对）

**IMP-1.** S. Bouyuklieva and I. Bouyukliev, *Classification of Linear Codes by Extending Their Residuals*,
in *Mathematical Software – ICMS 2020*, LNCS **12097**, pp. **173–180**, Springer 2020.
DOI `10.1007/978-3-030-52200-1_17`（PMC7340893）。

> **Proposition 2.** Binary linear [41,14,14] codes do not exist.  （印刷 p.179，PDF 第 7 页）

- **适用域**：命题文字对**全部二元线性码**成立，无 even/projective/零列/互异列限制。
  证明第一步用 Proposition 1（「若二元 [n,k,2d] 码存在，则存在一个 even 的」）把问题归约到 even 码，
  因此「排除全部 even 码 ⇒ 排除全部码」。Prop 1 本身在本包中不被单独使用。
- **距离语义**：原文第 2 节定义「A linear code of length n, dimension k, and minimum distance d … is called an [n,k,d] code」，
  故 **14 = 最小距恰为 14**。本包的归约**恰好**产出最小距恰为 14 的 [41,14,14] 码，
  因此无论命题按 exact 还是 $\ge$ 语义理解都被覆盖（见 §5 讨论）。
- **推论（由本包的「距离下降法」得到，属本 case 自证）**：设 $C$ 是二元线性 [n,k,$d$] 码（$k\ge1$），
  **整数** $d_0$ 满足 **$1\le d_0<d$**（**$d_0=0$ 必须排除，理由是「维数下降」而不是「最小距不良定义」**：
  穿孔像**仍是线性码**（例 $\langle1100,0011\rangle$ 穿孔首行支撑 $\{0,1\}$ 得 $\{00,11\}$，维数 1、最小距 2，
  最小距仍良定义）；但 $T=\mathrm{supp}(c)$ 时核恰为 $\{0,c\}$（任何支撑 $\subseteq T$ 的非零码字重量 $\ge d$ 且 $\le d$
  ⇒ 重量恰 $d$ ⇒ 等于 $c$）⇒ 穿孔像维数降为 $k-1$ ⇒ **得不到同维数的 $[n,k]$ 码**。
  边界回归：`work/20261020-source-corrections/verify_reduction_corrections.py` 的 **V5**（exit 0 时 PASS））。
  取最小权码字 $c$（重 $d$），令 $T\subseteq\mathrm{supp}(c)$，$|T|=d-d_0$；在 $T$ 上穿孔得 $C_T$：
  核中任一非零码字的支撑含于 $T$，重量 $\le d-d_0<d$，矛盾 ⇒ 穿孔单射、维数不降；又 $d(C_T)\ge d-|T|=d_0$ 而
  $c$ 的像重 $d_0$ ⇒ $d(C_T)=d_0$ **恰**；再补 $d-d_0$ 个**零列**（零列不改变任何码字重量）得同长度 $(n,k)$、最小距**恰** $d_0$ 的码。
  ⇒ **「不存在最小距恰 $d_0$ 的 [n,k] 码」⇒「不存在任何最小距 $\ge d_0$ 的 [n,k] 码」**。
  特别地：**IMP-1（无最小距恰 14 的 [41,14] 码）等价于 $d_2(41,14)\le13$**。
  （证明与逐条更正：`work/20261020-source-corrections/SOURCE_AUDIT_CORRECTIONS.md` 引理 D、推论 D1/D2；
  独立脚本 `verify_reduction_corrections.py` 经 `cpu_job.sh` exit 0、4/4 PASS。）
- **本机阅读范围**：出版社排版 PDF 全文 8 页（pp.173–180）逐页读完，副本
  `ref/20261020-residual2020/chapter_springer.pdf`（250801 B，sha256 `c2116c209cbafc607a56c14ae310d38472027ac91a97076d87dd9bada91f002c`）；
  文本抽取 `ref/20261020-residual2020/chapter_springer_text.txt`（用于定位，非引用依据）。
  重点：p.173 定义节、p.175 Corollary 1–3、p.179 Prop.1/Prop.2/Remark 1、p.180 参考文献。
- **Prop. 2 内部链的完整依赖图（2026-10-20 更正；此前版本把缩短方向搞反了）**：
  Prop. 2 的 Corollary 3 需要「无 [41−i,15−i,**≥14**] 码」（i=1..5）。**这五条全部可由 Feulner 自己的结果推出，
  不需要码表 [7] 的任何条目**（除第 (c) 项的 (41,27) 之外）。用两条标准事实：
  **缩短事实 S**：$[n,k,d]$（$k\ge1$）必存在一个**非零列**坐标，在其上缩短得 $[n-1,k-1,\ge d]$（缩短不使距离下降）；
  **穿孔事实 P**：$[n,k,d]$（$d\ge2$，无重量 1 码字）穿孔一位得 $[n-1,k,\ge d-1]$。
  由 Feulner 的 $d_2(35,10)\le12$（他本人高亮格）出发：
  $(36,11)\le12$（S）、$(37,12)\le12$（S）、$(38,12)\le13$（P）、$(37,11)\le13$（P）、
  $(39,13)\le13$（S，由 (38,12)）、$(40,14)\le13$（S 两次，由 (38,12)）、$(36,10)\le13$（P）。
  ⇒ i=1..5 分别由 $(40,14)$、$(39,13)$、$(38,12)$、$(37,11)$、$(36,10)$ 覆盖。
  ⇒ **论文内部「=14」与 Corollary 3 的「≥d」之间的缺口就此闭合**；
  论文自述的「我们证明无 [36,11,13]、[37,12,13]」也**可由 Feulner 的无 [35,10,13] 经缩短反证推出**，
  因而不是额外的独立输入。**（此前本包写「i=1,2 需码表 [7]、叶子 Ja」是错的：缩短把长码变短，
  故「长码存在 ⇒ 短码存在」，短的被排除则长的也被排除。）**
- **本轮新增：当前 codetables.de 页面上三格上界的逐字推导（2026-10-20 抓取，HTTP 200）**
  （`work/20261020-leaf-source/LEAF_SOURCE_REPORT.md`，引文自检 13/13 FOUND）：

  | 格 | 页面给出 | 页面写出的推导（逐字） | 参考标记（逐字） |
  |---|---|---|---|
  | (42,16) | lower 12 / upper **13** | "Ub(42,16) = 13 follows by a one-step Griesmer bound from: Ub(28,15) = 6 otherwise adding a parity check bit would contradict: Ub(29,15) = 7" | "Ja: D.B. Jaffe, Binary linear codes: new results on nonexistence , 1996, code.ps.gz ." |
  | (41,14) | lower 12 / upper **14**（旧表，未反映 IMP-1） | "Ub(41,14) = 14 follows by a one-step Griesmer bound from: Ub(26,13) = 7" | "Pu2: C.L.M. van Pul, [26,13,8] does not exist, priv. comm. 1985." |
  | (42,27) | lower 6 / upper **7** | "Ub(42,27) = 7"（**无推导**，只有断言） | "Ja: ..." |
  | (41,27) | lower 6 / upper **6**（精确） | "Ub(41,27) = 6 otherwise adding a parity check bit would contradict: Ub(42,27) = 7" | "Ja: ..." |

  ⇒ **两点结论**：(i) Prop. 2 引用的「no [41,27,>=7]」在码表页上的**完整含义本轮被逐字固定**：
  $d_2(41,27)\le6$ 来自 $d_2(42,27)\le7$（加一位校验位），而后者是 Jaffe 1996 条目；
  (ii) **本 case 的公开上界 Ub(42,16)=13 同样溯源到 Jaffe 的 (29,15) 条目**（即 U1 叶子）。
  **订正（第五轮，外层审阅第 4 条）**：第四轮据此写「(29,15) 已由 IMP-3 核实到原文级 ⇒ 起点上界不再是未核实叶子」
  ——**该说法撤回**。本地 ISIT 1998 文件是**第三方 OCR 转录**（`FORMAL_SPEC.md` v3 §外部依赖 U1 明文**不批准**升级），
  且两份本地副本 sha256 相同（`72360e9e…`）⇒ 仍是同一份第三方证据。⇒ **U1（$d_2(29,15)\le7$）保持 pending**，
  本 case 的公开上界仍是 **derived-only**。
- **第四轮的「残码替代路线」已撤回（第五轮，外层审阅第 1–3 条）**：第四轮写入本包的
  「用残码论证 + IMP-3 闭合 d=14/15/16 与『含重 14 码字』情形」「剩余谱限于 {13}∪{≥17}」等结论**全部不成立**。
  根因两条：(i) 残码距离下界是 $d-\lfloor w/2\rfloor$（$d$ 为**实际最小距**），第四轮在 $w>d$ 时误用 $w$；
  (ii) 第四轮的验算程序实际 **exit 1**，且「偶性差别」是脚本错误的产物。
  **订正后的事实与逐档表见 `work/20261020-residual-route/RESIDUAL_ROUTE.md`（已重写为撤回记录 + 订正版）**，
  其逐档表与 `FORMAL_SPEC.md` v3 §辅助结论 R 一致：$d=13\Rightarrow[29,15,\ge7]$（**不排除**）、
  $d=14\Rightarrow[28,15,\ge7]$、$d=15\Rightarrow[27,15,\ge8]$、$d=16\Rightarrow[26,15,\ge8]$。
  ⇒ **该路线不产生新结果**（$d=14$ 档只是重现 codetables 自己写下的 Ub(42,16)=13 推导），
  **主证明仍是 PARITY-2SHORT + IMP-1**。
- **唯一的传递依赖（不得泛称「完全脱离 Jaffe」）**：Prop. 2 证明中用到码表输入「无 [41,27,≥7]」，
  在码表页上沿上界链回溯为 `Ub(41,27)=6 ⟵ (加一个校验位) ⟵ Ub(42,27)=7 ⟵ **Ja**（D. B. Jaffe, *Binary linear codes:
  new results on nonexistence*, 1996, `code.ps.gz`）——**这是 Prop. 2 证明落到 Jaffe 的唯一一处**
  （此前版本误称有两处，源于把缩短方向搞反；见上一条）。
  逐行追溯见 `work/20261020-source-corrections/DEPENDENCY_CHAIN.md`，码表页副本
  `work/20261020-prop2-consistency/html/ct_n41_k27.html`。
  **本轮补充（逐格定位，见 `work/20261020-feulner-chain/FEULNER_CHAIN.md`）**：本地码表快照里
  (41,27) 一格的表值就是 **6（精确）**、(42,27) 一格是 **6 – 7**，且**两格都没有推导注释**；
  而链上其余每一格（(35,10)、(36,11)、(37,12)、(38,12)、(36,10)、(37,11)）都带本表自己的推导注释，
  可回溯到 Feulner 本人的「无 [35,10,13]」。~~⇒ 未回原文核实的对象 = **恰好一个标量** $d_2(41,27)\le6$。~~
  **第五轮撤回该说法**（外层审阅第 5 条）：**注释一致性只核实表内容与格间推导关系**，不等于核实了全部依赖；
  Prop. 2 应作为**整体已发表 import** 接受，其内部未独立核查的输入清单见 §2 的「(a)–(d)」四項。
  ⇒ **本候选结论的 import 链包含一个「原文未核实」的码表叶子**：Jaffe 1996 的 `code.ps.gz`
  （**本轮取回失败**：作者页 404；存档服务在本沙箱被代理阻断；2000 年 *Discrete Mathematics* 223:135–155
  期刊版正文直连 403，仅取得摘要；取回尝试全表见 `work/20261020-jaffe-leaf/JAFFE_LEAF_REPORT.md`）。
  该叶子与本 case 原 U1 叶子（$d_2(29,15)\le7$，同一文件的另一条目）**同源但不同条目**；
  **订正（第五轮）**：U1 **未**取得原文级核实（第三方 OCR，依 FORMAL_SPEC 保持 pending，见 §2 的 IMP-3 订正）；**(42,27)/(41,27) 同样只有派生证据**（码表页转述）。
  **在取得 Jaffe 1996/2000 原文或该表项的独立可核证之前，不得把本结论说成「完全自足」。**
- **该命题证明所依赖、但本机未重跑的部分**（如实标注为作者的断言）：
  (a) Feulner 无 [35,10,13]；(b) 作者自证无 [36,11,13]、[37,12,13]；
  (c) Grassl 码表「无 [41,27,≥7]」；(d) 程序 Generation/DimExtension 的穷举：209 个 even [35,9,14] 码
  （对偶距离 ≥3）全部不可扩展，输出 `RES 0, Elapsed time: 432m`。
  **这只是已发表的 import，不是本机的独立证书**；本机未复跑该计算（`DimExtension` 当前无公开下载）。
  其中 (a)(b) 的**数值**可由 Feulner 2014 学位论文附表独立佐证（见下），但作者的 432 分钟计算本机**未复跑**。
- **勘误/后续更正**：本轮检索（Springer 页面、Crossref、PMC、作者软件页、web 检索）未发现勘误或更正；
  「未查到」不等于「不存在」，检索范围记录于 `work/20261020-prop2-source/SOURCE_AUDIT.md` 与
  `work/20261020-prop2-consistency/`（若该目录本轮已生成）。
- **书目更正**：上一轮交接中写作「Bigatti, Carette, Davenport, Joswig, de Wolff 等，Mathematics 2020」**有误**——
  Bigatti/Carette/Davenport/Joswig/de Wolff 是该书**编者**，本文作者为 Bouyuklieva & Bouyukliev；
  Crossref 作者列表为 2 人。35-10 case 引用的 “Mathematics 8(11):2207” DOI 在 Crossref 返回 404（未改兄弟 case 文件，仅记录）。

**IMP-2（旁证/支撑 IMP-1 的输入）.** T. Feulner, *Classification and nonexistence results for linear codes with
prescribed minimum distances*, Des. Codes Cryptogr. **70** (2014) 127–138；以及其学位论文
**Thomas Feulner, *Eine kanonische Form zur Darstellung äquivalenter Codes – Computergestützte Berechnung und ihre
Anwendung in der Codierungstheorie, Kryptographie und Geometrie*, Dissertation, Universität Bayreuth, 2014, IX + 176 S.
（**题名更正**：上一轮把学位论文登记成了 DCC 论文题名；学位论文正文页 = PDF 页 − 12，共 188 PDF 页；见
`work/20261020-source-corrections/BIBLIOGRAPHY_FIX.md`），
其附表「Updated bounds for GF(2)」（本地副本 `ref/20261020-imports/feulner-dissertation-cd-results-ub2.html`，
sha256 `00a46f9503fcfc51c5f9782495e52edfd98bd91a99bf00e3d0fb1f736e32a848`；表项语义见印刷 p.140 / PDF p.152）。
该表逐项给出上界与其推导，例如

| (n,k) | 表值 | 表内推导 |
|---|---|---|
| (35,10) | 12 | [T. Feulner, DCC 2014] |
| (36,10) | 13 | Puncturing to [35,10,13] |
| (36,11) | 12 | Shortening to [35,10,13] |
| (37,11) | 13 | Puncturing to [36,11,13] |
| (37,12) | 12 | Shortening to [36,11,13] |
| (38,12) | 13 | Puncturing to [37,12,13] |
| (35,9)  | 14 | —（表值 $d_2(35,9)=14$，故「even [35,9,14]」与「even [35,9,≥14]」是同一集合，与 IMP-1 的 209 码输入集自洽）。**归属：未高亮 ⇒ 继承自码表，非 Feulner 自己的改进** |
| (41,14) | 12 – 14 | （旧上界，2020 年被 IMP-1 改进为 ≤13）**未高亮 ⇒ 继承自码表** |
| (42,16) | 12 – 13 | （旧上界）**未高亮 ⇒ 继承自码表** |
| (29,15) | 7 | **未高亮 ⇒ 继承自码表**；Feulner 论文与学位论文全文均未出现 (29,15)，参考文献亦未提 Jaffe ⇒ **不能**用 Feulner 独立支持 U1 |
| **(41,27)** | **6**（精确值） | **无推导注释 ⇒ 该表在此只是断言**；这正是 Prop. 2 引用的「无 [41,27,≥7]」（该格即 d⊥=6 的依据） |
| **(42,27)** | **6 – 7** | **无推导注释 ⇒ 断言**；上界 7 ⇒ 无 [42,27,8]（与当前 codetables.de 的 `Ub(42,27)=7`、参考标记 `Ja` 一致） |

**本轮新增的逐格机器可核提取（2026-10-20）**：`work/20261020-feulner-chain/`
  （`extract_feulner_chain.py` + `feulner_cells.json` sha256 `33b5151a…` + `extract_feulner_chain.out` +
  `FEULNER_CHAIN.md`）。该脚本把快照的**全部 2278 格**按 `title` 属性解析成 (表值, 推导注释) 并对**所有 64 个带推导注释的格**
  做一致性检查（穿孔格：目标距离 = 上界；缩短格：目标距离 = 上界+1，且 n 降 1、k 降 1）——**不一致 0 格**。
  **订正（第五轮，外层审阅第 5 条）**：第四轮据此写「未回原文核实的数值输入被精确收敛为**一个标量**」
  ——**该说法撤回**。64 条注释一致性检查只核实了**表内容与格间推导关系**，并不等于核实了全部依赖。
  **Prop. 2 作为整体已发表 import 接受，其内部未独立核查的输入如实列全**（四项）：
  (a) Feulner 无 [35,10,13]（表内归属他的 DCC 2014 论文；本地有作者预印本
      `ref/20261020-imports/feulner-nonexistence-preprint.pdf`，其 Table 1 含该条 —— **本机已见**，但未逐字回该文核对）；
  (b) **$d_2(35,9)=14$**（表内**无推导注释、继承自码表**）—— 它是**载荷性的**：Prop. 2 用「even [35,9,14] 码集」
      作为 209 码的输入集，只有在该值恰为 14 时「最小距恰 14」与「最小距 ≥14」才是同一集合；本 case **未**展示
      它可由 Feulner 的 (35,10) 结果推出（Griesmer 对 (35,9) 只给 $d\le16$，不足以推出 14）；
  (c) **$d_2(41,27)\le6$**（= $d_2(42,27)\le7$ 经加一位校验位；两格**均无推导注释**，参考标记 `Ja`）—— 原文未取得；
  (d) 作者的 **209 码 Generation 枚举**与 **432 分钟 DimExtension 搜索**（本机**未复跑**，`DimExtension` 无公开下载）。
  ⇒ **不得**声称「只剩一个未核标量」；正确表述是：Prop. 2 的**定理陈述**被作为已发表 import 引用，
  其**内部依赖**含上述 (b)(c) 两项继承自码表且无推导的数值，以及 (d) 作者的未复跑计算。

表项语义（已核到原文级，`work/20261020-source-corrections/FEULERN_TABLE_AUDIT.md`）：
表值是 $d_2(n,k)$ 的**上界**；「a-b」读作 [lb, ub]；**高亮格（n=1..68 × k=1..67 共 2278 格中共 80 个）表示该格是作者自己的改进**
（但**「高亮 = Feulner 自己的」这一说法过强**：其中 2 格归属 Bouyukliev–Jakobsson, arXiv:1006.0109），
`Puncturing/Shortening to [...]` 是推导路径（学位论文 PDF p.152 / 印刷 p.140；其参考文献 [31] 即 Grassl 码表，PDF p.185）。
故 Feulner 的「无 [35,10,13]」在 $\ge$ 语义下为 $d_2(35,10)\le12$，正是 IMP-1 证明链所需；
而 (41,14)(42,16)(40,14)(43,16)(35,9)(29,15) 等格**未高亮**，属继承的码表值，引用时不得说成 Feulner 的结论。

**IMP-3（本 case 自身的 U1 叶子；**第五轮已撤回「原文级已核实」的升级，恢复为 pending**）.**
D. B. Jaffe, *Optimal binary linear codes of length ≤ 30*, ISIT 1998（IEEE Int. Symp. Inf. Theory），
§I "BRIEF SYNOPSIS OF THE RESULTS"，该句**逐字出现在**本地副本 `ref/20261020-imports/jaffe_isit1998_spacefrontiers.html`
（**第三方 OCR 转载本，非出版社/作者原始文件**；该 HTML 的 `<link rel="canonical">` 指向
`https://machinelibrary.ai/r/10.1109/isit.1998.708596`，2026-10-20 grep 确认）：

> "no 29,11,10 code, exactly one 28,14,8 code, and no 29,15,8 code"

⇒ 这句话出现在本地**第三方 OCR 转载片段**中（**来源未核**：出版社/作者原始文件从未在本机取得），
对「无 [29,15,8] 码」的陈述因此**不构成原文级证据**；结合本包的**引理 D**（无最小距恰 $d_0$ ⇒ 无最小距 $\ge d_0$）
⇒ $d_2(29,15)\le7$（即原 U1）。~~**本 case 的 U1 由此升级为原文级已核实**~~
**第五轮撤回该升级**（外层审阅第 4 条）：本地副本是第三方 OCR ⇒ U1 **保持 pending**（详见本节末尾的订正）。
**注意**：该 ISIT 1998 文只覆盖长度 ≤ 30 的码，**不含 (42,27)**；
Jaffe 1996 预印本 `code.ps.gz` 与 2000 年 *Discrete Mathematics* 期刊版全文本机取不到，
故 **(42,27)/(41,27) 叶子仍未核实**。取回尝试全表与引文自检（8/8 逐字命中）见
`work/20261020-jaffe-leaf/{JAFFE_LEAF_REPORT.md,extracted_entries.txt,verify_quotes.out}`。

---

- **订正（第五轮，外层审阅第 4 条）**：第四轮把本条升级为「原文级已核实」并据此推出
  「本 case 的公开上界 Ub(42,16)=13 可追到原文级」——**该升级与该推论一并撤回**。
  理由：本地 ISIT 1998 文件是**第三方 OCR 转录**（`FORMAL_SPEC.md` v3 §外部依赖 U1 明文「**不批准**升级为原文完全核实，
  U1 保持 pending」）；`ref/20261020-imports/jaffe_isit1998_spacefrontiers.html` 与
  `work/20261020-jaffe-leaf/raw/t91_jaffe_isit1998_spacefrontiers_LOCALCOPY.html` 的 sha256 **完全相同**
  （`72360e9eb2e4f8a97e393b0fea250fcc4aea06e278e060ce0f020d89b31bbc17`）⇒ 仍是**同一份**第三方证据；
  所谓 2000 年期刊摘要 C2 **无本地原始文件**（逐字检查也跳过该项）；8/8 字符串命中**不能**证明来源真实性。
  ⇒ **U1 = $d_2(29,15)\le7$ 恢复为 pending（derived-only）**，一切依赖它的结论（含残码路线）同步降级。
## 3. 自证归约（无外部依赖）

### 引理 PARITY-2SHORT
**（本题版本）** 若存在二元线性码 $C\subseteq\mathbb F_2^{42}$，$\dim C=16$，最小距 $d\ge 13$，
则存在二元线性码 $D\subseteq\mathbb F_2^{41}$，$\dim D=14$，最小距**恰为 14**。

**（一般化版本，带充分条件）** 若存在二元线性码 $C\subseteq\mathbb F_2^{n}$，$\dim C=k\ge16$，
最小距 $d\ge13$，则存在二元线性码 $D\subseteq\mathbb F_2^{\,n-1}$，$\dim D=k-2$，最小距恰为 14。
> **$k\ge16$ 不可省略。** S3 的秩论证给出 $\dim\operatorname{span}\{g_j:j\in Z\}\ge k-|W|$，
> 而 $|W|\le14$，故只有 $k\ge16$ 才能保证 $Z$ 中存在两列线性无关。
> 反例（$k<16$）：重复码 $[13,1,13]$ 的奇偶扩展为偶 $[14,1,14]$，其重 14 码字在 13 个原坐标上全为 1，
> 故 $Z=\varnothing$，无法选出独立列对。**上一版证明包把引理写成对任意 $k$ 成立，是错误的**（外层审阅已指出），
> 本版已限定。

#### S1 距离下降（把 $d$ 归一到恰 13）
设 $d>13$，取最小权码字 $c$（$\mathrm{wt}(c)=d$），取 $T\subseteq\mathrm{supp}(c)$，$|T|=d-13$。
在 $T$ 上穿孔得 $C^T$：
- **单射性**：若 $x\in C$ 的支撑含于 $T$，则 $\mathrm{wt}(x)\le |T|=d-13<d$，故 $x=0$；因此 $\dim C^T=k$。
- **距离**：穿孔使最小距至多降 $|T|$，故 $d(C^T)\ge d-|T|=13$；而 $c$ 的像重 $13$，故 $d(C^T)\le 13$。
  于是 $d(C^T)=13$ 恰。
再补 $|T|$ 个零列得 $C'\subseteq\mathbb F_2^n$，$\dim C'=k$，$d(C')=13$ 恰。
（$d=13$ 时本步是恒等。）故此后可设 $d=13$。

#### S2 奇偶扩展
$C^e=\{(x,\ \textstyle\sum_i x_i):x\in C'\}\subseteq\mathbb F_2^{\,n+1}$。
线性、$\dim=k$；每个码字重量为偶（$w\mapsto w+(w\bmod 2)$）；
因 $d(C')=13$，重量 13 的码字扩展后重量 14，而任何码字重量 $\ge13$ 且为偶，故 $d(C^e)=14$ 恰。

#### S3 双缩短（保留最小距恰为 14）
设 $G^e$ 为 $C^e$ 的 $k\times(n+1)$ 生成矩阵，列 $g_1,\dots,g_{n+1}\in\mathbb F_2^k$；
$g_{n+1}=\sum_{j\le n}g_j$（校验列），且 $\dim\mathrm{span}\{g_1,\dots,g_{n+1}\}=k$。
取 $c\in C^e$ 重量恰 14（存在，因 $d(C^e)=14$）。在**原坐标** $1..n$ 中令
$W=\{j\le n: c_j=1\}$，$Z=\{j\le n: c_j=0\}$，$m=|W|\in\{13,14\}$（$m=14-c_{n+1}$）。
因为 $g_{n+1}\in\mathrm{span}\{g_1..g_n\}$，有 $\dim\mathrm{span}\{g_1,\dots,g_n\}=k$；
故
$$\dim\mathrm{span}\{g_j:j\in Z\}\ \ge\ k-\dim\mathrm{span}\{g_j:j\in W\}\ \ge\ k-m\ \ge\ k-14 .$$
由于 $m\le14$ 且本 case $k=16$，得 $\dim\mathrm{span}\{g_j:j\in Z\}\ge k-14=2$（一般地要求 $k\ge16$）。
故 $Z$ 中存在两个线性无关的列 $g_i,g_j$。
令 $D_0=\{x\in C^e: x_i=x_j=0\}$：映射 $u\mapsto (u\cdot g_i,\,u\cdot g_j)$ 满射，故 $\dim D_0=k-2$；
$c\in D_0$（因 $c_i=c_j=0$）且 $D_0\subseteq C^e$ 中所有码字重量 $\ge14$，故 $d(D_0)=14$ 恰。
删去坐标 $i,j$（在 $D_0$ 中恒为 0，重量不变、线性保持）得 $D\subseteq\mathbb F_2^{n-1}$，
$\dim D=k-2$，$d(D)=14$ 恰。∎

**注（不使用任何结构假设）**：以上三步**不要求**生成矩阵列非零、不要求列互异、不要求自同构、
不预设母码/固定残码/对称子族；只用到「秩」与「重量」。

#### 引理的数值验证（覆盖范围如实说明）
`work/20261020-prop2-proof/verify_reduction.py`（纯 stdlib，不 import 本仓库其它脚本，全部 $2^k$ 码字穷举）：
对 7 个测试码例（截短 simplex 码族，含 $d=13,14,15,16,28,29$ 等）逐步执行 S1/S2/S3 的机械判据，
并断言：S1 后长度/维数/最小距恰 13；S2 后全偶且最小距恰 14；S3 后维数恰 $k-2$、长度恰 $n-1$、最小距恰 14；
另设两个**反向对照**（$d<13$ 的码不得进入流程；最小距非 14 的码不得被判为 S3 成功）。
运行：`python3 work/20261020-prop2-proof/verify_reduction.py` → **exit 0**，
日志 `work/20261020-prop2-proof/logs/verify_reduction_direct.log`（同脚本另经 `cpu_job.sh` 单线程跑过一次）。

**覆盖范围的诚实说明（外层审阅要求）**：这 7 个用例的维数只有 $k=5,6,7$（**不含本题的 $k=16$**），
且 7 例的 S3 中 $|W|$ 全为 13；它们验证的是**机制**（S1/S2/S3 的机械判据与代数恒等式），**不**验证本题的 $k=16$ 情形。
覆盖 $k=16$ 精确参数的是另一套独立实现 `work/20261020-prop2-redteam/redteam_checks.py`：
在 $k=16$ 的 BCH [127,16,≥13] 族上（含 S1 输出的真 [127,16,13]、加零列、加**重复列**、加首位零列）全部判据通过，
另对小参数二元线性码做**分层穷举**（**口径以 `REDTEAM_REPORT.md` §2.2 为准**：
124,208 是**枚举出的生成矩阵数**（含秩亏与重复表示）→ 114,424 满秩 → **10,981 个不同码** → 6,785 个 $d\ge3$；
其中**进入充分条件分支者 0**（该段只覆盖机制）；随机搜索 40,000 次 / 保留 18,161 / 进入充分条件分支 6,946 / **违反 0**），
并用 4 个变异体证明判据有区分力（4/4 检出，判据失败全部来自实际列秩/见证/参数检查）；
其报告 `work/20261020-prop2-redteam/REDTEAM_REPORT.md` 记录了两处「失败」实为脚本复制了**行**而非**列**的构造缺陷（已修复，修复后全过），
以及 $k<16$ 的边界反例（$[13,1,13]$）。**两套实现互相独立**（不同作者、不同代码、不同秩算法）。

---

## 4. 主定理

**定理.** 不存在二元线性 [42,16,$\ge13$] 码；且 $d_2(42,16)=12$。

**证明.** 设 $C$ 是二元线性 [42,16,$d$] 码，$d\ge13$。由引理 PARITY-2SHORT（$n=42,k=16$）
得二元线性码 $D\subseteq\mathbb F_2^{41}$，$\dim D=14$，最小距**恰为 14**，即 $D$ 是一个 [41,14,14] 码。
这与 IMP-1（Prop. 2：二元线性 [41,14,14] 码不存在）矛盾。故 $\neg E(13)$，即 $d_2(42,16)\le12$。
另一方面本 case 已独立复算的显式 16×42 矩阵给出 $d_2(42,16)\ge12$
（`candidates/qr-seed-verified.json`；独立复算 `work/20261020-baseline-recheck/baseline_recheck.json`：
rank 16、全 65535 个非零消息的完整谱 $\{12:675,16:9898,20:30659,24:21056,28:3161,32:85,36:1\}$、最小权见证）。
故 $d_2(42,16)=12$。∎

**推论.** (i) 不存在偶 [43,16,14] 码；(ii) $d_2(43,16)\le13$（否则穿孔一位得 [42,16,$\ge13$]）。

---

## 5. 覆盖范围、语义讨论与与 FORMAL_SPEC 的关系

1. **归约的覆盖域**：主定理的反面是「存在某个 16×42 二元矩阵，秩 16，全部 65535 个非零消息重量 $\ge13$」。
   本证明的推理对**任意**这样的矩阵成立（引理只用秩与重量），因此不附加任何未经无损归约证明的结构限制，
   满足 FORMAL_SPEC「不存在性验收」对「覆盖全部满足秩 16、全部非零消息重量 ≥13 的 16×42 二元矩阵」的要求。
2. **exact vs $\ge$ 的语义风险已被规避（且二者其实等价）**：IMP-1 的字面陈述是「无最小距恰为 14 的 [41,14,14] 码」。
   本引理刻意产出**最小距恰为 14** 的码，故无论命题按 exact 还是 $\ge$ 解读都被覆盖。
   进一步，由 §2 的**距离下降法**（引理 D / 推论 D1）：「无最小距恰 $d_0$ 的 [n,k] 码」⇒「无任何最小距 $\ge d_0$ 的 [n,k] 码」，
   故 **IMP-1 的字面（exact）陈述本身已等价于 $d_2(41,14)\le13$**；两处旧判断
   「[41,14,≥15] 不蕴含 [41,14,14]」「d=15 需另找叶子」**均为假**，其技术原因是漏了「穿孔后补 0 列还原长度」这一步。
3. **上一轮 SOURCE_AUDIT 的一处结论需要修正**：`work/20261020-prop2-source/SOURCE_AUDIT.md` 断言
   「d=15 分支不被 Prop. 2 覆盖 ⇒ Prop. 2 不能单独闭合本 case」。该断言**忽略了 S1 距离下降法**：
   由 [42,16,15] 出发，先在最小权码字支撑上穿孔 2 位并补 2 个零列，即得 [42,16,13]（最小距恰 13），
   再走 S2/S3 即得 [41,14,14]。因此 $d\in\{13,14,15,16\}$（乃至任意 $d\ge13$）全部被覆盖。
   该修正已写入 `work/20261020-prop2-redteam/` 的对抗复核（若本轮已生成）。
4. **Prop. 2 证明链内部的 ≥ 语义（2026-10-20 二次更正：缺口已闭合）**：Corollary 3 的假设形式是
   「无 [n−i, k−i+1, $\ge d$] 码」，论文写作「no linear [41−i,15−i,14] codes exist for 1≤i≤5」。
   由**推论 D1**（无最小距恰 $d_0$ ⇒ 无最小距 $\ge d_0$）+ **缩短事实 S**（长码存在 ⇒ 短码存在）+ **穿孔事实 P**，
   Feulner 的 $d_2(35,10)\le12$ 一条即覆盖 i=1..5 的 $\ge14$ 形式：
   $(36,11)\le12$（S）、$(37,12)\le12$（S）、$(38,12)\le13$（P）、$(37,11)\le13$（P）、
   $(39,13)\le13$（**S，由 (38,12)**）、$(40,14)\le13$（**S 两次，由 (38,12)**）、$(36,10)\le13$（P）。
   ⇒ **论文内部的「=14」与 Corollary 3 的「≥d」之间的措辞落差不是缺口**；
   ⇒ **Prop. 2 落到 Jaffe 码表叶子的地方只剩一处**：$d_2(41,27)\le6$（见 §2）。
5. **与 FORMAL_SPEC 的关系**：FORMAL_SPEC 假定 $E(14)$ 不成立（经 U1→U2→U3 链，U1 原文未核、仍 pending）。
   本候选结论**更强**（直接排除 $E(13)$）且**不依赖** U1/U2/U3 这三条链，
   因此 U1 的 pending 状态**不再是主结论的障碍**；
   但 U1/U2/U3 仍应作为独立条目保留在 `CASE.json.imports_pending`（它们仍是各自邻格上界的依赖）。
   **需要同时记录的诚实事实**：本候选结论的 import 链里另有一个**原文未核实的码表叶子**——
   Prop. 2 证明里用到的 $d_2(41,27)\le6$，其叶子是 Jaffe 1996 的 `code.ps.gz`（经 `Ub(42,27)=7`）。
   该叶子与 U1 叶子（$d_2(29,15)\le7$）**同源但不同条目**；U1 仍 pending。
6. **未做的部分**（明确列出）：本机**未复跑**作者的 209 码枚举与 432 分钟 DimExtension 搜索；
   **proof-checker 正式审计未做**（GPT 调用按规则合并到轮末一次检查；10 项清单已备于
   `work/20261020-prop2-proof/PROOF_CHECKER_CHECKLIST.md`）；
   **跨家族审阅已做两轮但都针对第三轮版**：Grok（NEEDS_REVISION，3 项已修）与 Gemini（PASS，8/8，issues 为空）；
   **对第五/第六轮订正版的复审**：本轮已补 Gemini 对**精确变更集**的只读复审（见 §5.9），未改动的 S1–S3 沿用其结论；
   **Jaffe 1996 码表叶子（(42,27)→(41,27)）原文未核**。
7. **优先权/新颖性义务（新增，因本轮一致性检索的结果）**：
   `work/20261020-prop2-consistency/CONSISTENCY_REPORT.md`（及其 §0 勘误表）报告——(a) 2026-10-20 在 codetables.de
   现场抓到的二元表值 d_2(41,14)≤14、(42,16)≤13、(40,14)≤13、(43,16)≤14，与本地 2011 快照**逐字节相同**
   （**这只说明本次抓到的版本较旧；两次快照同在 2026-10-20 取得，MD5 相同不能证明数据自 2011 年冻结，
   也未排除其它站点存在更新版**）；(b) **在已实际读取的来源中未发现** d_2(41,14)≤13 的复述
   （两条引用文献**全文未取得**，仅凭摘要不足以断言；arXiv 题名检索零命中、作者检索因拼写错误作废、
   两次 S2 参数检索 429 限流——这些**失败项属未覆盖**）；(c) 在已查来源中未发现反例、相反结果、勘误或撤稿
   （Springer 0 命中；Crossref updates total-results=0；OpenAlex is_retracted=false）。
   ⇒ 本候选结论 **严于本次抓到的码表值**（d_2(42,16)≤12 vs 该表 ≤13）。按 ACTIVE_GOAL「宣称新界前另查当时权威来源」，
   **d_2(42,16)=12 的优先权复查是未解义务**（`work/20261020-prop2-priority/` 在做）；
   **在复查完成前，本包只主张「由 2020 年已发表结果 Prop. 2 可推出 d_2(42,16)≤12」，不主张新颖性/优先权**。
   检索范围、失败项与未访问项（MDPI 403、zbMATH 403、DBLP 202、arXiv/S2 失败、未访问 Google Scholar /
   web.archive.org / 付费墙正文）记录在 `work/20261020-prop2-consistency/sources.json` 与
   `work/20261020-prop2-priority/`。

### 5.8 跨家族（Grok）只读审阅的结论与修复（2026-10-20 18:2x–18:4x）
审阅者：**Grok**（grok-4.7，high），只读，原始记录 `reviews/20261020-grok-crossfamily/{GROK_REVIEW.md,verdict.json}`。
verdict = **NEEDS_REVISION**（1 项 medium + 2 项 low），**三项均已在本轮修复**：
1. **[medium] 本文件 §6 验收表曾写「一致性检索已完成（无冲突、无勘误、码表无更新版本）」——与 §5.7 的限定表述矛盾（属全称判断）**
   ⇒ 已改为「**已查来源中未发现**冲突/勘误/撤稿，也未在被查端点发现码表更新版；优先权复查已做，但不主张新颖性/优先权」。
2. **[low] 红队实例标注**：标为「BCH [127,16,13] 精确参数」的实例，其**实际最小距是 15**（d=13 分支来自 S1 的输出）
   ⇒ 已改标为「BCH [127,16,15]（S1 把 15 降到 13，即 d=13 分支）」，并**新增** `D_at_tau13_path_exact_parameters`
   （由 S1 输出 [127,16,13] 出发 ⇒ 偶扩展 ⇒ 双缩短 ⇒ **[126,14,14]**，全偶、全判据通过，谱首项 14 出现 2 次），
   原「原始 BCH 扩展」那条改名为 `D_from_raw_bch_extension_NOT_the_tau13_path` 并加注说明。
3. **[low] k=5 extended simplex 的「预期 S3 失败」注释不成立**（重跑为 PASS）
   ⇒ 已删除该断言，并写明 **k≥16 是证明所用的充分条件、不是必要条件**（该实例 rZ=4，链仍成功）；
   真正否定「无限制一般陈述」的反例仍是 k=1 族（如重复码 [13,1,13]）。
另：Grok 确认 S1–S3 在 (n=42,k=16,d≥13) 上成立、未使用零列/互异列/自同构/固定残码假设，Prop.2 字面陈述与归约产出一致，
并独立复算了本地种子（rank 16、完整谱、最小权见证 0x1）。Grok 同时明确：**这不等于 FORMAL_SPEC 验收通过，也不能标 solved-***。

---

### 5.9 跨家族（Gemini）对**第六轮精确变更集**的只读复审（2026-10-20 20:05–20:13）

- **范围**：只审第六轮的**精确变更集**（15 个文件，`reviews/20261020-gemini-round6-changeset/INPUT_MANIFEST.sha256`
  逐文件 sha256 绑定，`hash_check.out` 记录 **15/15 OK**）；**未改动的 S1–S3 沿用**第三轮 Gemini 的 8/8 PASS
  （`reviews/20261020-gemini-crossfamily/`），不重审。
- **结论**：verdict = **NEEDS_REVISION**（3 条**文本级**问题，**无数学问题**）：§5.9 悬空引用（由本小节补齐）、
  「124,208 个码穷举」旧口径残留 2 处、FEULNER_CHAIN 章节编号重复 1 处。三条**已在本轮就地修复**。
- **子代理进程状态**：该 Gemini 子代理在写完报告后**流断开**（`stream disconnected before completion`），
  `verdict.json` 由主会话**据其报告原文**转写（未改动报告内容），`hash_check.out` 为其本人运行所得。
- **重要限制**：跨家族审阅是**意见**，不替代数学证据；本包的验收仍以轮末 fresh GPT 检查的 proof-checker 审计为准。

## 6. FORMAL_SPEC 验收字段对照（不存在性方向）

| FORMAL_SPEC 要求 | 本包对应 | 证据路径 |
|---|---|---|
| 覆盖全部秩 16、重量 ≥13 的 16×42 矩阵 | 主定理对任意这样的码成立；不设结构限制 | §3 引理、§4 定理 |
| 严格数学证明 或 完备可检证书 | 严格数学证明（1 条外部 import + 1 条自证引理） | 本文 |
| 外部结果回原文、记定理/条件/阅读范围、列为 import | IMP-1 逐字引用、页码、sha256、适用域、作者未重跑部分均列出 | §2 |
| 宣称新界前另查当时权威来源 | **已查来源中未发现**冲突/勘误/撤稿，也未在被查端点发现码表更新版；**优先权复查已做**（结论同为「已查来源中未发现」），但**不主张新颖性/优先权** | §5.7、`work/20261020-prop2-consistency/`、`work/20261020-prop2-priority/` |
| 归约、对象编码、覆盖、拒绝判定、输入绑定 | 归约为纯数学（§3）；无枚举编码（因此无编码/漏检问题） | §3、§5.1 |
| 显式证据（矩阵、完整谱、最小权见证、独立复算） | 下界 $d_2\ge12$ 的显式 16×42 矩阵 + 完整谱 + 最小权见证 + 独立复算 | `candidates/qr-seed-verified.json`、`work/20261020-baseline-recheck/` |
| proof-checker 正式审计 | **未做**（GPT 调用按规则合并到轮末一次检查；10 项清单已备） | `work/20261020-prop2-proof/PROOF_CHECKER_CHECKLIST.md` |
| 跨家族审阅 | **按版本分三段记账**：① 第三轮核心审阅——Grok（grok-4.7，high，只读）verdict = **NEEDS_REVISION**（1 项 medium + 2 项 low），**三项均已修复**（见 `reviews/20261020-grok-crossfamily/` 与本文件 §5.8）；Gemini（gemini-3.8-flash，high）**PASS 8/8**（同一第三轮版）；② 第六轮**变更集**审阅——Gemini 只读复审第六轮精确变更集（输入哈希绑定），verdict = **NEEDS_REVISION**，**3 条文本级问题已修**；③ **第七轮文本订正后的复审未做**（并入轮末唯一一次 GPT 检查） | `reviews/20261020-grok-crossfamily/`、`reviews/20261020-gemini-crossfamily/`、`reviews/20261020-gemini-round6-changeset/` |

---

## 7. 证据文件清单

- 原始文献：`ref/20261020-residual2020/chapter_springer.pdf`（+ `.txt` 抽取、12 个公式 GIF、MANIFEST）
- 来源审计：`work/20261020-prop2-source/SOURCE_AUDIT.md`、`sources.json`、`prop2_excerpts.txt|json`、`http_status_log.txt`
- Feulner 附表：`ref/20261020-imports/feulner-dissertation-cd-results-ub2.html`
- 引理数值验证：`work/20261020-prop2-proof/verify_reduction.py`、`logs/verify_reduction_direct.log`
- 下界基线独立复算：`work/20261020-baseline-recheck/baseline_recheck.json`、`lemma_selfcheck.json`、`qr_chain_check.py`
- 对抗复核：`work/20261020-prop2-redteam/`（若本轮已生成）
- 一致性检索：`work/20261020-prop2-consistency/`（若本轮已生成）
