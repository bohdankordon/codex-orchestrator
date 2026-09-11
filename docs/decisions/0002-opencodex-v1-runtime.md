# ADR 0002: OpenCodex v1 runtime baseline

Status: Accepted
Baseline: v1.2.0

## Context

The workflow runs on the Codex / OpenCodex multi-agent surface. That surface has
versioned behaviour: how a child agent is configured, how roles are selected, how
messages, follow-ups, and interruptions reach a running child, and what isolation
is guaranteed. The acceptance evidence for this baseline was produced on
**multi-agent runtime v1**.

Two facts make the version choice load-bearing rather than cosmetic. First, the
workflow's own contract forbids assuming runtime behaviour: it requires the root
to establish role selection, capacity, messaging, per-child configuration, and
effective permissions from the exposed tools instead of hardcoding them. Second,
evidence is only evidence for the surface it was collected on.

## Decision

Multi-agent runtime **v1** is the accepted baseline for v1.2.0.

- Worker TOMLs stay model-neutral; they contain no model or reasoning-effort
  fields.
- Routing is an overlay: the orchestrator routing reference owns the default
  model and effort per role, and the root supplies the route explicitly when it
  spawns a worker.
- The repository does not silently switch to v2. A v2 migration is a deliberate
  change with its own acceptance evidence, not a packaging detail.

## Alternatives considered

- **Adopt v2 immediately** because it is newer. Rejected: no acceptance evidence
  exists for this workflow on v2, and the v1 results would no longer describe the
  shipped configuration.
- **Support v1 and v2 simultaneously** by documenting both and letting the reader
  choose. Rejected: it doubles the surface the documentation has to be correct
  about and gives no evidence for either.
- **Pin models inside the worker TOMLs** so routing cannot drift. Rejected: it
  couples role semantics to a provider decision, and every routing change would
  become a role change.
- **Hardcode runtime capability assumptions** (isolation, immediate
  cancellation, per-child sandbox) in the skill text. Rejected: the contract
  requires capability to be established at runtime, and wrong assumptions about
  cancellation in particular are unsafe.

## Rationale

The baseline should describe the configuration that was actually measured. v1 is
that configuration. Keeping routing in an overlay rather than in the role files
also means a model change is a small, reviewable, revertible change that does not
invalidate role semantics - and it is the reason the worker files in this
repository can stay identical to the installed production source across a
routing change.

## Evidence / consequences

- Integrated acceptance was run end to end on v1; every spawned role used the
  exact configured route, and silent model substitution was treated as a hard
  failure. See
  [benchmarks/integrated-acceptance/](../../benchmarks/integrated-acceptance/).
- Production-cost measurements were collected on v1 with the routing table in
  [model-routing.md](../model-routing.md).
- A future v2 adoption must repeat integrated acceptance on v2 before the
  baseline version in [BASELINE.md](../../BASELINE.md) changes.
- Because routing is an overlay, `opencode-go/*` routes are supplied at spawn
  time and remain replaceable without touching any role file.
