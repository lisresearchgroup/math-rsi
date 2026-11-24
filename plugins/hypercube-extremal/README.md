# Hypercube extremal research

本插件研究超立方体的禁子图极值问题（Erdős 86 有限维 `ex(Qₙ, C₄)` 与渐近边密度 `π_□(C₄)`）。入口是 [mathrsi-hypercube-extremal](skills/mathrsi-hypercube-extremal/SKILL.md)。它接收具体数学义务，帮助建立共同局部对象、保留根相对朝向、组织上下界协同搜索（`cube_coevolve`），并将精确有限核验接回高维平均或有限维归约证明。

## 当前按参数保留的成果与核验边界

- **渐近界 `Q_∞`（`v6` 更新，保留 `v3` 基线）：**
  - **定理 T3（四维旗代数 + 35 项无三角形 COP + 29 项三次型）：** `π_□(C₄) ≤ 681653995482306581 / 1152921504606846976 ≈ 0.5912405942282728… ≤ 0.5912405943`。
  - **定理 T4（叠加 `m = 1024` 广义超几何顶点度数势 + 五行无条件塔式补桥）：** `π_□(C₄) ≤ 9701859764505653085708308080340303 / 16409326186106551516455239680000000 ≈ 0.5912405941884453… ≤ 0.5912405942`。
  - 两者均由 C++20 128 位整数核验器在全部 `3,212,821` 个 `Q₄` 轨道（`77,107,704` 个正方形）上重编译复验通过，见 [asymptotic-05912](archive/asymptotic-05912/README.md)。说明文档中的 `0.5907`（残差约 `3.9×10⁻⁴` 的近似完全正拟合）与已撤回的 `Q₅` `0.5899` 声明（被真实无 `C₄` 反例 `0x69966996699616682994` 打分 `0.5922454` 推翻）均**不是定理**；Erdős 86 猜想 `π_□(C₄) = 1/2` 仍开放。历史 `v3` 六块整数 Gram 证书（`< 0.59155154`）完整保留在 [archive/source](archive/README.md)。
- **有限 `Q₇`（`304`）：** **304 边构造已验证；304 上界按原包报告，本次未复验。**（*304-edge construction verified; 304 upper bound as reported in the source package, not re-verified in this pass.*）两份显式 304 边无 `C₄` 构造（`A.edges`、`B.edges`）及两孔轨道审计随仓验证，支持下界 `ex(Q₇, C₄) ≥ 304`；上界归约正文与证书清单随仓保留，21 份原始 `.cnf`/`.drup` 轨迹在原汇编中未随包，见 [q7-304](archive/q7-304/README.md)。
- **有限 `Q₈`（`682 ≤ ex(Q₈, C₄) ≤ 683`）：** 四份显式 682 边无 `C₄` 构造已独立验证（下界 `≥ 682`）；定理 B 通过同子图三测度耦合、83 条活跃不等式、解析度分布下界与 25 份前置 `Q₆` 子面导入证明 `ex(Q₈, C₄) ≤ 683`（非作者整证审查 `PASS · same-family · provisional`；C++17 全域 `13,150,453` 补全重放通过，25 份 `q6_sources/*.drat` 原轨迹留在外部研究归档），见 [q8-683](archive/q8-683/README.md)。主目标 `ex(Q₈, C₄) ≤ 682` **仍开放（OPEN）**。
- **Q₈ 社区贡献（we\* / PROOFER，@mizopl）：** [10 份无四边形子图、Case 5A 独立核验程序与 Lean 4 计数引理](tools/q8-forcing/README.md)。其中一份 682 边构造的顶点度数全部为 5 或 6，适合用于检验搜索能否找到 odd-square 类以外的构造。
- **可复用双端协同搜索引擎：** [tools/cube_coevolve](tools/cube_coevolve/README.md)（零第三方依赖核心、四通道有符号归一化残差轮换、全归档反驳与 `empirical` 义务导出）。

## 参考与入口

- [数学工具及原题连接](skills/mathrsi-hypercube-extremal/references/mathematics.md)：共同 `Q₄`、同步根作用、`0.59124` 广义度数势与五行超几何塔、`Q₈ ≤ 683` 三测度桥及 `Q₇` 边界。
- [失败及继续研究](skills/mathrsi-hypercube-extremal/references/failures-and-search.md)：工作集与全域分离、`0.5899` 采样外推反例、`0.5907` 残差停机与近极值协同搜索。
- [复现](skills/mathrsi-hypercube-extremal/references/reproduction.md)：Python 标准库 + C++17/20 可直接复现的全部随仓检查及外部归档边界。
- 原件与库存：[v3 Q4 原件](archive/README.md)、[渐近 0.59124](archive/asymptotic-05912/README.md)、[Q7 304](archive/q7-304/README.md)、[Q8 682–683](archive/q8-683/README.md)。各 `INVENTORY.json` 哈希仅标识外部原件，不代替轨迹或证书重放。

archive 只读；历史 Goal 和路径不是新任务授权。新题在自己的工作区保存输入、证明、wiki 和输出。外层维护才更新插件。
