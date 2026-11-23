你在做一份计算机辅助不存在性证明的**正式审计**（proof-checker Phase 1 + 1.5，独立只读）。case 目录：`/home/user/math/aris4math_v2/cases/41-12`。不要假设证明正确；作者是另一家族的模型，你的任务是找出任何会使结论不成立的漏洞。本提示是自足的：本 case 没有 preflight.json / ROUND_MANIFEST.json / handoff，不必寻找它们。

## 待审对象

- 原题与验收条件：`FORMAL_SPEC.md`（冻结；特别是“不存在性验收”与“可用等价形式与依赖”两节）。
- 证明正文（唯一正文）：`PROOF.tex`。义务台账：`PROOF_SKELETON.md`。
- 有限计算的数学定义：`work/O6_SPEC.md`。
- 进口原文：I1 的发表版扫描 `ref/lemma4-jcmcc-2006.pdf`（Lemma 4 在 PDF 第 53 页，页图与阅读记录在 `work/20261122-imports/`）；I2 的全文文本抽取 `/home/user/math/aris4math_v2/cases/45-11/work/20261020-c5/canonaug/txt/boukou-2025-optimal-linear-codes-and-their-hulls-math13-2491.txt`（§2、§5、表 A5–A7）。
- 目录与核对：`work/20261122-catalog/`（`zenodo/extracted/38_9_16.2`、`qext/run_36_7_16/36_7_16.2`、`qext/run_37_8_16/37_8_16.2`；核对实现 A 在 `check/`，实现 B 在 `check2/`）；`work/20261123-assembly/`（w=6 无重复列子集的下标表与比较）。
- 搜索实现与验证：o6 `work/20261122-o6/`（`extsearch.c`、`brute.c`、`validate.py`、`validation/REPORT.md`）；o7 `work/20261122-o7/`（`ext2.cpp`、`validate_small.py`、`REPORT.md`）；交叉验证 `work/20261122-planted/REPORT.md`；比较工具与结果 `work/20261122-compare/`。
- 全域运行的逐码原始结果：`/shared/ecc-41-12/out/{o6_37_w5,o7_37_w5,o6_36_w6,o7_36_w6}/<idx>.json`，w=4 在 `work/20261122-o6/run_38_9/` 与 `work/20261122-o7/run_38_9/`；提交脚本与台账 `work/20261122-cluster/`。
- 下界矩阵：`work/20261122-seed-e14/`。

## 必查项（对每个定理、引理、命题、计算命题逐一检查）

A. 定义：有无含义不清或前后变化的符号（特别是 depth、t 与 τ、规范伴随式、𝒦_w / 𝒦_6 / 𝒦_6^+、“等价”）。
B. 假设供给：每一次引理/命题的**应用**处，列出它的每个假设在哪里被供给，是否真的供给了（例如引理 standard(ii) 对 K 的距离假设、引理 transport 对目录覆盖的假设、引理 bridge 对偶性的假设、命题 cover 对进口 I2 对象域的使用）。
C. 算式与不等式：Griesmer 和、球填充、缩短后的长度/维数/距离、尾重 t(j)、阈值 14/12/10、min(1+|T|,1+w−|T|)≤1+⌊w/2⌋<w 与 min(2+|T|,8−|T|)≤5<6，逐个重算。
D–F.（极限交换、概率模式、渐近一致性）本文不涉及；若你认为涉及请指出，否则写不适用。
G. 边界与退化情形：对每个关键引理尝试构造反例（见下“反例红队”）。
H. 依赖一致性：有无循环论证或引用了未证结果。

另外必须回答：

