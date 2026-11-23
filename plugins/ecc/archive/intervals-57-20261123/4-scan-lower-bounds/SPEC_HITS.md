# 命中验收规格（调度者定稿，2026-11-22）

第一轮开始后几分钟内即出现命中（73-42、74-43、75-43、78-46 四个基码、7 个目标），命中可能有几十个，验收必须批量、可重跑。上位纪律见 `SESSION_PROMPT.md` 第 9 节。

## 1. 数学

基码 B：`[n0,k0]`，校验矩阵 H（ρ×n0，列整数见 `SPEC_TOOLS.md` 第 1 节）。命中目标给出类型（A/L）、目标格、`new_d`、`depth`。

- 取 s 为 `raw.json` 的 `free` 中 `t = depth-1` 那一项的 reps 里的一个（默认取第一个，即最小的未覆盖伴随式）；s ∉ L_{depth-1}(H) 即陪集 s 的最小重量 ≥ depth。
- 解 `H x = s`（GF(2)，任取一解，约定取自由变量全 0 的解）。
- B 的生成矩阵 G_B：H 的核的一组基（k0 行，n0 列）。
- A 型：最终码 = B + ⟨x⟩，生成矩阵 `[G_B; x]`，参数 `[n0, k0+1]`，距离 = min(d(B), depth(s)) ≥ new_d。
- L 型：最终码 = {(c,0)} ∪ {(x+c,1)}，生成矩阵 `[G_B|0; x|1]`，参数 `[n0+1, k0+1]`，距离 = min(d(B), depth(s)+1) ≥ new_d。

验收对象是**最终码的生成矩阵 G**（K×N）：秩 K，且最小距离 ≥ new_d。上面的推导只是来源说明，不作证据；证据是对 G 的直接、完整验距。

## 2. 文件格式

`G.txt`：K 行，每行 N 个字符 `0`/`1`，第 j 个字符是第 j 个坐标（j 从 0 起，坐标顺序 = 基码 `.cols` 的列顺序，L 型的新坐标排在最后）。

## 3. 验距程序的接口（两套实现共用同一接口，互不看源码）

```
verify G.txt D out.json [threads]
```

判定 `d(C) ≥ D` 是否成立，C 是 G 的行空间。必须精确、完整、无抽样、无概率性步骤。`out.json`：

```
{"n":N,"k":rank(G),"rows":行数,"D":D,"d_ge_D":true|false,
 "method":"一句话说明所用的完备判据",
 "work":{...枚举了多少对象等计数...},
 "witness": null | {"codeword":"N 位 0/1 串","weight":w}   # d_ge_D=false 时给出重量 < D 的非零码字
}
```

规模：N ≤ 260，N−K ≤ 41（K 可达 240 以上，直接枚举 2^K 个码字不可行），D ≤ 40。多数命中 N−K ≤ 33，应在 8 核、40 GiB、数分钟内完成；N−K 到 40 时允许用到 64 线程、400 GiB。退出码：0 = 判定完成（无论真假），非 0 = 出错。

## 4. 批量驱动（实现 A 的任务）

`tools/hit_process.py [--id <基码id>] [--all]`：对 `hits/pending/<id>/` 的每个命中目标：

1. 按第 1 节构造，写 `hits/<N>-<K>/<id>-<A|L>/`：`G.txt`、`base.cols`、`s.txt`（十进制）、`x.txt`（n0 位 0/1）、`build.json`（基码 id、类型、目标格、new_d、depth、ρ、秩证据：rank(H)、rank(G_B)、rank(G)、`G_B·H^T=0`、`H x = s` 的核对结果、raw 的 sha256、各文件 sha256）、`DERIVATION.md`（推导文字，写明哪些是来源说明、哪些是证据）。
2. 运行验距 A：`verify_A.json`、`verify_A.log`。
3. 若 `tools/verify_b/verify_b` 存在则运行验距 B：`verify_B.json`、`verify_B.log`。
4. 查码表实时页：GET `https://www.codetables.de/BKLC/BKLC.php?q=2&n=<N>&k=<K>`，保存原始 HTML（`codetables_live.html`）和解析出的 lower/upper bound、取回 UTC 时间（`novelty_codetables.json`）；请求之间间隔 ≥ 3 秒，同一格只取一次（缓存在 `hits/_codetables_cache/`）。
5. 写 `STATUS.json`：`{"status": "verified" | "failed" | "partial", "note": ..., "checks": {"rank":..., "verify_A":..., "verify_B":..., "codetables_live_lb":..., "improves_live": new_d > live_lb}}`。`verified` 要求：秩正确、A 与 B 都 `d_ge_D=true`、`new_d > live_lb`。只有 A 时为 `partial`。任一验距为 false → `failed`，并发事件（`sched/events.py` 的 emit，类型 `hit_verify_failed`）。
6. 维护 `hits/INDEX.json` 和 `hits/INDEX.md`：每个目标格一行（目标格、码表下界、新下界、是否闭合区间、来源基码与类型的列表、各自状态）。同一目标格有多个来源时都保留。

幂等：已 `verified` 的不重做；`--force` 重做。看板读 `hits/` 下的 `STATUS.json`（见 `sched/README.md` 第 7 节的约定，必要时让看板也读 `hits/INDEX.json`）。
