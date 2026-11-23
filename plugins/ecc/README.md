# ECC：二元线性码研究与证书核验

本插件为二元线性码构造与不存在性研究提供实际数学、失败经验、Lean归约及普通确定性检查器。与MathRSI base配合使用：base管理目标、路线和最终验收，插件处理具体领域义务；不恢复旧研究Goal。

两个技能各有独立职责：

- [mathrsi-ecc](skills/mathrsi-ecc/SKILL.md)：解释原始n/k/d及量词，推进结构归约、分类、陪集联合条件、构造和失败诊断；返回真实证明、探针、反例或准确缺口。
- [ecc-certificate](skills/ecc-certificate/SKILL.md)：接收实际矩阵/母码/F/证书和当前scope，执行参数、覆盖、保存集、pair或Lean接口核验；将结论和未闭连接回交原prove/verify，不另启总控。

数学工具从 [结构归约](skills/mathrsi-ecc/references/reductions.md) 开始；卡点查 [真实失败与重试条件](skills/mathrsi-ecc/references/failures.md)；按义务找原件用 [阅读地图](skills/mathrsi-ecc/references/source-map.md)；形式结果读 [Lean显式参数与实际数据边界](skills/ecc-certificate/references/lean-boundary.md)。完整固定母码示例见 [fixed-parent](skills/mathrsi-ecc/examples/fixed-parent.md)。

## 按节点推进与避免重复研究

每次新推进先匹配已有分枝；未匹配时说明父域、未覆盖余类或共用依赖，归属未知则先核对。实际流程接在 mathrsi-ecc，范围验收接在 ecc-certificate。读[节点研究协议](skills/mathrsi-ecc/references/node-research.md)、[可填写工作包](skills/mathrsi-ecc/examples/node-work-package.md)与[72/36分枝示例](skills/mathrsi-ecc/examples/node-research.md)。沿用任务的节点账本和 ARIS wiki，固定身份而非预设统一分枝数量；局部排除与全域解答分开，共用计算不重复派发。

## v8 的构造与上界

18 组参数有了距离更好的码，每组都能导出实际生成矩阵。其中 10 组把保证可纠正的错误数提高了一位。上界方面，32 项新推论来自已发表的不存在性定理，9 项使上下界相等。另两项依赖同一份新计算证明，等待原研究项目最终验收。以下五项保留其早期归属。[下载生成矩阵和查看逐格上下界](https://lisresearchgroup.github.io/math-rsi/ecc-intervals.html) · [复核记录](evidence/v8-20261123/REVIEW.md)

## 早期五项结果

|参数|本包支持的结果|来源关系|
|---|---|---|
|43/10|d₂(43,10)=16|主不存在性证明＋实际距离16矩阵|
|44/10|d₂(44,10)=17|穿孔回主定理＋实际距离17矩阵|
|44/11|d₂(44,11)=16|缩短回主定理＋实际距离16矩阵|
|45/11|16≤d₂(45,11)≤17|邻参数推论；距离17的构造或排除**仍开放**|
|42/16|d₂(42,16)=12|对2020年已发表E3的应用＋实际距离12矩阵，不主张新颖性/优先权|

43/10旧证明、172类双完整扫描及全部pair拒绝属于v0已有成果；后续工作继承MathRSI v1/v2方法，深化了Lean归约、实际矩阵与原声明连接、便携证书发布/复验和42/16文献路线。本轮v3将这些材料接成可调用插件，未重新发现旧结果，也没有等预算提速实验。两Lean工程仍显式接受E1/E2/目录互异/完整计算或E3参数，标准公理列表不替代这些输入；42位下界当前只由普通全枚举核验。

## 从仓库根运行轻量检查

准备当前任务的实际scratch目录，将命令中的 `TASK/scratch` 换成该路径。Python需≥3.10；pair入口还需C++17编译器。输出应在冻结archive之外，pair输出目录须尚不存在。

```sh
python3 -B plugins/ecc/archive/source/computation/check_data.py \
  --output TASK/scratch/finite-data.json
python3 -B plugins/ecc/tools/check_saved_sets.py \
  --manifest plugins/ecc/archive/source/evidence/manifest.json \
  --output TASK/scratch/saved-sets.json
python3 -B plugins/ecc/tools/replay_one.py --index 169 \
  --output-dir TASK/scratch/parent169-replay
```

三者分别核五下界/172母码实际有限数据、172例保存集运输与精确相同、一个完整母码的148785个pair拒绝。保存集读回和pair重放都不重新遍历2³²商域；具体输入、结果与范围见 [IMPLEMENTATION](evidence/IMPLEMENTATION.md)。新候选矩阵可用ecc-certificate中的 `tools/check_matrix.py`，显式传原规格n/k/d并获得实际最小权消息。

## 随仓原件与分发边界

[archive/README](archive/README.md) 说明原件层，精确清单见 [INVENTORY](archive/INVENTORY.json)。`archive/source/` 保留证明、论文源/PDF、两Lean工程（无缓存）、全部下界/母码数据、172例双扫描输入/结果/接受集、检查器及验证报告。论文当前稿在 [`archive/source/paper/`](archive/source/paper/README.md)，其证据与可复现包在同级 [`archive/source/paper-reproduction/`](archive/source/paper-reproduction/README-REPO.md)。随仓完整保留母码169的546个F代表和148785字节pair流；其余171大pair流未分发，逐项保留原包相对路径与字节数。精简插件不能声称全172流可自包含重放，原完整发布README的全流描述须连同外层范围阅读。

`archive/legacy-context/` 是本仓此前接收的两份历史交接，`archive/intake/` 是已读范围明确的派生笔记；缺失的原研究wiki、完整失败轨迹、模型对话与第三方全文未冒充已拥有。新任务输出和wiki写自己的工作区，归档保持只读。
