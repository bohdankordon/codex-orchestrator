# Delegation and Handoff Contract

Use the relevant parts for safe, bounded assignments. These are information requirements, not mandatory printed headings. Keep optional detail optional; do not assume the child received this reference or the parent conversation.

## Minimum self-contained assignment

Every initial or fresh-worker assignment is self-contained. An established same-thread continuation may use the incremental contract below instead.

Convey, compactly:

- **Mode and task:** the bounded objective and user modality, including analysis/plan/review-only, no changes, implementation-only, or skipped checks as applicable.
- **Authority and constraints:** intended inspect scope, exclusive write ownership or no-write boundary, permitted side effects, and behavior/artifacts that must remain unchanged.
- **Relevant context/state:** why the task matters, the current relevant implementation, and assumptions needed to avoid stale work. Add interfaces, dependent workers, prerequisites, and shared resources only when relevant.
- **Success and return:** observable requirements derived from the user objective; the result/evidence needed, plus changes, uncertainty, blockers, and partial state when applicable.

Name a concrete result rather than a broad responsibility. Separate required behavior from optional improvements. An assignment grants neither overall-objective authority nor permission beyond the user's scope and effective runtime restrictions. Workers do not spawn children without parent authorization and runtime support. Repository-history operations and external publication are not implicitly authorized.

For cross-worker handoffs, pass the bounded objective, acceptance criteria, relevant paths/contracts/state, and material evidence or uncertainty. Do not paste whole transcripts or large research dumps when a compact handoff suffices. For independent Verifier or Reviewer challenge, omit unnecessary implementation rationale and conclusions that could anchor the challenger, but never hide material safety or correctness facts.

## Same-thread continuation and resumption

Prefer runtime follow-up for a live or idle worker when additional work continues the same bounded role, model, logical area, and evidence or investigation thread; its context remains relevant; continuity can be established; fresh independence is unnecessary; and ownership can safely be preserved or re-established. If that worker was closed and the runtime supports persisted resumption, prefer resuming it over spawning a replacement under the same conditions.

Use a fresh worker when independent challenge is material, another role or model is appropriate, prior context or assumptions are materially stale or contaminated, the assignment is a genuinely different logical investigation, safe ownership requires separation, or same-thread continuity cannot be established. Never present a reused Implementer as an independent Verifier or Reviewer. Do not keep an idle worker alive solely in hope of a provider cache hit; caching is an efficiency opportunity, not a correctness premise.

An incremental follow-up states the delta or new objective, changed constraints or state, invalidated assumptions or evidence, and the expected new result where material. It need not replay unchanged context already established in that thread. When continuity or relevant retained context is uncertain, use a normal self-contained assignment.

Context persistence does not imply ownership persistence. A completed or closed worker may retain context while its old write ownership is released. Before a resumed writer mutates, the parent explicitly re-establishes its exclusive write scope, reconciles current state and partial or unrelated changes, refreshes stale assumptions, and establishes that no overlapping writer is active. Until then, resumption grants no write ownership.

## Inspect scope and write ownership

Workers may inspect surrounding code needed to understand dependencies, subject to access constraints. Reading beyond write ownership does not permit mutation. Use explicit files when known; a bounded module or logical area is acceptable when files are not yet known. Logical responsibility never permits collision with another owner.

The parent maintains one active writer per file or tightly coupled logical area, including itself. Before substantial parallel writing, capture relevant status/diff or equivalent starting context, existing user modifications, shared contracts/resources, and ownership. Do not require exhaustive snapshots for ordinary work.

A trivial adjacent edit needs no escalation for a sole writer or clearly preauthorized logical area only if it stays within the objective, has no realistic ownership conflict, and changes no shared contract. During parallel writing, a newly shared or ownership-uncertain file requires parent coordination before mutation.

## Ownership lifecycle and steering

Ownership begins when the parent assigns an area or starts mutating it directly. To release or transfer it:

1. Stop or update the old assignment using actual runtime capabilities.
2. Establish that relevant mutating work has stopped and outstanding commands/delayed writes are no longer expected to complete. A sent message, interruption request, or worker summary alone does not establish this.
3. Inspect and reconcile partial work, preserve unrelated changes, and record unfinished state.
4. Release/reassign only when the current state is known well enough for another writer to proceed safely. If stoppage is uncertain, keep overlapping work unassigned and continue elsewhere where safe.

The parent must acquire/reconcile ownership before making its own integration edits. Never reset, clean, revert, or overwrite unrelated work to simplify handoff.

When the user changes scope or cancels affected work, apply this lifecycle before replacement work: propagate the latest modality, stop/update obsolete assignments, reconcile partial state, and invalidate superseded criteria/evidence. A queued message is not proof the worker has applied new instructions.

## Shared contracts and scope expansion

Identify a single owner for shared changes and establish dependent interfaces before parallel writing where practical. Agreed signatures, schemas, events, persisted formats, and public behavior remain stable until the parent approves a change.

For expansion, send one concise request: needed scope/change, reason, ownership or contract conflict, and whether useful assigned work can continue. The parent may extend ownership, sequence work, make an authorized shared change, assign a separate task, or decline. Continue unaffected work; wait before disputed mutation.

For an approved contract change, identify affected dependencies, update workers, and establish that their assumptions are refreshed before they resume work dependent on it. Reassess evidence based on the old contract.

## Command side effects and shared resources

Mutation includes auto-fixes, formatter write modes, snapshot updates, dependency installation, manifest/lockfile changes, code generation, tracked generated-file updates, fixture rewriting, migrations, destructive database resets, and mutable service state. Permission to execute checks does not authorize all such effects.

Verification/review/debugging assignments do not authorize intentional changes to production code, tracked tests, snapshots, fixtures, tracked generated files, or manifests/lockfiles. Any artifact mutation needs an explicit parent assignment, ownership, and compatible role/runtime permissions; production fixes belong to root or Implementer. A read-only role cannot gain unsupported authority through task wording. An evaluator that authors a change cannot present its checks of that change as independent verification.

Disposable build/test artifacts are allowed where appropriate and supported. Account for unexpected tracked changes without blindly reverting another writer's work. Isolate conflicting test databases, ports, caches, output/generated directories, devices/emulators, and services, or serialize access. Account explicitly for any interaction that remains; disjoint source files alone do not make operations independent.

A Debugger whose discriminating experiment needs unauthorized mutation returns the smallest experiment, expected confirming/falsifying observations, and side effects to the parent. Root or an appropriately permitted role can execute it. Disposable experiments require explicit support in the Debugger's configuration/assignment and runtime; they do not relax its production-source boundary.

## Evidence and partial returns

Return concise results grounded in evidence: changed files/symbols, checks and outcomes, expected versus observed behavior, uncertainty, and remaining work. For meaningful evidence identify the relevant source/dirty state, contracts, dependencies, environment, or external assumptions sufficiently for the parent to assess freshness. See [quality gates](quality-gates.md) for validity and finding semantics; pass needed rules into the assignment rather than assuming the worker read them.

On blockage, interruption, cancellation, or reassignment, account for completed subparts, partially modified files, unverified changes, running processes/outstanding mutations, known problems, evidence, and ownership awaiting release. Include abandoned approaches only when needed to avoid repeating them. If the worker cannot return this information, the parent reconstructs enough from actual state before reassigning.

A worker may report its bounded assignment complete, but only the parent integrates the result and decides whether the user's objective is achieved.
