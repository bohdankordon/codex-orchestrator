# ADR 0004: Reuse before respawn

Status: Accepted
Baseline: v1.2.0

## Context

Once a worker has run, the root can either continue that worker thread or spawn a
fresh one. Continuation is cheaper: the worker already holds relevant context and
its provider-side cache is warm. Fresh workers are safer in a different
dimension: a worker that has already reasoned about a change, or has already
reported a conclusion, is a weaker source of independent challenge than a worker
that has not.

The unsafe version of this trade is to reuse aggressively for cache locality and
then present the reused worker's agreement as independent verification. The
expensive version is to spawn fresh workers for everything and pay full context
reconstruction on each follow-up. Ownership adds a third constraint: only one
writer may hold a file or tightly coupled logical area at a time.

## Decision

Reuse a worker thread only when all four of these still match: **role, model,
logical area, and evidence thread**. Even then, reuse is permitted only when
independence and ownership requirements allow it.

- When independence materially matters, prefer a fresh worker.
- Never trade independence or ownership safety for reuse, and never assume a
  provider cache hit.
- If a thread is reused, the follow-up may be incremental instead of
  self-contained. A fresh assignment must always be self-contained: modality,
  bounded objective, inspect/write authority, constraints, relevant context,
  success and evidence criteria, and expected return.
- Ownership is released or transferred only after relevant mutating work and
  outstanding operations have stopped, partial changes are reconciled, and the
  current state supports safe reassignment. A cancellation message alone does not
  establish that.

The full criteria live in the
[handoff contract](../../orchestrator/references/handoff-contract.md).

## Alternatives considered

- **Always reuse** the existing thread to minimise tokens. Rejected: it silently
  converts verification into self-confirmation and risks two writers holding the
  same area.
- **Always spawn fresh** to maximise independence. Rejected: independence is
  worth paying for only when it changes the outcome. A bounded follow-up to the
  same worker in the same logical area is usually the cheapest correct option.
- **Keep a long-lived worker per role** and route all work of that kind to it.
  Rejected: it accumulates context the current task does not need and makes the
  worker's conclusions sticky across unrelated tasks.
- **Infer reuse eligibility from elapsed time or agent count.** Rejected:
  eligibility follows role, model, logical area, evidence thread, independence,
  and ownership, not the clock.

## Rationale

Independence and ownership are invariants; context reuse is an optimisation. If
the invariants are stated first, the optimisation applies only where it cannot
damage them. Tying reuse to role, model, logical area, and evidence thread keeps
the decision mechanical enough to make quickly and specific enough to be
reviewable.

## Evidence / consequences

- Integrated acceptance records seven valid spawn records across five cases,
  with independent challenge preserved where the case required it and same-thread
  work used where it did not.
- A cancellation that has not been confirmed does not release ownership. This is
  the rule that prevents a resumed writer from colliding with a worker that was
  believed to be stopped.
- The reuse decision is per thread and per follow-up. Continuation never carries
  a previous conclusion forward as evidence for a changed final state.
