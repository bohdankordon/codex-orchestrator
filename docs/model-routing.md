# Model routing

Routing is an operational overlay. It answers "which model and effort should run
this already-selected role", never "which role should exist" or "should this be
delegated at all". Role selection happens first and comes from evidence needs.

The authoritative released worker-routing file is
[`orchestrator/references/model-routing.md`](../orchestrator/references/model-routing.md).
The stable v1.2 source remains frozen. Tested alternatives and field-test
profiles are documented separately in [routing-profiles.md](routing-profiles.md).

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

## Tested alternatives

The repository now records multiple routing profiles instead of presenting a
single table as universally optimal:

- **Profile A — v1.2 stable baseline:** Sol High root + Muse mapper.
- **Profile B — validated Muse-root alternative:** Muse xhigh root + the v1.2
  worker mapping.
- **Profile C — field-test candidate:** Muse xhigh root + native Luna max mapper,
  with the remaining worker routes unchanged.

Profile B preserved near-baseline integrated quality and 100/100 on both
production-cost cases. Profile C's Luna mapper scored 99.5/100 in the isolated
Code Mapper challenge versus the frozen Muse mapper baseline at 98.0/100, but a
measured end-to-end Muse-root -> Luna-mapper handoff has not yet occurred because
the root correctly chose direct work in the available smoke tasks.

See [routing-profiles.md](routing-profiles.md) for the exact tables, evidence
status, and local field-test guidance.

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
intended agent type, the model from the selected routing profile, and the matching
reasoning effort explicitly. The root does not infer role mapping from featured
ordering, and does not silently substitute a model when the requested route
fails.

If the default model is unavailable or unsuitable — a provider or data
restriction, a benchmark override, a task-specific constraint — the root decides
the fallback explicitly and discloses any material reduction in independence or
capability. The routing reference lists manual fallback preferences, which are
preferences rather than an automatic proxy chain.

## Independent challenge

Model diversity is a secondary system property and never a reason to ignore task
evidence. With the v1.2 default mapping, production implementation is primarily
DeepSeek, behavioural verification is primarily native Luna, static review is
primarily GLM, and Muse handles high-volume mapping and causal debugging.

Profile C changes that split intentionally: native Luna handles both mapping and
behavioural verification, while Muse handles root orchestration and causal
debugging. This is a field-test routing choice, not a reason to create extra
workers.

When independent challenge materially matters, the root avoids collapsing
implementation and challenge onto the same model or provider family when an
equivalently capable independent route exists. Delegation is never performed
merely to obtain model diversity.

## Replacing the overlay

Benchmark results, new model releases, quota changes, or provider-policy changes
may update routing without touching the five worker contracts. That is the
intended property: routing is replaceable, role semantics are not implicitly
replaceable with it.

The released v1.2 source remains pinned by its release manifest. Experimental or
field-test profiles should be applied as local/runtime overlays until their
integration evidence is sufficient for promotion into a later released baseline.
