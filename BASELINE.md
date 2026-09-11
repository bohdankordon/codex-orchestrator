# Baseline

Source of truth for the accepted production baseline.

- **Version:** v1.2.0
- **Status:** Production Accepted
- **OpenCodex multi-agent runtime:** v1
- **Worker roles:** five, all permanent

## Routing

| Role | Model | Effort |
| --- | --- | --- |
| root | GPT-5.6 Sol (native) | High |
| code-mapper | `opencode-go/muse-spark-1.3-contributor` | xhigh |
| implementer | `opencode-go/deepseek-flash` | max |
| verifier | native `gpt-5.6-luna` | max |
| reviewer | `opencode-go/glm-5.3-flash` | max |
| debugger | `opencode-go/muse-spark-1.3-contributor` | xhigh |

Worker TOMLs stay model-neutral. Routing is an operational overlay held in
`orchestrator/references/model-routing.md`.

## Core principles

1. Delegation has a cost. Use the smallest amount of delegation that materially
   improves correctness, confidence and evidence quality, useful parallelism,
   context isolation, specialist depth, risk reduction, or efficiency.
2. Select evidence obligations first, then decide who should obtain them.
3. Maintain one active writer per file or tightly coupled logical area, including
   the root.
4. Release or transfer ownership only after mutating work and outstanding
   operations have stopped and partial state has been reconciled. A cancellation
   message does not prove mutation stopped.
5. Prefer same-thread reuse only while role, model, logical area, and evidence
   thread still match and independence and ownership permit it. Prefer a fresh
   worker when independence materially matters.
6. Root is primarily the objective, decision, coordination, and integration
   layer, not a duplicate execution lane. Direct root work remains allowed and is
   often cheaper for small tasks.

## Validated behaviours

- **Adaptive delegation** — the team size follows the evidence need; a correct
  direct-root solution and a correct delegated solution are both acceptable.
- **Direct-root economy** — small, well-understood work is cheapest when the root
  does it. Measured case 02 is the reference example.
- **Same-thread reuse** — genuine continuations of the same role, model, logical
  area, and evidence thread reuse the established worker instead of respawning.
- **Ownership safety** — one writer per area, reconcile-before-reassign, and no
  history or worktree mutation used to simplify a handoff.
- **Independent verification** — behavioural claims can be challenged separately
  from the agent that produced them, with PASS / FAIL / UNVERIFIED kept honest.
- **Thin-root behaviour** — root decides and integrates rather than replaying
  substantial specialist loops that already produced valid evidence.

## Known limitations and caveats

- Native ChatGPT quota is the primary constrained resource in the measured
  workflows; not every task benefits equally from the delegation the workflow
  allows.
- Upstream does not expose exact per-model ChatGPT quota percentage cost. Sol and
  Luna share one physical account pool, so percentage attribution between them is
  not separable, even though request, token, and cache figures are exact.
- Runtime telemetry does not currently provide a proven agent-id mapping for all
  requests. Per-role traffic is therefore never claimed as measured fact; the
  published accounting is model level.
- Benchmark figures are controlled observations from one environment. They are
  not universal cost guarantees, and raw input must not be conflated with
  uncached input when reasoning about cost.
- The published case definitions and deterministic evaluators can be run
  locally. The account/quota telemetry collector used for the original cost
  measurements is intentionally not published, because it was specific to one
  environment and one account pool; reproducing cost telemetry requires a
  compatible measurement method of your own.
- Routing selections are the validated v1.2 baseline, not a claim that any model
  is objectively best. See [docs/model-routing.md](docs/model-routing.md).
