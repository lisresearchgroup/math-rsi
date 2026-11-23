你是查新审阅者（novelty check，Phase C），只读。本提示自足：没有 preflight.json / ROUND_MANIFEST.json / handoff，不必寻找。输出用中文 Markdown 自由格式（不要只回 JSON），最后一行给出 `RECOMMENDATION: PROCEED` / `PROCEED WITH CAUTION` / `ABANDON` 之一。

## 待查新的结果

不存在二元线性 [41,12,≥15] 码（等价地，不存在偶 [42,12,16] 码），因此 d₂(41,12)=14、d₂(42,12)=15。方法：偶码化；对偶最小重量 w∈{4,5,6}；在重量 w 的对偶字支撑上缩短到已分类的母码 [38,9,16]（47 类）、[37,8,16]（17276 类）、[36,7,16]（8170 类）；对每个母码穷尽检查 w−1 个陪集头的全部子集和的陪集深度条件。结论依赖两条文献进口：无 [39,10,16]（JCMCC 59 (2006) Lemma 4）与 2025 年的分类类数（Mathematics 13:2491）。证明正文在 `/home/user/math/aris4math_v2/cases/41-12/PROOF.tex`。

核心声明：
1. d₂(41,12) 的上界由 15 降到 14（公开表为 14–15）。
2. d₂(42,12) 的上界由 16 降到 15（公开表为 15–16）。
3. 方法：对偶最小重量三分支 + 已分类母码 + 陪集相容性穷尽（与 (43,10) 的做法同型）。

## Phase B 检索到的材料（原始抓取在 `/home/user/math/aris4math_v2/cases/41-12/work/20261123-novelty/`）

- codetables.de（Grassl），2026-11-23 抓取：[41,12] lower 14 / upper 15，上界来源 “Ub(41,12)=15 is found by considering shortening to Ub(39,10)=15 Bou”；[42,12] lower 15 / upper 16，“Ub(42,12)=16 follows by the Griesmer bound”。文件 `codetables_41_12.html`、`codetables_42_12.html`。
- Magma V2.29-10 在线计算器，2026-11-23：BKLCLowerBound/UpperBound(GF(2),41,12)=14/15；(42,12)=15/16。文件 `magma_bounds.xml`。
- 上海创智学院 2026-11-07 公告（李帅团队）：(43,10)、(44,10)、(44,11) 定值，(45,11) 收窄，(42,16) 定值；方法是对偶重量 4 的缩短 + 172 类 (40,7,18) 母码 + 陪集无和性。未提及 (41,12)、(42,12)。https://www.sii.edu.cn/2026/1109/c27a1270/page.htm
- Bouyuklieva–Bouyukliev, Classification of Linear Codes by Extending Their Residuals (ICMS 2020)：证明无 [41,14,14]，并提到无 [36,11,13]、[37,12,13] 等；未涉及 [41,12,15]/[42,12,16]。文件 `residuals_pmc.html`。
- Bouyukliev–Bouyuklieva–Kurz, Computer classification of linear codes (arXiv:2002.07826)：全文无 [41,12]/[42,12]。文件 `lincode_2002.07826.html`。
- Bouyuklieva–Dzhumalieva-Stoeva, Optimal Linear Codes and Their Hulls (2025)：分类范围 k≤10、n≤40，不含 k=12。
- Kurz, Optimal self-orthogonal binary linear codes (arXiv:2610.39870v2, 2026-11-17)：维数 ≤9 的自正交码；全文无 [41,12]/[42,12]。文件 `kurz_so_2610.39870.html`。
- Tang–Fan, There is no binary linear [65,9,29] code (arXiv:2611.24997, 2026-11-18)：维数 9、10 的结果；全文无 [41,12]/[42,12]。文件 `tang_fan_2611.24997.html`。
- Seddas–Shashkov–Viazovska–Abbe, LinCodeEvolve (arXiv:2609.37056)：7 个下界纪录码，长度 50–240，均为构造；无 [41,12]/[42,12]。文件 `lincodeevolve.html`。
- generalised.si 2026-11-16：5 个长度 111–174 的下界码；无关。文件 `generalised_si.html`。
- Kiermaier–Wassermann–Zwanzger (arXiv:1503.03394)：无 [1988,12,992] 等；无关参数。
- Bouyukliev–Jacobsson (arXiv:1006.0109)：最小距离 8、10 的码；无关参数。
- 网络检索式（均无直接命中）："[41,12,15]"/"[42,12,16]" nonexistence；"d_2(41,12)"；"n(12,16)"；Kurz/Bouyukliev nonexistence dimension 12；2026 年 nonexistence binary linear codes。

你可以读上述本地文件核对，也可以读 PROOF.tex。请回答：这个结果是否已被某篇已发表论文或预印本包含？最接近的已有工作是什么，差别是什么？检索还有哪些明显的盲区（请点名具体来源，例如某作者主页、某数据库、某会议）？

=== NOVELTY VERDICT LIMITS (these bound how you judge, never how widely you search) ===
Search exhaustively; judge calibrated. Two failures waste months equally:
passing an idea a published paper already contains, and killing a viable idea
because the territory has neighbors.
1. Proximity is information, not a verdict. Someone working nearby goes in the
   report; it is not by itself a reason to reject.
2. ABANDON has exactly one qualification: a specific published paper already
   contains this result — name that paper. No named paper, no ABANDON.
3. Crowded-but-deltaed is PROCEED: state the delta in one sentence a reviewer
   could verify. Thin or contested delta is PROCEED WITH CAUTION — say what
   would make it carry, not why it should die. CAUTION is not a safe middle:
   if you cannot name the specific thing that makes the delta thin, the
   verdict is PROCEED.
4. Concurrent or competing work is not a veto. That is a race — report it and
   let the user decide whether to run it.
5. A direct attack on a central problem is legitimate novelty when nobody has
   executed it well. "This area is hot" does not mean "this area is taken."
6. This check is an early gate, never the last one — more triage, pilots, or
   external review still stand between any idea and a paper, whatever order
   this run uses. A wrongly passed idea dies cheaply at one of them; a wrongly
   killed idea is never seen again. When torn between two verdicts, choose the
   more permissive one.
Say plainly when an idea clears the check. Do not manufacture overlap.
