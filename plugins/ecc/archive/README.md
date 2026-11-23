# ECC 原件与分发范围

`source/` 是 `ecc-five-case-release-20261103` 的只读副本，保留原相对目录、原 README、REPRODUCE、论文、三份证明、两套 Lean 工程及依赖锁、全部下界和172母码数据、两扫描器、独立 checker、全部172例扫描输入/结果/接受集，以及发布复验报告。历史状态、命令、作者路径和排版脚注保持原文，不构成新研究授权。原包没有正式冻结规格独立文件、第三方全文、原研究wiki、完整失败轨迹或原模型对话；本插件没有补造它们。

原包实际清点为 **1326文件、1,723,685,941字节**；精确值以 [INVENTORY.json](INVENTORY.json) 的 `bytes_original` 为准。复制前按文件统计，未将目录大小估计当成证据。当前 `source/` 保留1155文件、44,064,662字节；其中完整保留母码index169 `catalog_after163_169` 的546个F代表及148,785个pair拒绝消息流。其余171个大pair流共1,679,621,279字节未随此源码插件分发。逐项原包相对路径、字节数和省略原因在inventory；没有虚构在线下载地址。持有原完整发布包时可按同名路径补回，不能把缺流状态当成全172例可重放。

原 `source/README.md` 描述**完整发布包**，因此其中“包含全部pair流”的陈述不描述本插件的精简副本。`source/verify.py quick` 的路径加载也会检查所有流，精简副本不能直接用该总入口冒充完整包。插件提供 [ecc-certificate](../skills/ecc-certificate/SKILL.md) 的明确轻量入口：矩阵/多项式检查可直接用冻结原程序；保存集合检查仅调整路径加载，跳过本就不读的pair路径；单母码checker只把172固定批次改为所选批次，保留所有数学检查与原母码编号。

`legacy-context/` 保存本仓v1已接收的两份原交接，来自 `development/context/ecc-source/`，用于读取真实失败、联合表示与45/11开放路线。它们是历史原件，内部指向v2工作区的外链不会被假称已打包。`intake/` 是2026-11-04的派生阅读笔记，精确记录已读范围与缺件；它不是原研究失败日志。源包没有的profile、模型原文及完整旧wiki明确仍缺。

两Lean工程不包含 `.lake`、`.olean` 或工具链；固定Lean4.34.1及mathlib锁不变。本轮没有新Lean构建，历史fresh构建和公理/类型日志原样保留。扫描器源码可用，当前轻量例子不运行2³²域。所有新任务与复算输出写当前任务scratch，不能写冻结副本；具体本轮执行见 [IMPLEMENTATION](../evidence/IMPLEMENTATION.md)。

原项目许可与第三方说明在 [THIRD_PARTY_NOTICES](source/THIRD_PARTY_NOTICES.md)，论文样式说明在 [STYLE_SOURCE](source/paper/STYLE_SOURCE.md)。保留文献作者与出处，不代填作者、机构、投稿或开放许可证。

`intervals-57-20261123/` 是 2026-11-23 整理的**轨迹与配图**：二元线性码界表中 MathRSI 推进的 57 个区间的逐格证据（证明、推导、矩阵、源码与验收记录）和中英两版汇总图。它是证据归档，不是结果发布；其中 `[41,12,15]` 一组的验收尚未走完，扫描下界一组当时仍在进行，各组的前提与限定见 [intervals-57-20261123/README](intervals-57-20261123/README.md)。该目录不属于上面的 `source/` 发布包，也不计入 INVENTORY。
