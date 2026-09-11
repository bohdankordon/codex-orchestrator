# ADR 0001: Five-role roster

Status: Accepted
Baseline: v1.2.0

## Context

The workflow needs a set of specialist roles it can select from. Early internal
iteration tried narrower roles, language-specific roles, and a generalist worker.
Both directions fail in predictable ways. A large roster makes role selection
itself a source of error, because several roles can claim the same work while
their authority boundaries overlap. A single generalist worker removes the
selection problem by removing the specialists, which also removes independent
verification and the separation between reading, writing, diagnosing, and
inspecting.

What the workflow actually needs is a small set of roles that are distinguishable
by the evidence they can produce and by what they are not allowed to do.

## Decision

Exactly five permanent worker roles, each with one reason to exist and one
authority boundary:

| Role | Reason to use | Authority |
| --- | --- | --- |
| `code-mapper` | Read-only mapping of execution paths, ownership, state flow, dependencies, side effects, blast radius | read-only |
| `implementer` | Bounded implementation under exclusive write ownership, with lightweight first-party checks | writes the assigned scope |
| `verifier` | Independent behavioural evidence, reported separately from implementation | reports; does not fix |
| `reviewer` | Read-only independent inspection of material risk that execution evidence can miss | reports; does not fix |
| `debugger` | Evidence-driven causal investigation while the cause is still uncertain | investigates; does not implement the fix |

The roster is a toolbox. No role is mandatory, no ordering is mandatory, and a
task may use none of them.

## Alternatives considered

- **A larger roster** with per-language, per-framework, or per-domain
  specialists. Rejected: it shifts cost from execution to selection, and
  overlapping authority is how double writers appear.
- **A single generalist worker.** Rejected: one worker cannot be independent of
  itself, and it collapses read-only investigation into write-authorised
  execution.
- **A fixed pipeline** of mapper, implementer, verifier. Rejected explicitly as
  a hard failure in acceptance scoring: it spends work on tasks that do not need
  it and hides the delegation decision instead of making it.
- **Merging reviewer into verifier**, or **debugger into implementer**. Rejected:
  both merges combine a non-writing role with a writing one, which is exactly
  the separation that keeps findings honest.

## Rationale

Each role answers a question the others cannot answer as cheaply or as honestly.
The mapper removes uncertainty before anyone writes; the implementer is the only
production writer; the verifier is independent of the implementation; the
reviewer covers risk that passing tests do not cover; the debugger establishes
cause before a fix is attempted. Five is the smallest count that keeps those
questions separate, and the largest count that stays selectable without
ambiguity.

## Evidence / consequences

- Each of the five roles was exercised in both cases of the role-selection
  benchmark, so the mapping is backed by observed behaviour rather than design
  intent.
- Role boundaries are enforced in the acceptance layer: unauthorized mutation by
  a verifier, reviewer, or debugger is a hard failure.
- Adding a sixth role now requires evidence that an existing role cannot cover
  the same obligation, because the cost of a wrong selection grows with the
  roster.
- Roles depend on runtime availability. If a role is unavailable, the root works
  directly or uses a safely scoped worker and discloses the loss of
  independence, rather than renaming a task and claiming the role ran.
See [architecture.md](../architecture.md) and
[0003-evidence-first-delegation.md](0003-evidence-first-delegation.md).
