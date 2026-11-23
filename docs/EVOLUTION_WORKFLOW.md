# 用研究经验迭代现有 MathRSI

实际执行入口是 [`mathrsi-meta-evolve`](../base/skills/mathrsi-meta-evolve/SKILL.md)。本页提供使用说明与历史案例；取证、分类、实现、讨论、实际使用和采用的执行链只在该 SKILL 中维护，避免两套流程漂移。它是独立的外层维护能力，不是五个解题子流程的第六阶段，也不在每次 handoff 后自动启动。

输入可以是完整项目交接、一次具体失败与修正、用户反馈或真实调用记录。技能在**现有版本上增量修改**，判断经验属于通用 base、领域插件、单题状态还是暂不采用，并让实际调用者消费修改。基础模型没有因此被训练；新目录、版本名或版本图不证明研究效率提高。

## 怎样调用

Claude Code 与 Codex 共用同一份主技能及 references。项目发现别名分别支持 `/mathrsi-meta-evolve` 和 `$mathrsi-meta-evolve`；未刷新发现时直接读取实际路径即可：

```text
读取 /实际路径/MathRSI/base/skills/mathrsi-meta-evolve/SKILL.md 并执行。
基于当前版本迭代，不另建平行解题主流程。
研究来源：<项目/交接包>；已有阅读与原件依据：<路径>。
本次目标：<具体调用修复、吸收领域插件或完善现有base>。
范围：<可写文件、源项目只读边界、计算/模型/资源和发布授权>。
现用维护记录：<已有EVOLUTION.md或报告；新任务可由技能建立>。
先回收已有关键成功、失败及更正链，按技能实现并实际使用。
```

恢复一轮维护时给出原记录、当前版本和准确下一动作，不重新初始化状态。维护材料留在 `development/evolution/`，原研究规格、证明与 wiki 仍在任务工作区；随插件保存的历史副本标为只读来源。历史 ACTIVE、Goal 和运行命令不构成恢复旧研究的授权。

用户只要求分析时交具体提案；已经授权迭代实现时推进到实际修改和使用，不在每一阶段重复索取同一许可。提交、推送、合并、付费调用和全局配置按本次已有授权判断，技能不另加一轮固定许可仪式，也不扩大原权限。

## 给执行者哪些材料

一条可用的经验要能接清旧目标、实际假设或调用、改变判断的原始结果、随后真正修改的动作，以及现在仍成立的范围。wiki 和 query pack 帮助导航，判断所依赖的证明、代码、结果和后续纠正仍回原件。

完整项目吸收保留内容地图和实际阅读范围；某项改动已有充分证据时就进入实现，不等无关全库阅读结束。仅列目录、解析生成表或接收代理摘要不能标为全文读过。关键缺件和冲突如实保留，不以补写摘要冒充历史原件。具体取证和分层示例见 [evidence-and-transfer](../base/skills/mathrsi-meta-evolve/references/evidence-and-transfer.md)。

作者还需读受影响的现行技能、caller 和消费方。现行版本已有正确动作时复用或补具体连接，不复制同义主干；领域公式、失败输入及专用检查器留给插件，单题参数和预算不变成通用默认。

## 怎样判断实际使用支持了什么

按 [技能验收说明](SKILL_ACCEPTANCE.md) 核查本次改变的真实接口、命令和行为。默认由协调者或具体作者实际使用候选内容，子代理协助实作与核对；不强制换一个无历史 agent 重跑完整流程。独立数学核验仍按原题合同执行，必要的有界独立消费可按真实疑问安排。

路径改动检查当前克隆和相对别名；命令改动执行相应真实有界输入并读退出码与输出；研究行为改动观察调用者作了什么决定及后继动作。只新增历史例子时核原件与范围，不为例子重跑旧大型搜索或全套 Lean。有效且未改变的证明、检查结果和审阅直接复用；不能删必要覆盖或验距后称提速。

记录实际输入、修改文件、原始回应、命令、产物与尚未执行部分。静态阅读、独立算术、固定证书重放、模型审阅、Lean 构建和全域第二实现各自说明范围，不合并成万能 PASS。成本保留 CPU/墙钟、准备/求解/检查、共享前提/新增代价的区别；无完整计时就不造总成本或通用加速比。

## 已有案例怎样复用

