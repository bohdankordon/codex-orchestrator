# Model routing

Routing is an operational overlay. It answers "which model and effort should run
this already-selected role", never "which role should exist" or "should this be
delegated at all". Role selection happens first and comes from evidence needs.

The authoritative file is
[`orchestrator/references/model-routing.md`](../orchestrator/references/model-routing.md).

## Validated v1.2 baseline

| Role | Model | Effort |
| --- | --- | --- |
| root | GPT-5.6 Sol (native) | High |
| code-mapper | `opencode-go/muse-spark-1.3-contributor` | xhigh |
| implementer | `opencode-go/deepseek-flash` | max |
| verifier | native `gpt-5.6-luna` | max |
| reviewer | `opencode-go/glm-5.3-flash` | max |
| debugger | `opencode-go/muse-spark-1.3-contributor` | xhigh |

`opencode-go/deepseek-flash` is the canonical routing identifier used by this
baseline. These selections are the ones the v1.2 evidence was produced with.
They are not a claim that any model is objectively the best available.

`gpt-5.6-luna` means the native ChatGPT/Codex model. The OpenCode Go route with
a similar name is a different route and is not a substitute.

## Why worker TOMLs stay model-neutral

The five files in [`agents/`](../agents/) define role boundaries, authority, and
evidence obligations. They deliberately contain no `model` and no
`model_reasoning_effort` field, for three reasons:

- role semantics and provider selection change for different reasons and at
  different rates;
- a model pinned inside a role contract is silently copied into every benchmark
  that reuses that role;
- a routing failure should surface as an explicit routing decision, not as a
  role that quietly changed identity.

`scripts/Test-Repository.ps1` fails if a model or reasoning-effort field appears
in a worker TOML, and CI runs the same check.

## How a worker gets its route

When the root spawns a worker on the current OpenCodex v1 surface it supplies the
intended agent type, the model from the routing table, and the matching reasoning
effort explicitly. The root does not infer role mapping from featured ordering,
and does not silently substitute a model when the requested route fails.

If the default model is unavailable or unsuitable — a provider or data
restriction, a benchmark override, a task-specific constraint — the root decides
the fallback explicitly and discloses any material reduction in independence or
capability. The routing reference lists manual fallback preferences, which are
preferences rather than an automatic proxy chain.

## Independent challenge

Model diversity is a secondary system property and never a reason to ignore task
evidence. With the default mapping, production implementation is primarily
DeepSeek, behavioural verification is primarily native Luna, static review is
primarily GLM, and Muse handles high-volume mapping and causal debugging.

When independent challenge materially matters, the root avoids collapsing
implementation and challenge onto the same model or provider family when an
equivalently capable independent route exists. Delegation is never performed
merely to obtain model diversity.

## Replacing the overlay

Benchmark results, new model releases, quota changes, or provider-policy changes
may update the routing reference without touching the five worker contracts.
That is the intended property: routing is replaceable, role semantics are not
implicitly replaceable with it.
