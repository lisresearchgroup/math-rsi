# MathRSI documentation

[English entry](../README.md) · [中文入口](../README.zh-CN.md) · [Visual tour](HOMEPAGE.md) · [Six research cases](../case-studies/README.md)

Choose the path that matches your task. The entry pages and quick start are bilingual or English; many detailed workflow and domain references are in Chinese.

| Your purpose | Read next |
| --- | --- |
| Try MathRSI and start a task | [Quick start](QUICKSTART.md) · [Runnable proof-repair example](../examples/proof-repair/README.md) |
| Understand the mathematics and evidence | [Six-case index](../case-studies/README.md) · [Public visual tour](https://lisresearchgroup.github.io/math-rsi/) · [Local viewing](HOMEPAGE.md) |
| Continue a research workspace | [Five workflows and return paths](WORKFLOWS.md) · [Workspace, wiki and recovery](WORKSPACE.md) |
| Choose domain methods | [Six-domain routing](DOMAIN_ROUTING.md) · [Plugin contract](PLUGIN_CONTRACT.md) |
| Connect external reviewers or use bundled ARIS | [Reviewer MCP](REVIEWER_MCP.md) · [ARIS reuse and dual-host layout](ARIS_REUSE.md) |
| Understand or maintain a version | [v8 release notes](V8_CHANGES.md) · [v7 changes](V7_CHANGES.md) · [v6 changes](V6_CHANGES.md) · [v5 history](V5_CHANGES.md) · [v4 history](V4_CHANGES.md) · [Evolution workflow](EVOLUTION_WORKFLOW.md) · [Implementation history](../development/README.md) |
| Inspect validation and attribution | [Validation records](../development/README.md#validation-and-implementation) · [Skill acceptance](SKILL_ACCEPTANCE.md) · [Provenance](PROVENANCE.md) |
| Contribute skills, plugins or verifiers | [Contributing guide](../CONTRIBUTING.md) · [中文贡献指南](../CONTRIBUTING.zh-CN.md) · [Plugin contract](PLUGIN_CONTRACT.md) · [Skill acceptance](SKILL_ACCEPTANCE.md) |

## Repository map

| Location | What lives here |
| --- | --- |
| [`base/skills/`](../base/skills/) | Ten MathRSI entry skills, bundled ARIS Claude skills and their resources. The five solving stages share one orchestrator; maintenance is separate. |
| [`base/skills/skills-codex/`](../base/skills/skills-codex/) | The Codex implementation of the bundled ARIS skills. |
| [`base/tools/`](../base/tools/) | Bundled helpers; set `ARIS_REPO` to this clone's `base`. |
| [`plugins/`](../plugins/) | Six domains and fourteen direct domain skills, mathematical references, failure knowledge and executable checkers. |
| [`case-studies/`](../case-studies/) | One overview of all six research threads, with existing case readers and links into plugin evidence. |
| [`examples/`](../examples/) | A bounded proof-repair exercise and reference output. |
| [`mcp-servers/`](../mcp-servers/) | Four reviewer bridge implementations; selected CLIs and authentication are external dependencies. |
| [`figures/mathrsi/`](../figures/mathrsi/README.md) | Editable architecture, GPT Image alternative, source instructions and historical diagrams. |
| [`development/`](../development/README.md) | Version implementation, maintenance, review and validation records. The current homepage source remains under this directory. |
| Your task directory | Original specification, active research wiki, proofs, certificates, verification and resumption notes. [Workspace guide](WORKSPACE.md) |

Project discovery aliases under `.agents/skills/` and `.claude/skills/` point to the repository's skills. They do not install model services. Archives preserve historical evidence; new research writes its own task workspace.

## Versions

**[MathRSI v8](https://github.com/lisresearchgroup/math-rsi/releases/tag/v8)** is the latest release. [Changes and provenance](V8_CHANGES.md) · [v8 ZIP](https://github.com/lisresearchgroup/math-rsi/archive/refs/tags/v8.zip) · [main ZIP](https://github.com/lisresearchgroup/math-rsi/archive/refs/heads/main.zip). Record the exact revision in a research handoff.

[Public Pages build and publication scope](PAGES.md) explains the allowlist, workflow and local preview.