**`composed` 不自动替换 research-review 的 Step 4。** [原审阅处置](../development/review-loop-integration/REVIEW_DISPOSITION.md)记录了内外层同时推进修法的风险；实际修法是由调用任务明确数学适配的返回点，保留证据对话，将修法和下一轮交回 route owner。可对照 [research-review Codex 原件](../base/skills/skills-codex/research-review/SKILL.md)与 [route-loop 实际调用](../base/skills/mathrsi-route-loop/SKILL.md)。已有静态复核不冒作完整 A–E 修法循环实跑。

**局部 verify 返回原 prove。** [真实行为试用](../development/workflow-redesign/behavioral-trial/REPORT.md)保存原问题、完整正文、精确计算、同家族意见和调用记录。局部核验后父 prove 继续原目标连接，没有提前全题 handoff；它支持这条具体转移，未运行正规 proof-checker、Lean 或完整联网研究链。未改此路径时可复用，不将历史运行追认为新 meta 技能的试用。

Property B 和 ECC 的 [历史转折](../development/workflow-redesign/REAL_PROJECT_TRANSITIONS.md)及 [ECC 仓内交接](../development/context/ecc-source/README.md)可作有界消费输入，不授权访问其原工作区或恢复旧研究。DD是历史v1→v2维护的研究来源；已有调用修改与插件接入见[v2具体变化](V2_CHANGES.md)，当次实际使用和采用由[v2维护记录](../development/evolution/dd-v2-20261102/EVOLUTION.md)追踪，不改写成MathRSI v1/v2的解题实验。当前v3的证据消费、ECC升级与三个新增领域见[v3变化](V3_CHANGES.md)和[v3维护记录](../development/evolution/v3-20261104/EVOLUTION.md)，其中的历史数学成果也不追认为v3重做。

## ARIS 原版与数学适配

仓内同时保留原版 meta-optimize／meta-apply 双宿主入口。它们与 `mathrsi-meta-evolve` 是不同合同：直接运行原版就遵循其真实 events、调用门槛、审阅和 apply 约定；数学适配接受研究原件，并依已有维护授权组织实现和实际使用。准确差异见 [aris-adaptation](../base/skills/mathrsi-meta-evolve/references/aris-adaptation.md)，双端路径与发现方式见 [ARIS_REUSE](ARIS_REUSE.md)。原版源副本保留其协议。

## 版本采用与状态

每轮维护记录说明实际改动、采用/暂缓决定、使用结果及未测范围。没有实际提交就记录工作树状态；没有新版重做研究就不声称新版解题率或 RSI 增益。新任务可选择已采用版本；在途研究由其协调者确认切换点，保留原规格、证明状态与已用预算，仅重核受影响结果。暂停研究不会随版本更新恢复。

新任务从[最新正式版](https://github.com/lisresearchgroup/math-rsi/releases/latest)开始，并记录实际采用的版本。v3在原有五个解题workflow与独立meta-evolve上增量修改：工作集/全域/已接受最佳的消费，带标记对象的同步运输，巨型域的有限全称机制与失败合法资产复用，以及混合Lean显式参数审计。ECC原位升级，新增超立方体极值、超立方体匹配延拓和Happy Ending领域能力；具体动作、命令、材料与保证范围见[V3_CHANGES](V3_CHANGES.md)，讨论、修订和采用以[v3维护记录](../development/evolution/v3-20261104/EVOLUTION.md)为准。

历史v2在v1已有五workflow上加入DD，并实现仅形式目标直接Lean、新基线消费到真实队列、对象改变后的正负证据重判，以及共同覆盖与局部充分门的区分；其具体文件和当次使用继续见[V2_CHANGES](V2_CHANGES.md)、[v2维护记录](../development/evolution/dd-v2-20261102/EVOLUTION.md)和[原验收记录](../development/VALIDATION.md)。v0指提炼MathRSI前的原始研究阶段，v1建立初版工作流，二者的历史与v2/v3的实际修改分开保存，不将归档数学结果记为新版重做。

v4已由同一meta技能组织增量实施，见[V4_CHANGES](V4_CHANGES.md)与[v4维护记录](../development/evolution/v4-20261108/EVOLUTION.md)。它将临界层取等、合法交换和相容见证接入原base，并深化Happy Ending/DD；实际检查与采用状态以该记录为准。固定v4标签保存本次发布，旧标签保持原提交。
