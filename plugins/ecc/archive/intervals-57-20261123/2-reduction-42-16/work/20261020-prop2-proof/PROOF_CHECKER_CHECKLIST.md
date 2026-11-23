# proof-checker 审计清单（并入下一轮合并的 GPT-6 Astra 检查）

> 本 case 的规则（ACTIVE_GOAL / BATCH_RUNTIME）：proof-checker 的 **GPT 审阅调用合并到轮末唯一一次检查**，轮内不另开 GPT。
> 因此本文件把「需要被审的每一步、每条依赖、每处已知缺口」写成可逐条核对的清单，供**下一次**轮末检查（fresh、只读、Astra/xhigh）执行。
> 本轮的外层检查（2026-10-20 17:53，NEEDS_REVISION）**不冒充** proof-checker 审计，也**不冒充** Grok/Gemini 跨家族审阅。

## A. 待审对象（只读）
- `work/20261020-prop2-proof/PROOF_PACKAGE.md`（主对象；SHA256 见 handoff）
- `work/20261020-prop2-proof/verify_reduction.py` + `logs/verify_reduction_direct.log`
- `work/20261020-prop2-redteam/redteam_checks.py` + `logs/redteam_checks.log` + `REDTEAM_REPORT.md` + `verdict.json`
- `ref/20261020-residual2020/chapter_springer.pdf`（Prop. 2 在印刷 p.179；SHA256 c2116c20…）
- `ref/20261020-imports/feulner-dissertation-cd-results-ub2.html`（Prop. 2 链的输入表）
- `candidates/qr-seed-verified.json`（下界种子）

## B. 逐条核对项
1. **S1 距离下降**：穿孔单射（核中码字重量 ≤ d−13 < d）⇒ 维数不变；最小距 ≥ d−|T| 且 ≤ wt(c^T) ⇒ **恰为 13**；
   补零列后长度/维数/距离是否如述。
2. **S2 奇偶扩展**：全偶；最小距**恰为 14**（重量 13 的码字扩展后为 14；任何码字重量 ≥13 且偶）。
   校验列 = 其余 42 列之和；秩 = 16。
3. **S3 双缩短**：重 14 码字在**原 42 坐标**上的 1 的个数 m ∈ {13,14}（校验位可能为 1 —— 旧稿曾在此出错）；
   零位集 Z 的列张成维数 ≥ k−m ≥ 2（k=16）⇒ 存在两列线性无关；
   核维数恰 14；重 14 码字存活 ⇒ 最小距**恰为 14**；删两位后长度 41、线性与重量不变。
4. **条件完整性**：引理的一般化陈述必须带 **k ≥ 16**（否则 [13,1,13] 反例）；脚本 docstring 与 NEXT_SESSION 的推广表述是否同步。
5. **全域覆盖**：结论是否覆盖**全部**秩 16、65535 个非零消息重量 ≥13 的 16×42 二元矩阵，且未使用
   「零列不存在 / 列互异 / 自同构 / 固定母码 / 固定残码」等未证假设。
6. **import 的适用性**：Prop. 2 是否覆盖**全部二元线性码**（Prop. 1 的 even 归约是否真的双向）、
   「14」的语义是否与本包使用的「最小距恰为 14」一致。
7. **import 的依赖链**：Feulner 无 [35,10,13]、作者声称的无 [36,11,13]/[37,12,13]、码表「无 [41,27,≥7]」
   （**该码表输入沿链回溯到 Ja/Jaffe 叶子**）、209 码 432 分钟计算（**只是已发表 import，不是本地独立证书**）。
8. **下界与结论的合成**：d_2(42,16) ≥ 12（本地独立复算）+ ¬E(13) ⇒ d_2(42,16) = 12。
9. **未完成义务的如实性**：proof-checker 审计（=本清单）、Grok/Gemini 跨家族审阅、优先权复查、
   作者 432 分钟计算未复跑、勘误检索的「未查到 ≠ 不存在」。
10. **表述纪律**：不得出现「不存在更新的公开版本」「2021–2026 没有任何文献复述」这类全称判断；
    一切检索结论须限定为「在已查来源中未发现」。

## C. 期望输出
- 每条 PASS / FAIL / NEEDS-REVISION，附原文位置与理由；FAIL 必须给出最小反例或错误行。
- 明确回答：**本 case 是否满足 FORMAL_SPEC「不存在性验收」的全部条件**（全域覆盖 / 严格证明 / import 记录 /
  显式证据 / 独立复算 / 审阅），以及**是否可把 status 改为 solved-***（只有全部成立才可）。
- 审阅记录写入 `reviews/<timestamp>-proof-checker/`，并在 `work/ROUND_HANDOFF.md` 中被下一轮引用。
