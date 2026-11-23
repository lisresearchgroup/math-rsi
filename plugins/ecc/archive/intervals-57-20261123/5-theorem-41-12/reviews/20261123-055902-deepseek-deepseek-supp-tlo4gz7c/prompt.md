你是独立的数学审阅者，只读。请审阅一份计算机辅助的不存在性证明，判断它是否成立。case 目录：`/home/user/math/aris4math_v2/cases/41-12`。本提示自足：没有 preflight.json / ROUND_MANIFEST.json / handoff，不必寻找。

结论：不存在二元线性 [41,12,≥15] 码（sound modulo 两条文献进口）。

请读：
- `FORMAL_SPEC.md`（原题与“不存在性验收”）；
- `PROOF.tex`（完整证明正文）；
- `work/O6_SPEC.md`（有限计算的定义）；
- `VERIFICATION.md`（证据清单）；
- 需要时读它们引用的原件：进口阅读记录 `work/20261122-imports/I1_reading.md`；I2 文本 `/home/user/math/aris4math_v2/cases/45-11/work/20261020-c5/canonaug/txt/boukou-2025-optimal-linear-codes-and-their-hulls-math13-2491.txt`；搜索实现 `work/20261122-o6/extsearch.c`、`work/20261122-o7/ext2.cpp`；比较结果 `work/20261122-compare/*.json`、`work/20261123-assembly/*.json`；见证 `work/20261123-witness5/REPORT.md`。

请检查并明确回答：
1. 归约链（引理 shorten、even、no39、dual、mother、standard、transport、label、bridge）每一步是否正确：算式（Griesmer 和、球填充 1+42+861+11480 与 2^12）、缩短的参数、尾重与阈值 14/12/10、量词方向。有没有对任意 [41,12,≥15] 码不成立的步骤，或偷偷附加的结构假设？
2. 引理 mother(d)（w=6 时母码无重复列）是否正确；w=6 分支把母码域限制为无重复列是否与命题 cover、计算命题 3 的论域一致。
3. 命题 cover：“N 个两两不等价的合格码 + 文献给出的类数恰为 N ⇒ 完全代表系”是否严密；文献 I2 的对象域（无零坐标、允许重复列、坐标置换等价、最优即 d=16）是否与用法吻合。
4. 定义 2 的“解”与引理 transport 的结论是否等价到足以使“全部母码解集为空 ⇒ 不存在”成立。
5. 证据：两套实现逐码一致、relaxed-5 检查与显式低重码字见证，是否足以支持计算命题 3；你认为还缺什么。
6. 你发现的任何其它漏洞。

可以写小脚本核对算式或抽查数据（只读）。输出：只返回一个 JSON 对象
{"verdict": "PASS" | "NEEDS_REVISION" | "FAIL", "issues": [{"location": "...", "problem": "...", "why": "...", "fix": "..."}], "answers": {"1": "...", "2": "...", "3": "...", "4": "...", "5": "...", "6": "..."}, "evidence_read": ["实际读取的文件/执行的命令"], "summary": "..."}
如实填写 evidence_read。
