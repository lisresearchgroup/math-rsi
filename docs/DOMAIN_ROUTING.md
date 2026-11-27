# 在真实研究义务中调用领域能力

这份资源由主入口和五个子工作流实际消费。先按原题对象选择一行，再读该技能的完整内容，执行当前阶段对应的动作；不是把全部插件依次运行一遍。没有合适插件时继续通用研究，有新的来源后再做独立维护。领域归档只读，输出写当前任务工作区。

| 原对象与问题 | 领域入口 | 专门核验或方法入口 |
|---|---|---|
| 均匀超图二染色、Property B、m(k) | [mathrsi-propertyb](../plugins/propertyb/skills/mathrsi-propertyb/SKILL.md) | literature、bound-lab、certificate三项按原契约调用 |
| 最大度与直径约束下的图构造/排除 | [mathrsi-degree-diameter](../plugins/degree-diameter/skills/mathrsi-degree-diameter/SKILL.md) | construction、transfer-diagnosis、obstruction-certificate |
| 二元线性码的构造、全域不存在性、码表参数 | [mathrsi-ecc](../plugins/ecc/skills/mathrsi-ecc/SKILL.md) | [ecc-certificate](../plugins/ecc/skills/ecc-certificate/SKILL.md) |
| AJT（Alon–Jaeger–Tarsi）、可逆有限域矩阵的处处非零向量 | [mathrsi-ecc 的图码方法](../plugins/ecc/skills/mathrsi-ecc/SKILL.md#ajt) | 以同一矩阵的输入、输出为两块，按需要标记对偶关系中的坐标；用[原坐标 Lean 定理](../case-studies/ajt/formal/Audit.lean)核对结论和维数范围 |
| Q_n禁子图密度、共同局部补全、旗代数证书 | [mathrsi-hypercube-extremal](../plugins/hypercube-extremal/skills/mathrsi-hypercube-extremal/SKILL.md) | 同技能的优化、整数证书和高维平均分支 |
| Q_n匹配的Hamilton延拓、带根路径、森林连通 | [mathrsi-hypercube-hamilton](../plugins/hypercube-hamilton/skills/mathrsi-hypercube-hamilton/SKILL.md) | 同技能的保标记归约、森林秩与局部正证书分支 |
| 杯帽、凸多边形、rank-3 signotope的路径容量 | [mathrsi-happy-ending](../plugins/happy-ending/skills/mathrsi-happy-ending/SKILL.md) | [happy-ending-certificate](../plugins/happy-ending/skills/happy-ending-certificate/SKILL.md) |

这里两个hypercube插件分别研究子图密度与匹配延拓；“都是超立方体”不构成互换证明的理由。多个插件共同参与时，由当前caller先固定对象之间的映射和要保持的性质，再组合返回结果。

## Happy Ending / N(m,r,s) 的11-20同输入接口

对m=8–10或固定宽度容量族，当前caller先读[同输入扇区缺额方法](../plugins/happy-ending/skills/mathrsi-happy-ending/references/nmrs-higher-bounds.md)，再取[原件交接](../plugins/happy-ending/archive/nmrs-20261120/HANDOFF.md)、[核验范围](../plugins/happy-ending/archive/nmrs-20261120/VERIFICATION.md)与[重放入口](../plugins/happy-ending/archive/nmrs-20261120/REPLAY.md)。这仍属于既有Happy Ending插件。

route/prove交同一个实际Q_m输入及同参数普通进口u,t；领域返回最后业主的全部倒二点集合、合法Y/I子域、δ的四项非负分解、普通行ρ和切片ε，以及(m−2)n+ρ+ε+(m−3)δ的总预算。删点后重算源与锁，不假定δ单调。临界层饱和约束是同一输入的必要条件；标量可行表不充当signotope构造。当前Q8≤292、Q9≤1098、Q10≤3978是未独审/未接受的工作推论，独立整数证书的旧Q9≤1146路线仍单独保留。verify核全域桥、实际有限证据与解析稿各自范围；handoff按REPLAY区分新轻量复算和历史大证明checker回执。正缺额δ8≥6、δ9≥11仍是开放义务，不能按条件推论记为已证。
## v5 与 v6 的超立方体双插件深化

Q7 Hamilton 延拓与无四环极值子图仍由现有两套超立方体插件承担，不增加第七个领域：
- **Hypercube Hamilton：** 固定 v5 和 v6 的七维阈值分别为至少 57、56 条边。11 月 19 日的项目工作证明覆盖七维超立方体中的任意匹配。先对至少 46 条边给出延拓，再证明每个包含极大匹配至少有 46 条边。最终有限排空可随仓复算；较早的部分稠密层证书需另行恢复。见 [Q7 案例](../case-studies/ruskey-savage-q7/README.md) 和 [证明与进口](../plugins/hypercube-hamilton/knowledge/q7-closure-proof.md)。
- **Hypercube Extremal（`v6`）：** 在历史 `v3` 六块 Q4 证书之外，新增渐近 COP + m=1024 广义度数势（`T3 ≤ 0.5912405943`、`T4 ≤ 0.5912405942` 配五行超几何塔）、有限 Q8 同图三测度拉回（`682 ≤ ex(Q8, C4) ≤ 683`，`≤682` 开放）、Q7（304 边构造已验证；304 上界按原包报告，本次未复验）以及可复用协同搜索引擎 `tools/cube_coevolve/`。见 [Erdős 86 案例](../case-studies/erdos-86/README.md)。

route/prove 交真实孔、伙伴、可选供体配对和已知合法切分，领域返回受控后继、返回桥及实际可用计划；先用新定理刷新跨表示覆盖，再研究余域。来源纤维计数必须基于真实兼容池。verify 明确固定全称计划或依原输入选择的有限计划集；多省略点森林证书按实际省略集合与端点合同核验，不能只改秩常数。数学条件与真实程序仍由插件负责。

## 准备与增量文献：先明确要借用哪种结果

prepare把原题、允许终点、当前参数、已有wiki与已查来源交给survey，并标出上表中的适用入口。survey实际执行对应领域的定义与来源分支，再使用research-lit补查异名、引用链、反例和勘误。领域读取和通用广搜共享一个调查与wiki writer；领域作者可独占提取文件，由survey消费进原报告。

- **ECC：** 交n、k、d、域、秩/支撑要求以及构造还是不存在性目标。领域返回精确参数与允许操作、已发表不可存在结果/分类的实际条件、矩阵基线及其本地验距状态。survey核原文版本和分类上限是否适用于当前对象，交prepare固定进口。不能把43/10的172类目录直接迁到45/11全域，也不能把42/16的已发表结果应用当成新纪录。
- **Hypercube extremal：** 交禁图、密度分母及有限n/渐近量词。领域返回共同Q4表示、COP/广义度数势（T3/T4）、有限维同图多测度拉回（Q8）或协同搜索接口（cube_coevolve），以及Baber等历史来源定位和有限n误差的准确含义。survey按当前比较主张查新，不能用渐近0.5912405943作为每个有限Q_n的裸上界，也不将0.5907近似拟合或已撤回0.5899当作定理。
- **Hypercube Hamilton：** 区分维数、原匹配允许的边、使用的方向及圈或指定端点路径。普通七维匹配的保边 Hamilton 圈调用 R7。指定端点的七维路径 P7，以及一般维数中使用至多七个方向的匹配仍开放。Fink–Hotmar Theorem 5 的提升以指定端点路径命题为前提，现有 P6 支持至多六方向。
- **Happy Ending：** 交点集/抽象signotope/CNF对象、顶点次序、颜色约定、路径参数和weak/split定义。领域返回版本化容量链与所需进口。survey核a=16、b=25等确切来源，不用抽象见证声称几何实现；新75/76原稿已完整随插件归档，返回其同会话未独立接受状态与75/76/77的不同含义；不将旧25下界见证当新上界证明。

查得新基线或进口后，caller要明确改变什么：仍需解的目标、可以取消的重复搜索、可调用的新定理及尚缺假设。已有正确调查只补新疑问，不因插件升级重做整个领域检索。原任务的固定目标不被竞争纪录比较悄悄替换。

DD 的准备沿 [插件契约](PLUGIN_CONTRACT.md)；新的饱和源案例读取 [增点与重放](../plugins/degree-diameter/references/saturated-insertion-and-replay.md)，区分公开2557种子、本地2566前驱和有日期的公共2566比较。实际执行归属v2+DD，v4接收经验。

## 路线迭代：要求能改变决策的领域返回

route-loop先交本轮阻塞、实际失败输入、原量词、已尝试域和资源边界，要求领域执行一项推导或探针。下一轮由route-loop消费结果后启动，领域作者不另开同级审阅循环。

**ECC：** 调mathrsi-ecc比较构造、陪集扩维与必要联合条件。固定母码已全域排除就保留其范围；只有不等价新母码或改变的数学条件值得重试。报告代表数之外的完整扩张成本与原坐标约定。便宜必要pair门已足够排除当前原域时，不继续更贵的多行扩张；门非空则把实际存活输入交回prove。

**极值超立方体：** 调mathrsi-hypercube-extremal的共同补全/同步作用及工作集探针。给具体模型、已接受证书和改进方向，收回restricted/full、探索最佳、已接受最佳及违反K的可重建编码。全域失败回原候选补行；模型有改进但尚未整数化就交精确化义务，不更新已接受下界/上界。若没有违反输入身份，先补该对象，不重复盲优化。

**Hamilton：** 调 mathrsi-hypercube-hamilton 区分原匹配、可选供体配对与实际压缩后继，返回受控接口与返回桥，保持自由根、目标和原边。新定理先在已知合法切分/补全中使用；来源纤维先在真实兼容池精确计数，再选择有限生成域。固定切失败不等于原匹配未覆盖；返回真正余域及其带标记输入。

**Happy Ending：** 调mathrsi-happy-ending检查固定漏态映射的SAT反例、局部修复净收益和同一中间匹配供给。返回反驳的准确引理/域、保留的条件工具及新动作。例如固定缺态失败，转e/m基数义务；左右人数够而不共匹配，先证明共同交会；局部节省被增核吃掉则停止同型扩表。实际反例不在原对象域时只诊断表示，不宣布原题为假。

**v4 临界层与饱和源：** Happy Ending 在已证整数界差一单位时按 [取等/替锁参考](../plugins/happy-ending/skills/mathrsi-happy-ending/references/equality-exchange.md) 返回同一链的零松弛结构、合法交换及仍缺的端点定位；用11点逐点饱和反例或10点双插点反例否定准确的过强引理，不能否定带额外条件的全题。DD 在degree无余量且允许删旧边时，按增点参考试matching cut、新星和必要的old-only switch，返回同一最终图上的old-old/new-old坏对及未覆盖域，再改变候选。

## 证明推进：把领域输出接回实际输入

prove给领域作者独占输出目录、精确缺失引理、允许进口与下游要用的结论。领域结果若是一般证明，读完整前提与任意输入连接；若是实例，读它的表示与验证结果。新文献问题回survey增量分支，然后返回本条义务。

- **ECC：** mathrsi-ecc交付缩短/穿孔/偶扩展的同一坐标映射、必要母码域、完整分类条件和pair接口。构造候选立即交ecc-certificate完整验秩验距；排除则分别接分类覆盖、完整集合、拒绝和原目标。它们不是同一个PASS。
- **极值：** mathrsi-hypercube-extremal交付同一K的全部局部观察、共享根同步运输、整数Gram候选及高维平均证明。最终精确矩阵变了，重算它的所有声明域分数；合法域及未变覆盖证明可继续复用。原n维图到Q4平均的连接必须与该证书对应。
- **Hamilton：** mathrsi-hypercube-hamilton 交真实伙伴、受控辅助配对、返回桥与原边恢复。几何固定计划覆盖该几何的每个实现；有限条件计划则证明同一实际匹配至少有一门适用。两者都交源覆盖、标记运输和最终展开。有限秩路线仍需完整匹配列的秩桥与非零列；通过后只关闭声明范围，全域圈结论使用密层定理和保持原匹配的极大补全，指定端点另查 P7。
- **Happy Ending：** mathrsi-happy-ending交同一母体的诱导核、实际路径、三图和固定中间匹配，证明损失与补偿使用同一批点；chart须保packet、weak和目标短帽条件。必要时交happy-ending-certificate核具体颜色/路径或编码lifting，收回准确箭头后继续。

临界层的 Happy Ending 作者还须交回实际替锁域的不交计数、进口禁形保持，以及同一条容量强迫路径如何经精确端点覆盖接外部供给；下一整数层重新计算松弛，不沿用旧等号。DD 作者交实际cut/switch配方与生成图；复用插件随附重放器向当前任务目录输出，度数守恒证明和距离义务分开交verify。具体路径见上方两份v4领域参考，不调用网站开发目录的文件。

## 验证：选择领域义务，不自动启动所有程序

verify持有原规格与整个证明。只将当前需核的领域部分交相应入口，读取命令、真实输出与有限谓词，再决定能关闭哪个义务。领域验收返回后，由原verify继续proof-checker或按需Lean，不在插件里递归整个最终审计。

| 入口与输入 | 返回什么 | 原caller实际消费 |
|---|---|---|
| ecc-certificate，实际矩阵/目录/扫描或pair证书、最终Lean声明 | 形状秩验距、目录/保存集范围、pair拒绝、显式形式前提分别报告 | 存在性只需验实际见证；全域不存在性继续核覆盖及进口；未供给的Lean参数保持原题义务 |
| mathrsi-hypercube-extremal，冻结证书（原包装器）或同型新候选（check_q4_candidate.py）、平均引理 | 精确PSD、完整域新C/M_F/M_v各自证据；比较同一目标后仅以更好已认证候选替换best | 同一G的有限界与渐近结论分别装配；prepare-only不能充当全域遍历 |
| mathrsi-hypercube-hamilton，带标记输入、森林/矩阵/局部证书 | 核固定或条件计划量词、实际省略集合 U⊆H、森林度数/分量、完整列端点、位矩阵与rank及覆盖桥 | 本轮完整 T63 target04 为4096²位/rank4096，旧 A10 为1024²位/rank1024；两迁入消费者PASS。只覆盖这些实际输入，不代替其余T63核、完整Q7或全部进口证明链 |
| happy-ending-certificate，颜色TSV或某个SAT/结构义务 | 抽象见证、固定策略反例，或CNF绑定/lifting/UNSAT各自实际范围；新取等/交换/端点接口逐箭头核对 | lower25不推出upper25，11/10点反例只否定指定辅助引理；75/76工作稿不因插件维护升级为接受 |
| dd-obstruction-certificate，cut/switch配方、最终图及历史收据 | 有界有限编辑重放、实际字面度数与所执行的全点对/形式化范围分别返回 | 重建不等于验距；删边不沿用old-old保距；历史BFS/Lean与本次命令分列，缺完整Lean工程不能声称本克隆可重建 |

精确命令及依赖见各插件evidence/IMPLEMENTATION.md和复现reference。需要数据未随仓时，将缺件与来源交回当前义务，继续可独立处理的部分；不自动启动多TB下载、大SAT/扫描或旧研究Goal。

## 装配、交付与下一次恢复

assemble消费领域准确命题、假设与验证范围，在使用处接完整前提，而不是引用一句“插件通过”。例如ECC旧题结论/邻参数推论/42文献应用分开，Erdős有限n保误差项，Q6保持维数及方向量词，Happy Ending保持抽象/几何及候选状态。

handoff从同一领域入口取已接受证书、真实复现命令、原件导航和明确缺件，交完整证明与可读页面。发现程序默认改写数据的，按插件命令在新任务副本运行；不把搜索器当默认只读checker。archive与原wiki是知识来源，新任务的结果、失败、未闭义务和断点写自身wiki。新通用经验通过单独授权的meta-evolve维护现有版本，解题中不改base。

每次领域返回用已有报告说明“哪条原义务改变了、证据在哪、下一步是什么”即可。文件数、模型赞同或局部核验次数不替代这个实际消费动作。
