# ADR 0005: Thin root in v1.2

Status: Accepted
Baseline: v1.2.0

## Context

The root model is the most capable and the most expensive part of the workflow.
If the root implements the bulk of a change itself, the expensive model is spent
on loop-heavy execution, and the specialist workers become decoration. If the
root delegates everything, the workflow pays coordination cost for work it could
have done in one step, and no one is left holding the objective.

v1.0 and v1.1 drifted toward the first failure: the root re-read files, re-ran
checks, and replayed work that a worker had already completed, which inflated
root turns without improving the result.

## Decision

In v1.2 the root is primarily the objective, decision, coordination, and
integration layer, not a duplicate execution lane.

- Reuse sufficient valid final-state evidence instead of rediscovering facts,
  repeating equivalent checks, or replaying substantial delegated loops, unless
  contradiction resolution, freshness, integration, or another concrete decision
  requires it.
- Prefer specialist execution for substantial loops, and only after delegation
  has been justified by the evidence-first decision.
- Direct root work, narrow integration or triage inspection, cheap decisive
  checks, and necessary independent evidence remain allowed. The rule removes
  duplicated substantial loops, not root judgement.
- Root work is also subject to one active writer per file or tightly coupled
  logical area. "Thin" is a statement about duplicated loops, not a licence for
  the root to write wherever it likes.

## Alternatives considered

- **Root as a pure router** that never touches the repository. Rejected: it makes
  the root unable to integrate, unable to verify a small change cheaply, and
  dependent on a worker for one-line decisions.
- **Root as a second implementer** running in parallel with workers. Rejected: it
  duplicates the most expensive model, and it is the fastest way to produce two
  writers on the same area.
- **Root owns all substantial execution, workers own only verification.**
  Rejected: it inverts the cost model, is the behaviour v1.0 and v1.1 drifted
  into, and gives the most expensive model the least judgement-intensive work.

## Rationale

The root's comparative advantage is deciding and integrating, not typing. Every
root turn should move the objective forward: resolving a contradiction,
integrating results, triaging a finding, or making a decision the workers cannot
make. Repeating a worker's loop does none of those things and costs the most of
any action in the system.

## Evidence / consequences

- Root turn economy is the behaviour this ADR exists to protect. The two
  production-cost cases were run on the v1.2 thin root; the follow-up case
  reached a correct result with no delegated worker and no OpenCode Go traffic at
  all. See [benchmarks/production-cost/](../../benchmarks/production-cost/).
- The rule is written as a preference with explicit exceptions, so integration
  and decision work is never accidentally prohibited along with duplicated
  execution.
- A change that pushes substantial execution back into the root is an
  architecture change and should carry evidence with it, per
  [git-workflow.md](../git-workflow.md).
