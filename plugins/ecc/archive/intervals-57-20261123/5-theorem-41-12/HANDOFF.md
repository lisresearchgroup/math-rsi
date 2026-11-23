# HANDOFF — case 41-12：不存在二元线性 [41,12,≥15] 码

2026-11-23。规格 `FORMAL_SPEC.md`（v3）。

## 结论

**不存在二元线性 [41,12,≥15] 码**（¬E(15)）。推论：d₂(41,12)=14，d₂(42,12)=15。

性质：计算机辅助证明，**sound modulo 两条文献进口**：

- I1：不存在二元线性 [39,10,16] 码（JCMCC 59 (2006) 33–87，Lemma 4）。
- I2：无零坐标的最优二元 [36,7]、[37,8]、[38,9] 码分别恰有 8170、17276、47 个等价类（Mathematics 13:2491 (2025)，表 A5–A7）。

**验收状态：未完成。** `FORMAL_SPEC.md` 要求“proof-checker 正式审计，并由 MiniMax 与 Gemini 审阅”。正式审计（Sol/xhigh，两轮）与 MiniMax 审阅均已通过；**Gemini 审阅没有取得**（2026-11-23 三次调用全部 HTTP 429）。`CASE.json` 未改。

## 各部分是什么性质的证据

| 内容 | 性质 | 位置 |
|---|---|---|
| 归约：偶码化 → 对偶最小重量 w∈{4,5,6} → 缩短得母码 → 标准扩张的子集和深度条件 → 规范伴随式 | 纸面证明 | `PROOF.tex` §3–§4 |
| 目录：47 / 17276 / 8170 个实际码逐码合格、两两不等价 | 计算，两套独立实现（Sonnet、Sol） | `work/20261122-catalog/check/`、`check2/` |
| 目录完备 | 文献进口 I2 的类数（本地没有独立重做分类） | `PROOF.tex` 命题 cover |
| 搜索：20709 个母码解集全空 | 计算，两套算法不同的实现（o6、o7）逐码一致 | `work/20261122-o6/`、`work/20261122-o7/`、`work/20261122-compare/`、`work/20261123-assembly/` |
| w=6 的 5 元和条件 | 3406 个母码无候选（o6 变体，单实现）；另 2 个母码的 1748736 个候选各有显式重量 12 码字（可重放） | `work/20261123-assembly/r5_K6_summary.json`、`work/20261123-witness5/` |
| 下界 [41,12,14]、[42,12,15] | 显式矩阵，`verify_code` + 独立实现全枚举 | `work/20261122-seed-e14/`、`work/20261123-lb42/` |
| 正式审计 | Sol/xhigh 两轮：NEEDS_REVISION → PASS | `PROOF_AUDIT.md`、`PROOF_AUDIT.json`、`reviews/20261123-*sol-formal-audit-*` |
| 其它模型审阅 | MiniMax PASS；DeepSeek 判数学成立；Grok 审过归约草稿 PASS；Gemini 未取得 | `VERIFICATION.md` §5、§7 |
| 形式化 | 没有（无 Lean） | – |
| 独立目录复现、他人复现 | 没有做 | – |

## 值得知道的事实

- 三个分支的结果：w=4 的 47 个母码连相容三元组都没有（相容对共 15 个）；w=5 的 17254 个母码有 52176 个合格三元组、没有四元组；w=6 的 3408 个母码有 33931020 个合格四元组、没有五元组。
- 最接近的情形：[36,7,16] 母码 idx 1980 与 2004（重量谱均为 16:63, 20:63, 36:1）各有一批 5 元集满足 1–4 元的全部条件，只在 5 个头之和上失败（陪集深度 6，需要 ≥10）。对应的 [42,12] 扩张码恰有一个重量 12 的码字，其余码字重量都 ≥16。
- 任务说明里的一条前提不成立：Zenodo 数据集只有 [38,9,16] 的 47 个矩阵，没有 [36,7,16] 与 [37,8,16]。这两份目录是用论文所用的公开程序 GENERATION v1.1 重新生成的，个数与 hull 直方图同论文表一致。证明不依赖生成程序正确（只用实际矩阵的核对结果加 I2 的类数）。
- w=6 分支的母码域是“无重复列的偶母码”（3408 个），依据 `PROOF.tex` 引理 mother(d)。对其余 4688 个有重复列的偶母码，两套实现也都全部算完且逐码一致（无解）；这部分不进入主定理。`PROOF.tex` 第 7 节写的“o7 完成 8095 个”是撰写时的状态，最后一个（idx 2067）已于 11-23 早晨完成。

## 复现入口（均在 case 目录下执行；未在独立目录重放过）

```
# 目录核对（各约 2 分钟内）
python3 work/20261122-catalog/check/catalog_check.py work/20261122-catalog/qext/run_36_7_16/36_7_16.2 36 7 16 --out work/20261122-catalog/check --jobs 3 --assert-fresh
python3 work/20261122-catalog/check2/run_audit.py

# 单个母码的搜索（生成矩阵文件：κ 行 N 列 0/1）
work/20261122-o6/extsearch <gen> <w> 16 <out.json>        # w=6 典型 20–60 秒，约 0.35 GiB
work/20261122-o7/ext2 <gen> <w> 16 <out.json>             # w=6 典型 1–3 分钟，约 0.8 GiB

# 整份目录（按码断点续跑）
python3 work/20261122-o6/run_catalog.py <catalog.2> <w> 16 <outdir> --jobs J
python3 work/20261122-o7/run_catalog2.py <catalog.2> <w> 16 <outdir> --jobs J     # 本地副本限 J≤2；Cluster 副本已放宽

# 两实现逐码比较
python3 work/20261122-compare/compare_runs.py <catalog.2> <w> <dirA> <dirB> <out.json>
python3 work/20261123-assembly/make_w6_subset_compare.py

# 见证重放（1980 约 1 秒，2004 约 1 分钟）
python3 work/20261123-witness5/replay_witness.py work/20261123-assembly/r5/2004.gen work/20261123-witness5/witness_2004.txt.gz
```

全域原始结果（逐码 JSON）在共享盘 `/shared/ecc-41-12/out/`，没有复制进 case 目录。实耗：o6 约 90 CPU 小时，o7 约 295 CPU 小时，relaxed-5 约 25 CPU 小时（Cluster，8 核任务）。

## 还差什么

1. **Gemini 审阅**（规格明文要求）。通道恢复后执行：
   `bash ../_devbox/review.sh gemini $PWD $PWD/reviews/prompts/20261123-supplementary-review.md gemini-supp`
   然后把结果记入 `VERIFICATION.md` §7 与 `PROOF_AUDIT.md`。或者由用户决定是否接受 DeepSeek 的审阅作为替代。
2. `CASE.json` 的最终状态由用户或外层脚本发布。
3. 可选：进口 I2 若要去掉，需要独立重做三类母码的分类；进口 I1 的原始计算也没有重放。
