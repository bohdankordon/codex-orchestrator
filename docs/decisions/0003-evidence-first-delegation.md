# ADR 0003: Evidence-first delegation

Status: Accepted
Baseline: v1.2.0

## Context

Multi-agent workflows fail in two directions. Delegating everything spends
quota, latency, and coordination effort on tasks the root could have finished
directly, and it produces the illusion of rigour by counting agents instead of
evidence. Delegating nothing gives up independent challenge, context isolation,
and the specialist depth that a second model with a different framing provides.

The usual fixes are both wrong. A fixed pipeline decides delegation before the
task is understood. A cost rule that always picks the cheapest available model
decides it without reference to correctness or risk.

## Decision

Delegation is decided per task, in this order:

> Select evidence obligations first, then decide who should obtain them.

Concretely, the root establishes the requested outcome, the remaining
uncertainty, the evidence the completion decision needs, the evidence that
already exists and is still valid, and the unresolved material risk. Only then
does it choose who can resolve the next need reliably at reasonable cost.

Two supporting rules make the decision honest:

- **An agent call is not itself a quality gate.** Spawning a worker is not
  evidence, and using a role name does not mean the role ran.
- **The smallest useful team wins.** Delegation must materially improve
  correctness, evidence quality, context isolation, useful parallelism,
  specialist depth, risk reduction, or efficiency. If it does not, the root does
  the work directly.

The invariant that states the same rule as a constraint is kept verbatim in the
production source and in [BASELINE.md](../../BASELINE.md):

> Delegation has a cost. Use the smallest amount of delegation that materially
> improves correctness, confidence/evidence quality, useful parallelism, context
> isolation, specialist depth, risk reduction, or efficiency.

## Alternatives considered

- **Role-first delegation** ("this is a behavioural change, so spawn a
  verifier"). Rejected: it decides the answer before asking what evidence is
  missing, and it makes verification ceremonial on tasks whose risk is elsewhere.
- **Always delegate to the cheapest capable model.** Rejected: cost is one input
  to the decision, not the decision. Cheap work that produces no usable evidence
  is expensive.
- **Always work directly and delegate only on request.** Rejected: it forfeits
  independent verification exactly where independent verification has the most
  value.
- **Treat the pipeline as the discipline.** Rejected as a hard failure in
  acceptance scoring, because it converts a judgement into a ritual.

## Rationale

Choosing obligations first makes both failure modes visible. If no obligation
requires a second party, the correct action is visible as zero delegation. If an
obligation requires independence, the correct action is visible as a worker that
is genuinely independent of the implementer. Cost then enters as a tiebreaker
between options that all satisfy the obligation, which is the only place where it
belongs.

## Evidence / consequences

- The integrated acceptance layer scores the delegation decision and role
  selection at 30 of 100, the single largest bucket, and treats a mandatory
  pipeline as a hard failure.
- Case 02 of the production-cost benchmark is the direct-root path, solved with
  no delegated worker and no provider-hosted worker traffic at all; Case 01
  exercised the auth refresh-token rotation path with delegated workers. Both
  scored 100/100. Those results are published as evidence that adaptivity is
  the behaviour under test, not a slogan.
- The decision is re-made per task. A previous task's delegation shape is not
  evidence for this task's delegation shape.
