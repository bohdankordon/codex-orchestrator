# Adaptive Workflow Examples

These are illustrations, not pipelines or required team sizes. Shorten, combine, or adapt them using the root skill, [handoff contract](handoff-contract.md), and [evidence questions](quality-gates.md). Choose evidence needs before assigning roles.

## Known change, direct or delegated

For an obvious label correction, root inspects, edits, and performs a cheap check. For a well-understood behavioral fix, root or Implementer makes the owned change and obtains targeted evidence. Delegate only a concrete need; neither size nor the word "bug" forces a Mapper, Debugger, or Verifier. Add independent challenge when consequences and remaining uncertainty justify it.

## Unclear reconnect failure

Map ownership only if unclear. Root or Debugger ranks plausible causes and selects discriminating observations. Parallel investigation might ask whether transport recovery loses queued events and whether serialization drops session fields, if those questions are independently useful. Investigators report confirming, falsifying, and contradictory evidence rather than defending explanations. A mutation-dependent experiment goes to root or a permitted role. Once the cause is sufficiently established, root or Implementer fixes the owned path and obtains an appropriate regression check; preserve flaky outcomes and uncertainty.

Continue the same Mapper or Debugger thread for a narrow follow-up in that logical path when the handoff contract permits. After implementation, use a fresh Verifier or Reviewer when independent challenge materially matters.

## Parallel modules with shared contracts

Root captures relevant starting changes, establishes shared interfaces and a single shared-file owner, and assigns independent modules to writers within runtime capacity. A newly shared registration file goes through parent coordination before mutation. Root reconciles combined behavior and uses final-state evidence that actually covers the integration; it does not rerun the same check under another label.

## Concurrent verification and review

After an elevated change by root or Implementer reaches a stable relevant state, Verifier exercises required behavior while Reviewer inspects a distinct sensitive boundary, if neither depends on the other's result and their resource use is compatible. Root triages results. A later shared-contract fix invalidates affected evidence and may need focused re-review; an unrelated UI edit need not invalidate the original checks.

## Analysis-only request

User asks to explain reconnect state loss without changing code. Root inspects directly or assigns a bounded read-only investigation carrying that modality. It returns supported analysis and uncertainty. A proposed fix is not permission to implement, and commands with prohibited side effects are not run.

## User-skipped verification

User requests a change but says to skip tests. Root or Implementer respects that constraint and performs other useful permitted checks. Test claims remain UNVERIFIED due to instruction, not PASS. Root determines whether the constrained outcome is achieved or partial from remaining evidence; it does not repeatedly request permission to run the waived tests.

## Unavailable verification and baseline failure

A required external test service is unavailable. Record the affected claim as UNVERIFIED and describe the blocker; gather remaining useful permitted evidence. Return partial work for an ordinary request where appropriate, while a persistent objective requiring that result remains incomplete under runtime rules. If tests also fail on the baseline, establish attribution from existing evidence or an isolated copy, without mutating the live shared checkout or silently fixing unrelated failures.

## Partial-worker recovery

An interrupted worker has partial edits and a generator still running. Root keeps overlapping ownership unavailable, establishes stoppage of delayed mutations, inspects changes and unverified work, then releases/reassigns safely. A replacement receives the reconciled partial state rather than starting from stale assumptions. If stoppage cannot be established, root works elsewhere where safe.

## Shared mutable test resources

Two checks target disjoint modules but reset the same database or bind the same port. Root isolates resources where practical or sequences the checks. Concurrent source-read access alone does not establish independent observations.

## Serious uncertain finding

Reviewer reports a possible authorization bypass with high impact and low confidence. Root chooses INVESTIGATE and obtains targeted evidence, then fixes, defers/reports, or dismisses with a reason. Reviewer does not implement the remediation or decide overall completion. A security fix may need focused inspection even after execution tests pass.

## User steering during active work

User changes the expected reconnect policy while a writer is active. Root identifies affected assignments, updates/stops them, accounts for delayed writes, reconciles partial changes and ownership, and replaces obsolete criteria/evidence. Unaffected work can continue; old assignments do not authorize continued mutation against the new request.

## Persistent resumption

Root resumes from its compact objective, constraints, criteria, evidence, findings, ownership, blocker, and next-action record. It checks relevant state: a changed serializer can reopen reconnect evidence, while unchanged work stays settled. It continues justified work and uses the same parent completion decision as ordinary tasks. A new turn or long duration alone causes no fresh review or larger team.
