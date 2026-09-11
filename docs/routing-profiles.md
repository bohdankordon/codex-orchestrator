# Routing profiles

The orchestrator roles are model-neutral. A routing profile chooses the root model and the model/effort used for each already-selected worker role; it does not change role authority or require any worker to be spawned.

These profiles preserve the core rule: select evidence obligations first, then decide who should obtain them.

## Profile A — v1.2 stable baseline

Status: **stable / released in v1.2.0**.

| Role | Model | Effort |
| --- | --- | --- |
| root | GPT-5.6 Sol (native) | High |
| code-mapper | `opencode-go/muse-spark-1.3-contributor` | xhigh |
| implementer | `opencode-go/deepseek-flash` | max |
| verifier | native `gpt-5.6-luna` | max |
| reviewer | `opencode-go/glm-5.3-flash` | max |
| debugger | `opencode-go/muse-spark-1.3-contributor` | xhigh |

This is the frozen v1.2 routing used for the published acceptance and production-cost evidence.

## Profile B — Muse root with v1.2 workers

Status: **validated alternative root; not the v1.2 default**.

| Role | Model | Effort |
| --- | --- | --- |
| root | `opencode-go/muse-spark-1.3-contributor` | xhigh |
| code-mapper | `opencode-go/muse-spark-1.3-contributor` | xhigh |
| implementer | `opencode-go/deepseek-flash` | max |
| verifier | native `gpt-5.6-luna` | max |
| reviewer | `opencode-go/glm-5.3-flash` | max |
| debugger | `opencode-go/muse-spark-1.3-contributor` | xhigh |

Observed evidence:

- integrated acceptance: 96.8/100 versus the historical Sol baseline at 97.2/100, with no hard failures;
- both production-cost cases preserved 100/100 quality;
- the production-cost runs selected direct-root execution and did not invoke workers.

This profile is useful when the objective is to move root traffic from the native account pool to OpenCode Go while keeping the v1.2 worker mapping unchanged.

## Profile C — Muse root + native Luna mapper

Status: **field-test candidate**.

| Role | Model | Effort |
| --- | --- | --- |
| root | `opencode-go/muse-spark-1.3-contributor` | xhigh |
| code-mapper | native `gpt-5.6-luna` | max |
| implementer | `opencode-go/deepseek-flash` | max |
| verifier | native `gpt-5.6-luna` | max |
| reviewer | `opencode-go/glm-5.3-flash` | max |
| debugger | `opencode-go/muse-spark-1.3-contributor` | xhigh |

Observed evidence:

- isolated Code Mapper challenge: Luna 99.5/100 versus the frozen Muse baseline at 98.0/100, with no hard-boundary failures;
- the same two production-cost cases preserved 100/100 quality with Muse as root;
- neither production-cost case needed a mapper, so adding the Luna route did not cause gratuitous native delegation;
- a final engineering smoke passed, but the root again chose valid direct work, so the end-to-end Muse root -> Luna Code Mapper handoff remains unobserved.

Use this profile for real-task field testing. Its components are individually validated, but the specific Muse-to-Luna mapper integration edge has not yet been exercised in a measured end-to-end task.

## Choosing a profile

Use Profile A when you want the released, frozen baseline and the strongest continuity with v1.2 evidence.

Use Profile B when you want the validated Muse-root economy experiment without changing any worker mapping.

Use Profile C when you want to field-test the new split: Muse handles root orchestration and causal debugging, while native Luna handles code mapping and behavioural verification.

Do not choose a profile solely to force usage of a particular provider. A worker should still be spawned only when delegation materially improves correctness, confidence, evidence quality, useful parallelism, context isolation, specialist depth, risk reduction, or efficiency.

## Applying a profile

The root model is selected for the root session. Worker routing is an overlay; worker TOMLs remain unchanged.

For a local experiment, keep the repository's released v1.2 source intact and override the installed routing reference or pass the intended model/effort explicitly when the runtime supports it. Do not add model fields to worker TOMLs.

The installed routing reference normally lives at:

```text
%USERPROFILE%\.agents\skills\orchestrator\references\model-routing.md
```

For Profile C the only worker-route change from v1.2 is:

```text
code-mapper -> native gpt-5.6-luna / max
```

The root session changes separately from native Sol High to `opencode-go/muse-spark-1.3-contributor` at `xhigh`.

After field testing, record whether `code-mapper` was actually spawned and, if so, confirm the runtime identity, read-only boundary, handoff quality, and root consumption of its evidence before promoting Profile C to a stable default.
