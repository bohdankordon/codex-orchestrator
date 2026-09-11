# Codex Orchestrator

An adaptive multi-agent engineering workflow for Codex and OpenCodex. It pairs a
thin root orchestrator with five specialist worker roles, and it decides how much
delegation a given task actually needs instead of running a fixed pipeline.

Current stable release: **v1.2.0**

This is an independent community project. It is not affiliated with or endorsed
by OpenAI, OpenCode, OpenCodex, or the model providers referenced in its routing
documentation.

## Why this exists

A strong root model is the most reliable part of a multi-agent system and the
most expensive part of it. The failure modes are symmetrical: a workflow that
delegates everything burns quota on work the root could have finished directly,
and a workflow that delegates nothing gives up independent verification, context
isolation, and specialist depth.

This project treats the delegation decision as a cost/benefit decision that
belongs to the root agent and should be made per task:

- capable root models are valuable but expensive;
- fixed pipelines spend work on tasks that do not need them;
- choosing evidence needs first keeps the team as small as the task allows;
- specialists still pay off when they isolate context, add independent
  verification, or distribute load across model tiers and providers.

No universal superiority is claimed. This is a discipline for spending effort
where it changes the outcome.

## Architecture

```
Root / Orchestrator   objective, scope, decisions, integration, completion
  |
  +-- Code Mapper     read-only mapping of paths, ownership, state flow
  +-- Implementer     bounded implementation under exclusive write ownership
  +-- Verifier        independent behavioural evidence, PASS/FAIL/UNVERIFIED
  +-- Reviewer        read-only inspection of material risk
  +-- Debugger        causal investigation of an observed failure
```

These are available roles, not a sequence. A task may use none of them, one of
them, or several. No role and no ordering is mandatory.

The canonical principle:

> Select evidence obligations first, then decide who should obtain them.

Two invariants carry most of the safety:

- **One active writer per file or tightly coupled logical area**, including the
  root. Ownership is released only after mutating work has demonstrably stopped
  and partial state has been reconciled; a cancellation message alone does not
  establish that.
- **Reuse before respawn.** An existing worker thread is continued only while the
  role, model, logical area, and evidence thread still match and independence and
  ownership permit it. A fresh worker is preferred whenever independence
  materially matters, and never abandoned in order to chase a provider cache hit.

Root stays the objective, decision, coordination, and integration layer. Direct
root work is allowed and is often the cheapest correct answer for a small,
well-understood task.

## Routing profiles

The released v1.2 baseline remains stable:

| Role | Model | Effort |
| --- | --- | --- |
| root | GPT-5.6 Sol (native) | High |
| code-mapper | `opencode-go/muse-spark-1.3-contributor` | xhigh |
| implementer | `opencode-go/deepseek-flash` | max |
| verifier | native `gpt-5.6-luna` | max |
| reviewer | `opencode-go/glm-5.3-flash` | max |
| debugger | `opencode-go/muse-spark-1.3-contributor` | xhigh |

The repository also documents two tested alternatives:

- **Muse-root profile:** Muse Spark 1.3 Contributor xhigh as root, with the v1.2
  worker routing unchanged.
- **Muse + Luna Mapper field-test profile:** Muse xhigh as root and native Luna
  max as Code Mapper, with DeepSeek implementation, Luna verification, GLM
  review, and Muse debugging unchanged.

The Muse-root challenge scored 96.8/100 against the historical Sol baseline at
97.2/100 with no hard failures, and both production-cost cases retained 100/100.
The isolated Luna Code Mapper challenge scored 99.5/100 against the frozen Muse
mapper baseline at 98.0/100 with no hard-boundary failures. The specific
Muse-root -> Luna-mapper handoff remains a field-test edge because the root
correctly chose direct work in the measured integration smoke task.

The worker TOMLs in `agents/` contain no model or reasoning-effort fields. They
are model-neutral role contracts, and routing is maintained separately. Changing
a model is an overlay change, not a role change.

See [docs/model-routing.md](docs/model-routing.md) for routing semantics and
[docs/routing-profiles.md](docs/routing-profiles.md) for exact profile tables,
evidence status, and local field-test guidance.

## Example adaptive behaviour

Complex or risky change, where the relevant path is not yet understood and
independent challenge matters:

```
Code Mapper -> Implementer -> independent Verifier -> root integrates
```

Small, local, well-understood change, where delegation would add coordination
cost without improving confidence:

```
root inspects -> root fixes -> targeted check -> done
```

Both are legitimate outcomes of the same workflow. They are examples, not
pipelines: a task may mix them, stop early, or skip a role the evidence does not
require.

## Planner integration

Product and architecture planning can happen in ChatGPT or another external
planner. When implementation is handed to Codex, provide the objective,
established context, constraints, and acceptance criteria, then begin with
`Use $orchestrator.` Do not preselect workers or prescribe a delegation
pipeline: repository execution planning belongs to the orchestrator.

See [docs/planner-integration.md](docs/planner-integration.md) for fresh-thread
and continuation handoffs, examples, and a copy-paste migration instruction for
an existing planning chat.

## Validation

| Case | Score | Sol requests | Native 5h delta |
| --- | --- | ---: | ---: |
| Auth refresh-token rotation | 100/100 | 20 | +5 pp |
| Stale persisted event fixture | 100/100 | 8 | +2 pp |

Integrated runtime acceptance across five cases: accepted, average 97.2/100, no
hard failures.

The second case is published precisely because it used no delegated worker at
all. The direct-root path was the correct answer there, and the benchmark scores
that as a pass rather than a missed opportunity.

Quota deltas are observations from one environment and one account pool, not a
general cost model. The case definitions and deterministic evaluators are
published and can be run locally; the account/quota collector behind the cost
figures is not, so those figures are historical evidence rather than something a
new user can regenerate end to end. See [benchmarks/](benchmarks/) for what each
evidence layer can and cannot show.

## Installation

Windows, PowerShell 5.1 or later:

```powershell
.\scripts\Install-Orchestrator.ps1 -WhatIf   # preview
.\scripts\Install-Orchestrator.ps1           # install
```

Directory layout, routing prerequisites, and verification commands:
[docs/installation.md](docs/installation.md).

## Development

`main` holds the latest accepted baseline. Meaningful changes go through a
short-lived branch and a pull request, CI must pass, and the change lands as a
single squash commit. Changes that affect delegation, ownership, or routing
should carry their evidence or a benchmark note with them.

Details: [docs/git-workflow.md](docs/git-workflow.md) and [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE). Design lineage and the third-party text comparison
behind it are recorded in [NOTICE.md](NOTICE.md).
