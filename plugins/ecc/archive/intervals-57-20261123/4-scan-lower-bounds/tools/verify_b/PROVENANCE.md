# 验距 B（Sol 独立实现）的来源

- 模型 gpt-6.1-sol，经 codex 桥，sandbox=read-only，reasoning effort high；提示只含 `SPEC_HITS.md` 第 2、3 节的接口与规模要求，明确禁止读取本工作区已有源码。
- v1：thread 01a203ec-53d2-7b20-805b-8cea789a3bd1，原始记录 `/home/user/math/aris4math_v2/vendor/codex-home/sessions/2026/11/22/rollout-2026-11-22T23-42-29-01a203ec-53d2-7b20-805b-8cea789a3bd1.jsonl`；该会话中工具调用行数（function_call/exec_command）= 0。
- `sol_reply_v1_raw.md` 为完整原始回复，`verify_b_v1.cpp` 为逐字提取的代码块，sha256 = 0c88b4ed12675f4974a7fe1a0ce2b9588f4ef1fe830996e3ae3ee6784af0f153。
- v1 的判据：坐标分两半，一半枚举重量 ≤ ⌊(D−1)/2⌋ 的子集建表，另一半枚举全部重量 ≤ D−1 的子集查表，两个方向各做一次。完备，但另一半的枚举量是 Σ_w C(N/2,w)，N≈256、D≈12 时约 10^15，不可行；N ≤ 约 90 的命中可用。
- 调度者未改动源码。

## v2（同一 thread 的续问，2026-11-22）

- 起因：v1 规模不达标。续问只指出规模问题并给出通用的可行性提示（任意 ≤ D−1 列线性无关；把码字支集任意拆成两半，只需枚举大小 ≤ ⌈(D−1)/2⌉ 的列子集；位图或哈希表），未提供任何源码。
- `sol_reply_v2_raw.md` 为完整原始回复，`verify_b_v2.cpp` 为逐字提取的代码块，sha256 = 9786c6a64202d7fe705d6c52d9fe0ae97375ab2d7c46dc1c29e75c5b569cb7d6。整个会话的工具调用行数 = 0（Sol 未读取任何文件）。
- `verify_b` 可执行文件由 v2 构建：`g++ -O3 -std=c++17 -static -pthread -o verify_b verify_b_v2.cpp`。v1 的可执行文件保留为 `verify_b_v1`，可作第三个对照。

## v3（同一 thread，2026-11-23）

- v2 用 g++ 11.4 编译失败（原子成员导致移动赋值被删除；一处变量名少下划线）。把编译器报错原文发回，Sol 给出完整 v3；同时要求其自查并发插入与重试计数两点。未提供任何源码或补丁。
- `sol_reply_v3_raw.md` 为完整原始回复，`verify_b_v3.cpp` 为逐字提取的代码块，sha256 = 4090064d3b702c35bcd426929ef852b759324239f1e4acb08d0260e6be89edc2。整个会话的工具调用行数 = 0。
- **当前 `verify_b` = v3 构建**（上一节关于 v2 构建的说法作废：v2 未能编译，其间 `verify_b` 一直是 v1）。

## v4（同一 thread，2026-11-23）——当前 `verify_b`

- v3 能编译，但调度者的黑盒对照（`tools/lead_bruteforce_check.py`：随机小码穷举全部码字求真实最小距离）发现两类故障：(a) 真实 dmin < D 时有约 1% 的用例**错判为 d_ge_D=true**；(b) D > dmin 时大量以“搜索内部错误”退出。v1 在同一对照下 0 问题。
- 发回给 Sol 的只有三个具体失败输入和现象描述，并要求其对照自己的完备性证明自查；未提供源码或补丁。Sol 给出的根因：v3 插入当前重量层时没有查询此前各层的集合，漏掉了跨层重复；恢复另一子集时重量范围取错。
- `sol_reply_v4_raw.md` 为完整原始回复，`verify_b_v4.cpp` 为逐字提取的代码块，sha256 = 70f1354ba54140134fe3fc81827e20f150720a7c067544d70e7454923596dab7。该 thread 全程只有 1 次工具调用（Sol 用 python 手算例 3 的码字，未读任何工作区文件）。
- v4 的黑盒对照：种子 11（1,500 次判定）、20261123（2,400 次）、7（2,400 次），0 问题；同一脚本对 v3 仍报 WRONG/RC（说明对照能抓到这类错误）。
- `verify_b` = v4 构建，sha256 见 `sha256sum tools/verify_b/verify_b`。v1 可执行文件保留为 `verify_b_v1`（方法不同：坐标分半；N ≤ 约 90 时可作第三个对照）。
- 教训记录：独立实现本身也必须先过穷举对照再用于验收；v3 若直接使用会给出错误的“通过”。