1. **量词与对象域**：主定理是否覆盖 FORMAL_SPEC 的全部对象（任意秩 12 的 12×41 二元矩阵），有没有偷偷附加结构条件？w=6 分支把母码限制为“无重复列”是否由引理 mother(d) 严格证明、是否与命题 cover 和计算命题 3 的论域一致？w=4、5 分支是否确实没有用这一限制？
2. **进口的使用**：I1 的原文对象是否就是一般二元线性 [39,10,16]（恰为 16）；证明是否正确地用 Griesmer 补上了 ≥17。I2 计数的对象域（无零坐标、允许重复列、坐标置换等价、d 恰为 d₂(n,k)=16）是否与命题 cover 的用法逐条吻合；“N 个两两不等价的合格码 + 类数恰为 N ⇒ 完全代表系”这一步是否严密；重生成目录所用程序的正确性是否被证明依赖（应当不依赖）。
3. **规范标号与解的定义**：引理 label、bridge 是否正确；`work/O6_SPEC.md` §2–§3 与 `PROOF.tex` 定义 1–2 是否逐条一致；是否存在“引理 transport 的结论成立但不构成定义 2 意义下的解”的情形。
4. **计算命题 1、2（目录）**：读 `check/catalog_check.py` 与 `check2/audit.cpp`（及其 Python 驱动），判断它们各自判定的谓词是否就是计算命题所述；不变量是否真的是等价不变量；同桶对的精确判定是否穷尽；两套实现是否真的独立；偶码下标表与“偶且无重复列”下标表的一致性证据是否成立。可做轻量复算（例如抽几个码自己重算秩、最小距离、零列、重复列）。
5. **计算命题 3（搜索）**：读 `extsearch.c` 与 `ext2.cpp` 的全部搜索与深度计算逻辑，判断：(a) 各自计算的 depth 是否精确（o6 的分层递推与位图异或移位；o7 的 min-plus 变换与偶域压缩）；(b) F、D12、D10 三个集合与阈值是否与定义一致（o6 中 ethr={D−3,D−5,D−7} 的快照含义）；(c) 递归枚举是否对无序集合穷尽、是否只做了升序这一种无损约化、预过滤位图是否只是加速而不改变判定；(d) 计数器是否可能溢出（64 位）或解表截断是否影响“解集为空”的判定；(e) 两套实现是否真的算法独立，逐码比较的字段是否足以支持“解集为空”在两套实现下各自成立。检查 `compare_runs.py` 判定的命题，以及 `work/20261123-assembly/w6_subset_compare.json` 的生成是否可信（可自行从原始逐码 JSON 重算 w=6 无重复列子集 3408 个母码的两实现一致性与 c5 总和；也可抽样若干母码重跑 `extsearch`，例如把输出写到 /dev/stdout）。
6. **小域验证是否覆盖了关键路径**：两套实现上线前的验证（61 例、33 例、planted 24 例 + 182 组）是否实际触发了 3、4、5 元子集条件；`work/20261122-planted/REPORT.md` 报告“严格由 5 元和条件造成的拒绝”一次也没有出现——请判断这是否留下了 5 元阈值（τ(5)=10）实现错误而不被发现的可能，以及这种可能是否会导致**漏解**（错误地拒绝合法 5 元集）。如果你认为有风险，请给出能消除它的最小补充检查。
7. **证据边界是否如实**：PROOF.tex 第 7 节关于 o7 尚有 3 个有重复列的 [36,7,16] 母码未跑完的说明，与主定理的论域是否一致、是否影响结论。
8. **FORMAL_SPEC 的不存在性验收**是否逐条满足：归约、对象编码、分类覆盖、实际完整遍历、拒绝判定、输入绑定；“保留的都合法”与“合法的没有漏掉”是否分别闭合；外部结果是否列为 import 并回到原文。

## 反例红队（Phase 1.5）

对引理 dual、mother(c)(d)、standard(ii)、transport、bridge、命题 cover 各做一次有记录的反例尝试（小参数类比、退化情形如重复列/零列/a_i∈K/两个头相同/头为奇、极端 T）。只有代数上验证过的才标“反例成立”，否则标“候选”。记录全部尝试，即使没有找到。

## 输出格式

只返回一个 JSON 对象（UTF-8，可含较长的中文字符串），字段：

```
{
 "verdict": "PASS" | "NEEDS_REVISION" | "FAIL",
 "research_complete": true | false,          // 仅当 FORMAL_SPEC 的不存在性验收全部满足且无未解的 FATAL/CRITICAL 问题时为 true
 "final_status": null 或 一句话（例如 "¬E(15) proved modulo imports I1, I2"）,
 "issues": [ { "id": 1, "status": "INVALID|UNJUSTIFIED|UNDERSTATED|OVERSTATED|UNCLEAR",
               "impact": "GLOBAL|LOCAL|COSMETIC", "severity": "FATAL|CRITICAL|MAJOR|MINOR",
               "location": "...", "statement": "...", "why_invalid": "...",
               "counterexample": "YES(...)|NO|CANDIDATE(...)", "affects": "...", "minimal_fix": "..." } ],
 "checks": { "A": "...", "B": "...", "C": "...", "D-F": "...", "G": "...", "H": "...",
             "q1": "...", "q2": "...", "q3": "...", "q4": "...", "q5": "...", "q6": "...", "q7": "...", "q8": "..." },
 "counterexample_attempts": [ { "target": "...", "attempt": "...", "result": "..." } ],
 "evidence_read": [ "实际读取的文件与行范围、实际执行的命令及其结果" ],
 "summary": "..."
}
```

如实填写 evidence_read：只列你真正读过、算过的东西。
