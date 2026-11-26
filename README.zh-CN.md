<div align="center">

# <picture><source media="(prefers-color-scheme: dark)" srcset="figures/mathrsi/branding/mark-c-dark.png"><img src="figures/mathrsi/branding/mark-c-light.png" width="76" height="38" align="middle" alt=""></picture> MathRSI<br><sub><sup><em>SII MathRSI Team</em></sup></sub>

**面向数学探索与证明的自进化智能体系统。**<br>让 Claude Code 与 Codex 执行可读的 Markdown 技能与领域核验器。

[![项目主页 / EN + 中文](figures/mathrsi/badges/visual-tour.zh-CN.svg)](https://lisresearchgroup.github.io/math-rsi/ "项目主页 / EN + 中文")&nbsp; [![快速开始 / 立即上手](figures/mathrsi/badges/quick-start.zh-CN.svg)](#开始使用)&nbsp; [![数学成果 / 6 大方向](figures/mathrsi/badges/results.zh-CN.svg)](case-studies/README.md)&nbsp; [![Agent 指南 / 工作流 + Wiki](figures/mathrsi/badges/agent-guide.zh-CN.svg)](docs/WORKFLOWS.md)&nbsp; [![贡献者 / 团队](figures/mathrsi/badges/contributors.zh-CN.svg)](#contributors)&nbsp; [![EN / English](figures/mathrsi/badges/lang-en.svg)](README.md)

</div>

MathRSI 结合通用工作流、领域插件与单题研究知识库，引导 Claude Code 或 Codex 完成文献调研、路线探索、证明、审阅、验证与交付。研究成果和失败经验持续用于改进工作流与插件。

[![MathRSI 历史主页 v0 → v6 演进回放](figures/mathrsi/media/evolution.gif?v=6-q7-20261120)](figures/mathrsi/media/evolution.mp4?v=6-q7-20261120)

*历史主页 v0 → v6 演进回放；画面中的“Current”指当时的 v6。点击观看 MP4；[完整交互主页](https://lisresearchgroup.github.io/math-rsi/) · [六个数学案例与核验范围](case-studies/README.md)。*

**43 位码研究回放**

[![MathRSI 工作台总览](figures/mathrsi/media/workbench-zh.webp)](figures/mathrsi/media/workbench-zh.mp4)

*打开[交互工作台](https://lisresearchgroup.github.io/math-rsi/workbench/index.html?lang=zh#wb-demo) · [观看中文 MP4](figures/mathrsi/media/workbench-zh.mp4)。三位研究角色重演已完成的证明，回放中的生成矩阵和排除见证来自项目归档。*

<a id="news"></a>

## 📢 版本动态

[2026 年 11 月数学成果](https://lisresearchgroup.github.io/math-rsi/november-2026-zh.html)

- **[v8](https://github.com/lisresearchgroup/math-rsi/releases/tag/v8)** · 2026-11-23 — 18 组参数有了更好的二元线性码，生成矩阵可以直接下载。上界方面，从已发表的定理推出了 32 项改进，其中 9 项确定了最优距离。另有两项等待原研究项目最终验收。
- **[v7](https://github.com/lisresearchgroup/math-rsi/releases/tag/v7)** · 2026-11-22 — 七维超立方体的工作证明已覆盖所有匹配，每个匹配都能延拓为哈密顿圈。凸多边形研究的新稿给出了 ES(8) ≤ 294、ES(9) ≤ 1,100、ES(10) ≤ 3,980 三个上界。
- **[v6](https://github.com/lisresearchgroup/math-rsi/releases/tag/v6)** · 2026-11-20 — 七维超立方体中，保证匹配能延拓为哈密顿圈的门槛从至少 57 条边降至至少 56 条。八维超立方体中，无四边形子图的最大边数被限定在 682 与 683 之间。

<details>
<summary>早期版本（v1–v5）</summary>

- **[v5](https://github.com/lisresearchgroup/math-rsi/releases/tag/v5)** · 2026-11-14 — 在七维超立方体中，至少含 57 条边的匹配都能延拓为哈密顿圈。证明通过改变同一个匹配的表示来复用已有定理，这个技巧也进入了通用工作流。
- **[v4](https://github.com/lisresearchgroup/math-rsi/releases/tag/v4)** · 2026-11-08 — 从凸多边形的证明中，团队提炼出一种方法，沿不等式逐步回溯，找出必须同时取等的条件。度–直径插件也加入了构造更大图的方法。
- **[v3](https://github.com/lisresearchgroup/math-rsi/tree/v3)** · 2026-11-04 — 新增三个插件，分别研究超立方体中的无四边形子图、超立方体匹配延拓和凸多边形。MathRSI 由此覆盖六个数学领域。
- **[v2](https://github.com/lisresearchgroup/math-rsi/tree/v2)** · 2026-11-03 — 度–直径插件加入 MathRSI。团队用这个插件首次试行版本维护流程，把图构造中积累的经验写回通用工作流。
- **[v1](https://github.com/lisresearchgroup/math-rsi/tree/v1)** · 2026-11-03 — 从超图二染色（Property B）和编码理论两项研究中，团队提炼出第一套通用工作流，涵盖问题界定、路线探索、证明、核验和交接。

</details>


<a id="开始使用"></a>

## 1. 🚀 快速开始

**一键启动数学工作台。** 准备好 Git、Python 3.10+、[pipx](https://pipx.pypa.io/stable/installation/) 和已登录的 Agent 客户端，在终端运行：

```sh
git clone --depth 1 https://github.com/lisresearchgroup/math-rsi.git
pipx install "git+https://github.com/wanshuiyin/SuperARIS.git"
mathrsi
```

在向导里选择自己的课题目录；提示填写 MathRSI 仓库时，选择刚克隆的 `math-rsi` 文件夹，再选团队和模型。以后打开工作台，直接输入 `mathrsi`。

**直接用 Claude Code 或 Codex。** 在客户端打开克隆的 `math-rsi` 文件夹，并允许访问课题目录。在 Claude Code 输入 `/mathrsi-research 研究 ../my-problem/problem.md 中的问题`；在 Codex 用 `$mathrsi-research` 接同一句请求。

**按需接入独立审阅。** 例如，Claude Code 可以通过 MCP 请 Codex 检查一份证明。[连接 MCP 审阅者](docs/REVIEWER_MCP.md) · [完整安装、验稿与恢复指南](docs/QUICKSTART.md)

<a id="六个数学方向"></a>

## 2. 🧮 数学成果

六个领域的研究同时积累数学结果和可复用方法。[公开主页](https://lisresearchgroup.github.io/math-rsi/) · [本地运行方法](docs/HOMEPAGE.md)。**[中英可视化导览](https://lisresearchgroup.github.io/math-rsi/)**展示问题、成果与演进；**[六题统一索引](case-studies/README.md)**连接证明、核验范围和可运行工具。

[![六题数学成果速览](figures/mathrsi/results-overview/results-overview.zh.svg?v=8-ecc)](case-studies/README.md)

- **Property B：** $k=5,\ldots,12$ 的具体下界，以及所有 $k\ge12$ 随参数指数增长的加性增益。[成果与证明范围](case-studies/property-b/README.md)
- **纠错码。** 18 组参数的生成矩阵可下载。在 37 项有证据支持的上界改进中，13 项与已有码的距离相等，确定了最优值。另有两项等待原项目最终验收。 [查看构造与矩阵](https://lisresearchgroup.github.io/math-rsi/ecc-intervals.html#lower) · [查看上界与证明](https://lisresearchgroup.github.io/math-rsi/ecc-intervals.html#upper)
- **Degree–Diameter：** 四组展示参数的构造： $(10,4)$ 为 2,567 点； $(11,5)$ 为 37,632 点； $(12,5)$ 为 42,433 点； $(16,4)$ 为 16,416 点。[构造、日期比较与核验范围](case-studies/degree-diameter/README.zh-CN.md)
- **Erdős 第 86 题：** 七维超立方体的无四边形子图最多有 [304 条边](https://arxiv.org/abs/2611.27284)，$682\le\mathrm{ex}(Q_8,C_4)\le683$，渐近密度上界从 $0.60318$ 推进至 $\le0.5912405943$（`T3`）／$\le0.5912405942$（`T4`）。[结果与核验范围](case-studies/erdos-86/README.md)
- **Ruskey–Savage：** 完整作者工作证明覆盖 $Q_7$ 的任意匹配（包括空匹配与完美匹配），保留 $Q_6$ 全称结果；待外部同行评议，无 Lean。[证明、局部复算与版本历史](case-studies/ruskey-savage-q7/README.md)
- **Happy Ending 与 $N(m,r,s)$：** 新同输入扇区缺额工作稿给出平面工作推论 $\mathrm{ES}(7)\le77$、$\mathrm{ES}(8)\le294$、$\mathrm{ES}(9)\le1100$、$\mathrm{ES}(10)\le3980$；独立数学审阅尚未完成。先前可重放的有限证书保留各自范围与来源。[现值、证据与复现](plugins/happy-ending/archive/nmrs-20261120/HANDOFF.md) · [案例导读](case-studies/happy-ending/README.md)

<a id="三层架构"></a>

## 3. 🧩 三层架构

![MathRSI 三层架构：Base 调用领域方法，读取、更新并复用任务工作区；独立维护改进 Base 和 Plugins](figures/mathrsi/architecture-three-layers.svg)

**Base**（`base/`）提供通用研究方法；**领域插件**（`plugins/`）提供专门数学和检查器；**任务工作区**保存单题规格、wiki、证明、证书与恢复状态。[架构与插件契约](docs/PLUGIN_CONTRACT.md) · [可编辑源文件与 GPT Image 版本](figures/mathrsi/README.md)

<a id="研究如何推进"></a>

## 4. 🔬 研究如何推进

主入口 [`mathrsi-research`](base/skills/mathrsi-research/SKILL.md) 协调 **准备 → 路线 → 证明 → 验证 → 交付**，从当前证据进入并读取每阶段实际产物。任务 wiki 贯穿读取、更新和再次使用；职责明确的协作者与跨模型 reviewer 参与研究。

| 当前需要 | 使用入口 |
| --- | --- |
| 明确新问题，调查文献 | [Prepare · 准备](base/skills/mathrsi-prepare/SKILL.md) |
| 续接研究或未完成证明 | [路线迭代](base/skills/mathrsi-route-loop/SKILL.md) · [证明推进](base/skills/mathrsi-prove/SKILL.md) |
| 检查并修复候选证明或证书 | [Verify · 验证](base/skills/mathrsi-verify/SKILL.md) · [证明修复示例](examples/proof-repair/README.md) |
| 交付已有成果并供后续复用 | [Handoff · 交付](base/skills/mathrsi-handoff/SKILL.md) |

[详细工作流与返回路径](docs/WORKFLOWS.md) · [六领域路由](docs/DOMAIN_ROUTING.md) · [工作区与记忆](docs/WORKSPACE.md)

<a id="研究经验如何改进工作流"></a>

## 5. 🔄 研究经验如何改进工作流

![研究证据经单独维护转为更强 Base 和更深领域插件](figures/mathrsi/research-to-capabilities.svg)

两条线共同演进：**共享 Base 的行为持续强化**，**领域 Plugins 持续扩展与深化**。独立的 [`mathrsi-meta-evolve`](base/skills/mathrsi-meta-evolve/SKILL.md) 维护流程把研究证据转成实际改动。

- **v8 通用流程与 ECC 插件。** 从一个构造推到相邻参数时，把变换后的对象一并交付。同组参数保留最强的见证。对于很少触发的排除条件，用已知应被拒的输入检验。ECC 插件据此导出 18 份生成矩阵，也保留了每项上界推导所用的前提。[方法与实例](docs/V8_CHANGES.md)

- **v6 通用流程：** 采纳新分类前，先在最难的未闭合分支上做小规模试探，并在同一输入上统计新增覆盖；上下界协同搜索中把证明目标与对抗搜索目标分开，轮换四路归一化带符号残差，并在全部历史构造上检验候选不等式；当浮点 SDP 或完全正规划的单轮增益不高于有理化修补误差时及时停机。
- **深化领域插件：** `hypercube-extremal` 新增渐近 COP + $m=1024$ 广义度数势上界（`T3` / `T4`）、同一子图耦合三组测度的有限维拉回（$Q_8 \le 683$）、$Q_7$ 304 边构造与原包报告归档，以及可复用的 `cube_coevolve` 引擎；`hypercube-hamilton` 完成 $Q_7$ 完整 E16（$\ge 56$ 边，涵盖全部 $\mu=0..4$），加入参数化 $Q_6$ $\Delta=2$ 双桥、$Q_6$ $A_8$ 及大面 $S_6$ 独立孔表与小面符号原孔的组合建模；`happy-ending` 新增 $m=7,8,9$ signotope 受限容量的跨平台核验器与精选归档（$N(8,6,6)\le 61$ 共享标签 CEGAR、$N(9,8,8)\le 688$ 与 $D_9\le 458$ 参数化稀疏整数对偶及松弛封顶停机判据；由 **Trellis + ARIS + v3** 做出，并入主线维护，固定 `v6` 标签不变）。
- **Q₇ 后续维护 · 2026-11-20：** `main` 吸收原项目 11 月 19 日接受的完整 R7 作者工作证明。研究使用 v3 本地适配；固定 v5（≥57 边）与 v6（≥56 边）快照不变。[证明导读](https://github.com/lisresearchgroup/math-rsi/blob/main/plugins/hypercube-hamilton/knowledge/q7-closure-proof.md) · [复算范围](https://github.com/lisresearchgroup/math-rsi/blob/main/plugins/hypercube-hamilton/archive/q7-closure/README.md)
- **延续既有能力：** 保留 v5 的受控辅助选择、跨等价表示复用定理、先消化返回结果再派发新任务，以及 v4 的把取等情形收成可用见证、全局进展重评和 ECC 分支计算共享。

**[MathRSI v8 是最新正式版](https://github.com/lisresearchgroup/math-rsi/releases/tag/v8)。** [更新说明](docs/V8_CHANGES.md) · [下载 v8](https://github.com/lisresearchgroup/math-rsi/archive/refs/tags/v8.zip) · [下载 main](https://github.com/lisresearchgroup/math-rsi/archive/refs/heads/main.zip) · [演进记录](development/README.md) · [维护指南](docs/EVOLUTION_WORKFLOW.md)

v0 记录通用框架形成前的 Property B 和编码研究。首个版本标签是 v1。 [历版动态](#news) · [早期架构图](figures/mathrsi/README.md#historical-diagrams)

<a id="文档与来源"></a>

## 6. 📚 文档与来源

**[按目的选择阅读路径](docs/README.md)** · [六题研究案例](case-studies/README.md) · [仓库地图](docs/README.md#repository-map) · [验证记录](development/README.md#validation-and-implementation) · [技能验收](docs/SKILL_ACCEPTANCE.md) · [参与贡献](CONTRIBUTING.zh-CN.md)

基于 **[ARIS](https://github.com/wanshuiyin/Auto-claude-code-research-in-sleep)** 和插件／案例保留的研究原件。随仓 ARIS 快照为 `c485faa59a68e51c6575dea67ca57abc7a6a2b9c`。[来源说明](docs/PROVENANCE.md) · [快照清单](base/ARIS_SNAPSHOT.json) · [桥接来源](mcp-servers/SOURCE.md)

工作流和脚本采用 **[MIT 许可证](LICENSE)**；归档论文与第三方材料保留原版权。

<a id="contributors"></a>

## 7. 👥 贡献者

### 核心贡献者

Ruofeng&nbsp;Yang<sup>&#42;</sup>, Haitong&nbsp;Ma<sup>&#42;</sup>, Kaitao&nbsp;Qiu, Zuhao&nbsp;Zhang, Jiaxuan&nbsp;Sun, Tianzhi&nbsp;Ren, Zheli&nbsp;Zhou, Shuai&nbsp;Li<sup>#</sup>

<sup>&#42;</sup> 同等贡献。<sup>#</sup> 通讯作者。

### 贡献者

按姓氏字母顺序排列。

Haitham&nbsp;Bou&nbsp;Ammar, Dimitris&nbsp;Tsaras, Rasul&nbsp;Tutunov, Jun&nbsp;Wang, Kuan&nbsp;Yang, Qiaosheng&nbsp;Zhang, Zhinuo&nbsp;Zhou

<a id="acknowledgements"></a>

### 🙏 致谢

感谢 [@mizopl](https://github.com/mizopl) 和 we\* 项目（PROOFER）分享八维超立方体的 10 份无四边形子图构造、Case 5A 的独立核验程序，以及用 Lean 4 证明的计数引理。[查看这项贡献](plugins/hypercube-extremal/tools/q8-forcing/README.md) · [Issue #60](https://github.com/lisresearchgroup/math-rsi/issues/60)
