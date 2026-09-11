# Architecture

This document describes the v1.2 workflow as implemented by the files in this
repository. Root behaviour is defined by [`orchestrator/SKILL.md`](../orchestrator/SKILL.md);
worker behaviour is defined by the five contracts in [`agents/`](../agents/);
the detailed rules live in [`orchestrator/references/`](../orchestrator/references/).

## Root authority

The root orchestrator owns the user objective, scope and requirements,
decomposition, delegation, priorities, dependencies, write ownership,
integration, finding triage, verification and review strategy, blockers, and the
final completion decision. The root contract activates only for an explicitly
invoked task; invocation does not create a persistent objective or authorise
unrelated actions.

Workers return bounded work and evidence. They do not own the overall objective
or its lifecycle, and a worker completing its assignment is not by itself
evidence that the user's objective is achieved.

## Worker contracts

| Role | Purpose | Authority | Refuses |
| --- | --- | --- | --- |
| `code-mapper` | Map uncertain execution paths, ownership, state flow, dependencies, and blast radius | Inspect only | Implementation, general review, project decomposition |
| `implementer` | Bounded implementation with lightweight first-party checks | Edit within assigned ownership | Unassigned areas, unapproved shared-contract changes |
| `verifier` | Independent behavioural evidence for assigned claims | Execute and inspect; report PASS/FAIL/UNVERIFIED | Fixing the implementation it evaluates |
| `reviewer` | Independent inspection of material risk | Inspect only; report with impact and confidence | Fixing its own findings, deciding completion |
| `debugger` | Causal investigation of an observed failure | Investigate, reproduce, run bounded permitted probes | Production fixes, unrelated review findings |

Each contract is self-contained: an assignment supplies modality, a bounded
objective, inspect and write authority, constraints, relevant context, success
criteria, and the expected return. Beyond an established same-thread
continuation, no worker is entitled to assume it inherited earlier conversation.

All five contracts are model-neutral. They contain no model or reasoning-effort
fields, which keeps role semantics and routing separable.

## The delegation decision

The order of operations is fixed by the root contract:

1. Establish the requested outcome and acceptance criteria.
2. Identify remaining uncertainty, required evidence, and existing valid evidence.
3. Identify unresolved material risk.
4. Only then choose who can resolve the next need reliably at a reasonable cost.

An agent call is not itself a quality gate. Task size neither requires nor forbids
delegation; the size of the expected improvement does. Direct root work is the
correct answer whenever delegation would not materially improve correctness,
evidence quality, context isolation, useful parallelism, specialist depth, risk
reduction, or efficiency.

## Ownership lifecycle

Ownership begins when the root assigns an area or starts mutating it directly,
and there is one active writer per file or tightly coupled logical area at all
times. Release or transfer requires all four steps:

1. Stop or update the old assignment using actual runtime capabilities.
2. Establish that relevant mutating work and outstanding commands or delayed
   writes have stopped.
3. Inspect and reconcile partial work, preserving unrelated changes, and record
   unfinished state.
4. Release or reassign only when the current state is known well enough for
   another writer to proceed safely.

Command side effects count as writes: formatter write modes, dependency
installation, snapshot updates, code generation, fixture rewriting, and
migrations all mutate. Permission to run checks is not permission to mutate.

## Cancellation semantics

Sending a cancellation, interruption request, or steering message does not
establish that mutation stopped. A queued message is not proof that a worker has
applied new instructions. Until stoppage is established, overlapping work stays
unassigned and the root continues elsewhere where that is safe.

## Continuation and resume semantics

An established worker thread is the preferred target for more work when all of
the following hold: the bounded role is unchanged, the model is unchanged, the
logical area is unchanged, the evidence or investigation thread is unchanged,
its context is still relevant, continuity can be established, fresh independence
is unnecessary, and ownership can safely be preserved or re-established.

If that worker was closed and the runtime supports persisted resumption, resuming
it is preferred to spawning a replacement under the same conditions.

Continuation grants context, never ownership. Before a resumed writer mutates,
the root re-establishes its exclusive write scope, reconciles current and partial
state, refreshes stale assumptions, and confirms that no overlapping writer is
active. An incremental follow-up states the delta, changed constraints, and
invalidated assumptions; it does not replay unchanged context.

## Fresh-worker independence

A fresh worker is required when independent challenge is material, a different
role or model is appropriate, prior context is stale or contaminated, the
investigation is genuinely different, safe ownership requires separation, or
same-thread continuity cannot be established.

A new agent, a different model, or a fresh context does not establish
independence by itself. A reused Implementer is never presented as an
independent Verifier or Reviewer. A Verifier that fixes what it evaluates
forfeits that independence and must disclose it.

## Direct root path

The root is an objective, decision, coordination, and integration layer rather
than a duplicate execution lane. That is a preference about substantial
specialist loops, not a prohibition: direct root work, narrow integration or
triage inspection, cheap decisive checks, and necessary independent evidence all
remain allowed. When root work itself becomes the implementation under
examination, its own checks are first-party evidence and are labelled that way.

## Evidence states

Each material claim or check carries one of three states:

| State | Meaning |
| --- | --- |
| `PASS` | The claim was demonstrated on the relevant final state. |
| `FAIL` | Observed behaviour contradicts the claim. |
| `UNVERIFIED` | Evidence was skipped, unavailable, inconclusive, or not gathered. |

Absent evidence is never converted into `PASS`, and an environment failure is
never converted into a behavioural `FAIL`. Evidence is valid for a scope and a
basis, not forever: `HEAD` alone does not identify a dirty worktree, and after
changes only materially affected evidence is invalidated, with the narrowest
sufficient recheck.

Findings are triaged with impact, confidence, and disposition kept separate. The
dispositions are `FIX NOW`, `DEFER / REPORT`, `DISMISS`, and temporarily
`INVESTIGATE`. Findings are not manufactured from style preferences or
unrelated pre-existing issues.

## Why completion stays with root

Only the root integrates results and decides whether the objective is achieved,
because only the root holds the objective, the acceptance criteria, the current
valid evidence, the finding dispositions, the ownership record, and the
constraints the user attached. Workers decide bounded questions; a worker
decision about its own slice cannot establish the user's outcome.

The completion outcomes are `ACHIEVED`, `PARTIAL`, `BLOCKED`, and
`UNVERIFIED`, and they are one decision rather than another automatic test suite
or agent call. Integration is part of that decision: individual worker success
does not establish that combined behaviour satisfies shared contracts, data
flow, startup, compatibility, or end-to-end requirements.

## Reference map

| File | Governs |
| --- | --- |
| `orchestrator/SKILL.md` | Root authority, delegation decision, ownership, evidence, completion |
| `orchestrator/references/handoff-contract.md` | Assignment contents, ownership lifecycle, continuation, command side effects |
| `orchestrator/references/quality-gates.md` | Risk bands, evidence validity, independent challenge, findings, failure attribution |
| `orchestrator/references/workflow-patterns.md` | Illustrative adaptations; explicitly not pipelines |
| `orchestrator/references/model-routing.md` | Operational model and effort preferences (replaceable overlay) |
