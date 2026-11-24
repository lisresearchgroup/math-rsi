# Start a mathematical task with MathRSI

## Open the mathematics workbench

The SuperARIS package provides the `mathrsi` command; the MathRSI checkout supplies the mathematical workflows and domain plugins. Have Git, Python 3.10+, [pipx](https://pipx.pypa.io/stable/installation/) and a signed-in Claude Code or Codex CLI ready. Use your existing MathRSI clone or clone it once:

```sh
git clone --depth 1 https://github.com/lisresearchgroup/math-rsi.git
pipx install "git+https://github.com/wanshuiyin/SuperARIS.git@48ad483"
mathrsi
```

In the wizard, choose the directory for your problem and enter the path to the MathRSI checkout when prompted. Choose your workbench, team and models. Run `mathrsi` again for the next session. If you already use a pipx installation of SuperARIS that only exposes `superaris`, add `--force` to the install line above to replace that installation with the linked revision. If your shell cannot find pipx-installed apps, run `pipx ensurepath` and reopen your terminal.

## Start directly in Claude Code or Codex

After completing [setup](#get-the-repository-and-choose-a-workspace), open this repository in **Claude Code** or **Codex** with access to your task directory. In Codex, replace `/skill` with `$skill`. Replace the example paths below with your own.

**Start from a mathematical problem**

```text
/mathrsi-research Study edge-count lower bounds for k-uniform hypergraph two-coloring; work in ../my-problem/
```

Connects literature research, route exploration, proof work, verification and handoff, reusing the task wiki throughout. If you already have a problem statement, you can pass `../my-problem/problem.md` instead.

**Check a candidate proof or local lemma**

```text
/mathrsi-verify Check ../my-problem/proof.tex
```

Checks the proof or a specific obligation, repairs local omissions and identifies substantive mathematical gaps that need further proof work.

**Resume an existing study** (Codex example)

```text
$mathrsi-research Continue the study in ../my-problem/
```

Reads the task's existing specification, wiki and resumption notes, then continues from the current evidence. In Claude Code, use `/mathrsi-research`.

## Get the repository and choose a workspace

Use `main` for the current workflow, or clone a [tagged release](https://github.com/lisresearchgroup/math-rsi/releases) and record its revision in your task handoff. See the [evolution records](../development/README.md).

You need Git and an installed, authenticated agent host (Claude Code or Codex). Python 3.9+ runs the included replay and reviewer bridges. Additional tools are needed only for the actions you choose: reviewer CLIs and accounts for external reviews, network/search access for literature work, TeX for PDF compilation, or a task-specific Lean environment for formalization. None of these accounts or toolchains is supplied by cloning the repository.

The selected Q7 replay requires **Python 3.11+**; see the [Q7 replay package](../plugins/hypercube-hamilton/archive/q7/README.md) for its additional requirements.

Run in a terminal, choosing a different parent directory if desired:

```bash
mkdir -p "$HOME/src"
git clone https://github.com/lisresearchgroup/math-rsi.git "$HOME/src/math-rsi"
cd "$HOME/src/math-rsi"
export MATHRSI_ROOT="$(pwd -P)"
export ARIS_REPO="$MATHRSI_ROOT/base"
python3 --version
```

Git will use your existing GitHub authentication. The HTTPS URL can also be replaced with the organization's SSH clone URL when your account is configured for SSH.

Keep the current problem in its own workspace. If you already have a specification, proofs, a `NEXT_SESSION.md`, or a research wiki, use that directory. Read the recovery entry and then the original evidence it points to; do not initialize a second wiki or replace old file names just to match this guide. For a new task:

```bash
mkdir -p "$HOME/research/my-problem"
export TASK_ROOT="$(cd "$HOME/research/my-problem" && pwd -P)"
```

Place the problem statement and available source materials there. The workflow will create only the documents the task needs. A short proof can live in one document; a long investigation benefits from a specification, proof directory, wiki, and recovery entry. See [workspace and recovery guidance](WORKSPACE.md).

The exports above apply to this terminal. In each new shell, set `ARIS_REPO` to **this clone's `base` directory** again. Agent tool calls may use independent shells, so include the export in the same call as a helper, or use its absolute path:

```bash
export ARIS_REPO="$HOME/src/math-rsi/base"
python3 "$ARIS_REPO/tools/research_wiki.py" --help
```

An old task may have its own `tools/` or `.aris/tools/` helpers, which some upstream resolvers prefer. Tell the agent to use this clone's absolute helper paths and inspect any local overrides before relying on them. Do not run the bundled upstream installers to set up MathRSI; the complete skills and resources are already in `base/`. Details are in [ARIS reuse](ARIS_REUSE.md).

## Launch Codex or Claude Code

Starting the host in the clone allows its project skill aliases to be discovered. Give it access to the task directory as well. Choose one host:

```bash
cd "$MATHRSI_ROOT"
codex --add-dir "$TASK_ROOT"
```

```bash
cd "$MATHRSI_ROOT"
claude --add-dir "$TASK_ROOT"
```

These are agent-host commands, not MathRSI commands. Check your installed host's `--help` if it differs. With a desktop host, select the clone as the project and grant the task directory through that host's directory controls. You can also start in an existing task workspace and explicitly provide the skill's absolute path; project aliases may then be unavailable, but reading the actual skill works.

### If project skills are not discovered

The clone provides project-relative aliases in `.claude/skills/` and `.agents/skills/`; cloning does not install them globally or set `ARIS_REPO`. Use the short calls above once the host discovers these aliases. If discovery has not refreshed, the explicit-path fallback below remains available. Replace its paths with actual absolute paths; shell variables in chat text are not automatically expanded.

```text
Read /absolute/path/to/math-rsi/base/skills/mathrsi-research/SKILL.md
and execute it for the task in /absolute/path/to/my-problem.

The original problem and constraints are in problem.md. Restore the existing
specification, NEXT_SESSION.md, relevant wiki entries, proofs and evidence
before deciding where to enter. For a new problem, begin with preparation
and actual literature discovery, then fix the precise original statement.

Continue through the applicable stages to a supported proof, construction,
permitted counterexample, or precise unresolved obligation. Read each stage's
actual output before starting its successor. Preserve the original target.
Use helpers only from /absolute/path/to/math-rsi/base/tools, setting
ARIS_REPO=/absolute/path/to/math-rsi/base in each helper shell call.
Keep generated research files in the task workspace and reuse its wiki.

Use the reviewer setup agreed for this task. Record actual calls and their
scope; report unavailable dependencies accurately. Deliver a readable proof,
verification evidence and a recovery/handoff entry. Do not change MathRSI's
core or its acceptance conditions while solving the problem.
```

For degree–diameter graphs, add: “Also read `plugins/degree-diameter/skills/mathrsi-degree-diameter/SKILL.md` in this clone. Preserve the original graph target and use the relevant construction, obstruction, or transfer skill within the current stage. Read the historical wiki and supporting sources as needed; write new results to my task workspace.” The [DD plugin guide](../plugins/degree-diameter/README.md) gives the actual theorem conditions, programs, and archived evidence. `$mathrsi-degree-diameter` / `/mathrsi-degree-diameter` and its three subordinate skills have project-relative discovery aliases.

For Property B, add: “Also read `plugins/propertyb/skills/mathrsi-propertyb/SKILL.md` in this clone and use its methods where they address the current obligation.” The repository contains the corresponding knowledge and executable checks. The upgraded ECC and three new domain capabilities use the same parent/return contract:


| Your problem | Also read in this clone | Concrete use |
| --- | --- | --- |
| Binary linear codes | [mathrsi-ecc](../plugins/ecc/skills/mathrsi-ecc/SKILL.md), [ecc-certificate](../plugins/ecc/skills/ecc-certificate/SKILL.md) | Pass n/k/d, actual matrix or parent/coset/pair obligation; consume the exact witness or scoped exclusion result. |
| Cube forbidden-subgraph density | [mathrsi-hypercube-extremal](../plugins/hypercube-extremal/skills/mathrsi-hypercube-extremal/SKILL.md) | Pass the original density target and common local object; consume the exact local certificate and averaging bridge separately. |
| Cube matching extension | [mathrsi-hypercube-hamilton](../plugins/hypercube-hamilton/skills/mathrsi-hypercube-hamilton/SKILL.md) | Pass the matching, root/target and required edges; consume the marked reduction or finite universal certificate. |
| Happy Ending / signotopes | [mathrsi-happy-ending](../plugins/happy-ending/skills/mathrsi-happy-ending/SKILL.md), [happy-ending-certificate](../plugins/happy-ending/skills/happy-ending-certificate/SKILL.md) | Pass geometric vs abstract object, path parameters and proof/witness scope; retain the weak/split distinction. |

For a bounded verification request, say: “Use the domain skill within the current verify stage. Read the actual input, run its documented checker in my task scratch directory, and return what it proves and the remaining original-problem connection. Keep archived sources read-only.” You can then use the [real replay commands](V3_CHANGES.md#bounded-commands-from-the-current-clone) without starting an archived research Goal.

The MathRSI entry skills are host-neutral. When they call an embedded ARIS skill, **Codex reads `base/skills/skills-codex/<name>/SKILL.md`; Claude reads `base/skills/<name>/SKILL.md`**. Relative aliases under `.agents/skills/` and `.claude/skills/` support project discovery. If loaded, `$mathrsi-research` in Codex or `/mathrsi-research` in Claude can invoke the entry; explicit file reading remains usable when discovery has not refreshed.

## Enter at the stage your evidence supports

You do not need to restart a whole research cycle to check an existing proof. The main entry chooses among these stages, or you can request one stage directly:

| What you have | Entry skill | What it should actually return |
| --- | --- | --- |
| A new question or unclear specification | `mathrsi-prepare` | Precise statement, investigated literature and imports, current gaps |
| A fixed question but an uncertain method | `mathrsi-route-loop` | Reviewed and probed route, explicit unproved obligations, first executable tasks |
| A usable route or unfinished proof | `mathrsi-prove` | Actual lemmas, proof, certificate, counterexample, or precise remaining connection |
| Only a formal goal, fixed Lean witness, or existing Lean export | `mathrsi-verify` direct Lean branch | Original-statement alignment, actual definitions/export/build/axioms, accurate reused vs new evidence; no mandatory TeX or paper audit |
| A complete candidate proof or witness | `mathrsi-verify` | Checks in the original scope, actual audit and repairs, verification status |
| Established results needing readable delivery | `mathrsi-handoff` | Proof, reproducibility instructions, wiki and recovery/handoff entry |

For example, a stage-only request can say:

```text
Read /absolute/path/to/math-rsi/base/skills/mathrsi-verify/SKILL.md.
Verify the original theorem in FORMAL_SPEC.md against PROOF.tex in my task
workspace. Execute the applicable proof-checker procedure for this host,
repair concrete gaps while preserving the statement, and write VERIFICATION.md
linking the real audit and evidence. Return the result and remaining obligation;
this request is only for verification, not a new research cycle.
```

For a formal-only request, replace the proof-audit example with:

```text
Read /absolute/path/to/math-rsi/base/skills/mathrsi-verify/SKILL.md.
Check the formal target in FORMAL_SPEC.md using the actual Lean module and
export in my task workspace. Go directly to lean-formalize; use the task
requirements for building and reviewing. Reuse valid existing evidence and
state which commands ran now. Return the exact export, definitions, build
and transitive-axiom evidence, missing conditions, and the next action.
No natural-language paper audit is requested.
```

If both a formal target and a natural-language proof audit are requested, execute each applicable contract and report their scopes separately. The [F4 example](../base/skills/mathrsi-verify/references/lean-target-entry.md) demonstrates static consumption of historical evidence; it is not a new Lean build.

When the main entry delegates a stage, that stage returns to its caller; the caller starts the successor once. A local verification returns to the proof obligation it checked. Literature questions can return to survey without repeating an unchanged investigation. [The workflow map](WORKFLOWS.md) explains these transitions and the actual internal skill calls.

## Connect the reviewers you will use

Choose the review route and its budget before asking for a review-bearing stage. Codex can use a fresh native reviewer when the host provides one; that is same-family evidence and is reported as provisional. External reviewers require the corresponding installed CLI, authentication, and a real MCP service loaded into the host. A Python bridge being present in the clone does not establish model access.

Follow [reviewer installation and invocation](REVIEWER_MCP.md) for the host-specific registration commands, tool parameters, timeouts, first-call and continuation contracts. Register only the services you need, restart or reconnect the host, and inspect its actual tool directory. The guide includes Grok, Antigravity/Gemini, Codex, and Claude-review routes; their continuation APIs differ. Credentials remain in your normal CLI/provider environment, outside the repository and proof files.

Tell the executing agent which available backend/model/effort you intend and let it preserve those settings across subcalls. `base/tools/reviewer_route.py` only resolves configuration; running it does not call a model or complete a review. A reviewer response must be read, its specific concern addressed, and the resulting proof checked. Save the raw response, scope, session identity and actual completion state. A failed service call leaves that review pending while independent mathematical work may continue.

## Try the bounded proof-repair example

For an immediate local replay with no model call or TeX installation:

```bash
cd "$MATHRSI_ROOT"
python3 examples/proof-repair/replay.py
```

It exactly checks a counterexample to the input proof's independence assertion and the rational arithmetic in the repair. To run the agent workflow yourself, copy only the starter into a fresh workspace:

```bash
export TASK_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/mathrsi-proof-repair.XXXXXX")"
cp "$MATHRSI_ROOT/examples/proof-repair/starter/REQUEST.md" "$TASK_ROOT/REQUEST.md"
cp "$MATHRSI_ROOT/examples/proof-repair/starter/PROOF.tex" "$TASK_ROOT/PROOF.tex"
```

Launch your chosen host with access to `TASK_ROOT` as above, then use the natural-language invocation in the [example README](../examples/proof-repair/README.md). Keep the completed `reference/` out of the reviewer input if you want a fresh exercise. Compare your result with the reference after your run; a saved reference audit does not certify a new execution.

The historical trial repaired the proof and obtained same-family/provisional reviews. Its TeX compilation attempts returned **127** because `pdflatex` was missing, so PDF compilation remained pending. No Lean verification or full new-research chain was exercised. The example explains exactly what the replay and trial establish.

## Evolve MathRSI from research experience

For a separate maintenance task, read [`mathrsi-meta-evolve`](../base/skills/mathrsi-meta-evolve/SKILL.md). It improves the existing version from real research evidence, implements scoped base/plugin changes, and uses the changed behavior. It is separate from the five solving stages. Both hosts share this skill: `$mathrsi-meta-evolve` in Codex or `/mathrsi-meta-evolve` in Claude; direct reading works without refreshed discovery.

```text
Read /absolute/path/to/math-rsi/base/skills/mathrsi-meta-evolve/SKILL.md
and execute it on the existing MathRSI version.
Research source and existing evidence: <paths>.
Maintenance goal and allowed files/resources: <scope>.
Resume the current EVOLUTION.md if one exists. Reuse the key source chains,
implement the supported changes, and actually use the affected interfaces.
Keep the original research workspace read-only unless separately authorized.
```

The skill owns the execution sequence; [evolution guidance](EVOLUTION_WORKFLOW.md) explains the inputs and adoption boundary. The current coordinator uses the candidate workflow, with bounded subagent help where useful. A fresh agent running the entire process is not a mandatory prerequisite; required independent mathematical checks still follow the task contract. Existing valid checks are reused.

The bundled original ARIS `meta-optimize` and `meta-apply` also have host-specific aliases. They retain their own contracts and are distinct from the mathematical adaptation; see [ARIS reuse](ARIS_REUSE.md). The [v2 changes](V2_CHANGES.md) preserve DD integration history. The [v3 changes](V3_CHANGES.md) preserve that earlier increment and its actual bounded use. The current [v6 changes](V6_CHANGES.md), [v5 history](V5_CHANGES.md), [v4 history](V4_CHANGES.md) and [maintenance records](../development/README.md) distinguish each release from subsequent main maintenance. Archived outcomes supply mathematical methods, not new-version research performance benchmarks.

## Keep the result usable next time

Keep the precise theorem, full proof and evidence in the task workspace, and update its existing wiki as facts become available. Read back the relevant entity pages: the generated wiki query pack is navigation and may omit a detail needed by the next obligation. Initialize a wiki only when the task genuinely needs one and none exists, following the host's bundled `research-wiki` skill.

At a handoff or interruption, leave a short recovery entry pointing to the original specification, supported results, remaining obligations, actual live work and first useful next action. Record the MathRSI revision used (`git rev-parse HEAD` in the clone), any local changes, and the enabled plugin. Record mathematical proof, arithmetic replay, formal verification, model review and PDF generation in their own actual scopes. A missing rendering dependency need not erase a proved theorem, and a successful rendering command does not prove one.

Workflow improvements belong to a separate authorized maintenance change; see [version evolution](EVOLUTION_WORKFLOW.md). Solving a new task does not resume the archived research projects or modify their historical results.
