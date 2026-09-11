# Evidence and Quality Decisions

Use these questions where relevant, not as ordered stages or a report template. The parent selects evidence obligations; agent calls are possible means of satisfying them. Scale detail to the unresolved decision.

## Do we understand enough to act?

Establish the user's intended outcome, modality, observable acceptance criteria, constraints, and ownership sufficiently for the next action. Derive criteria from the objective rather than merely copying implementation assumptions. Do not require repository-wide understanding for localized work. Map uncertain paths only as far as needed; ask for decisions that cannot responsibly be inferred while continuing unaffected work.

## What consequences determine the evidence needed?

Use descriptive risk guidance, not team sizes or mandatory printed classifications:

| Band | Consequences | Evidence emphasis |
| --- | --- | --- |
| LOW | Localized, readily reversible work with limited consequences. | Cheap direct inspection or targeted execution may be decisive. |
| STANDARD | Meaningful behavior with non-trivial correctness or regression consequences. | Demonstrate required behavior and relevant failure/regression conditions; assess the value of independent challenge. |
| ELEVATED | High blast radius, difficult reversibility, substantial uncertainty, sensitive state, or serious consequences. | Address consequential failure modes, boundaries and integration; preserve meaningful independent challenge. |

Sensitive boundaries are explicit modifiers: authentication, authorization, permissions, payments/billing, destructive data operations, secrets, cryptography, sensitive user data, irreversible migrations, and security boundaries. Identify the property at risk and require evidence for it. A one-line change can be elevated; mere proximity to sensitive code does not establish impact.

Consider coupling, concurrency, public compatibility, data persistence, and environment differences where relevant. Increase obligations when evidence reveals additional risk; reduce them when evidence establishes a safer, simpler scope. Neither task size nor a persistent objective determines the band. Do not reduce obligations merely to label unresolved material risk acceptable.

## What must be demonstrated, and what evidence exists?

Identify required behavior/properties and meaningful success, failure, and regression conditions. Use executed behavior, targeted tests, integration/end-to-end checks, relevant regression suites, static checks, or precise code-path inspection according to the claim. Static evidence alone does not demonstrate runtime behavior that it cannot establish. A targeted check can be more useful than a large unrelated suite.

Record enough to substantiate a meaningful result: the claim, relevant state/environment, command or observation method, outcome/exit status, expected versus actual behavior, and limitations. Keep logs concise or referenced; vague confidence and worker assurances are not substitutes for evidence. Do not demand exhaustive logs for cheap obvious checks.

Implementation self-checks are first-party verification. Reuse valid evidence when it actually supports the claim, regardless of which conceptual question originally prompted it. One stable final-state check may establish behavior, integration, regression, and compatibility together; do not rerun equivalent checks just to populate separate stages.

## Does independent challenge materially improve confidence?

Independent verification validates behavior separately from implementation reasoning: derive expectations from the objective, examine assumptions, and obtain evidence rather than echo the author's conclusion. It is valuable for non-trivial behavior, meaningful regression impact, integration, elevated risk, or uncertainty the author/root cannot adequately challenge.

A root that implemented well-understood work may obtain decisive objective evidence without automatically spawning a Verifier. This remains first-party evidence. When the root did not author the relevant implementation, its independent evaluation can contribute; if its subsequent integration edits affect the claim, reassess that separation.

For elevated or sensitive changes, preserve meaningful independent challenge unless explicit user instructions or the environment/runtime prevent it. Test passing or coordination cost alone is not a reason to remove that challenge. Match it to the risk: independent behavioral verification, focused inspection, or both when they address distinct unresolved concerns. Report any material limitation and perform remaining useful permitted checks.

A new agent, different model, or fresh context does not establish independence by itself. Give the evaluator requirements and relevant artifacts; label implementation explanations as claims to check. A reviewer need not duplicate verification, and a Verifier must not fix the failures it is assessing.

## Is the evidence valid for the final relevant state?

Evidence has a scope and basis, not timeless validity. Identify source files and relevant dirty changes, shared contracts, dependencies, generated state, runtime configuration, environment, and external-service assumptions as needed to assess that basis. `HEAD` alone does not identify dirty content. A concise scoped state note, relevant diff/content identity, or available snapshot is sufficient; commits and permanent evidence databases are not required.

Establish a stable relevant window while gathering meaningful verification/review evidence. Conflicting source or resource mutation must be serialized or isolated where necessary; an inconsistent intermediate observation is not authoritative final evidence. An isolated worktree/copy may help when supported and worthwhile, but is not mandatory. If relevant state changed during a check, reassess coverage before accepting the result.

After subsequent changes, invalidate only materially affected evidence. Retain evidence whose basis remains valid and use the narrowest sufficient recheck. Broaden checking when changed contracts, hidden coupling, consequential fixes, or environment differences affect more claims. If freshness cannot be established, treat the affected claim as unverified until reassessed.

For example, reconnect evidence based on `session.ts` and `serializer.ts` may survive an unrelated UI edit. A serializer change requires reassessing that evidence and affected checks, without automatically discarding unrelated results.

Fresh review is warranted when the final relevant state is uncovered, earlier review was invalidated, integration created new risk, or elevated/sensitive risk remains insufficiently challenged. Duration, turn count, and agent count are not triggers. A finding fix that cannot be established through execution alone needs appropriate focused inspection; broad re-review is not automatic.

## What material findings remain?

Reviewer may inspect GENERAL risks or a focused dimension such as correctness, security, performance, architecture, testing, accessibility, reliability, or compatibility. Use multiple reviewers only for distinct material questions. Testing review examines evidence/test adequacy; verification establishes observed behavior. Architecture review needs concrete consequences, not preferred abstractions.

A compact material finding includes the location/surface, triggering condition, plausible impact, supporting evidence, confidence, objective relevance, and recommended direction. "No material findings" is valid. Do not manufacture findings from style, speculative refactors, or unrelated pre-existing issues. Consolidate duplicates.

Keep these decisions separate:

- **Impact:** plausible consequence if real. HIGH means serious consequence, MEDIUM a material bounded consequence, LOW limited consequence. Confidence does not determine impact.
- **Confidence:** HIGH means demonstrated or strongly evidenced; MEDIUM meaningful but incomplete evidence; LOW a plausible concern needing investigation. State assumptions; do not present a hypothesis as confirmed.
- **Parent disposition:** `FIX NOW` for supported current-scope defects or risks requiring correction; `DEFER / REPORT` for real issues appropriately outside current work or acceptable to defer; `DISMISS` for incorrect, unsupported, duplicate, irrelevant, or immaterial items; `INVESTIGATE` temporarily for material uncertainty needing targeted evidence before final disposition.

A high-impact, low-confidence concern can warrant investigation without immediate fixing or dismissal. The parent decides whether a finding prevents completion; severity is not a worker-controlled task-blocking state. Retain material reasons for deferral/dismissal and reopen only when evidence, requirements, or relevant state changes. Formal labels need not be printed for trivial observations.

## What explains failed or conflicting evidence?

Distinguish failures introduced by current work, exposed by it, unrelated pre-existing failures, and unattributed failures when evidence is insufficient. Use known results, CI evidence, relevant history, or targeted reproduction. Do not switch branches, reset, clean, stash user changes, or otherwise mutate the live shared worktree merely to reproduce a baseline; use an isolated copy/worktree when justified and supported.

An unrelated baseline failure does not automatically fail the task. Explain its effect on confidence and keep unrelated repairs outside scope unless the parent explicitly expands it. Do not report an infrastructure outage as an implementation defect or modify correct production code merely to evade an unrelated environment failure.

For an established cause, make an owned targeted fix and recheck affected claims. For an unclear cause, root or Debugger should use a small ranked hypothesis set, discriminating evidence questions, confirming/falsifying observations, and contradictions. Prefer actions with high expected information gain relative to cost. Do not assign investigators to advocate hypotheses. Distinguish causal mechanisms from correlation and retain contrary evidence.

Before retrying, identify a changed condition, new question, more discriminating experiment, or other concrete expected information gain. For flakes, preserve successes and failures, assess relevance to the objective, and narrow conclusions if still inconclusive; never retry until green. Repeated non-informative attempts call for a changed strategy or honest limitation, not repeated delegation.

A diagnostic handoff to implementation should include the causal explanation, violated invariant, affected path, and useful regression check when known, plus remaining uncertainty. Experiments requiring unauthorized writes go to root or a permitted role under the [handoff contract](handoff-contract.md).

## Is integration covered and what remains unverified?

Combined behavior must satisfy relevant shared contracts, data flow, startup, compatibility, and end-to-end requirements. Individual worker success does not establish this. Reuse existing final-state evidence where it covers integration; independent edits with no interaction may need only lightweight reconciliation. Compare relevant starting and final worktree state for lost/unexpected changes, including generated artifacts, without normalizing unrelated work.

For each material claim/check, use `PASS` when demonstrated, `FAIL` when observed behavior contradicts it, or `UNVERIFIED` when evidence is skipped, unavailable, inconclusive, or not gathered. Explain a concrete blocker separately where applicable. Never convert absent evidence into PASS or an environment failure into behavioral FAIL.

Respect user-waived tests/review and record the affected evidence as unverified due to that constraint; do not repeatedly ask to reinstate it. A waiver changes the obligation, not the observed facts. Perform remaining useful permitted checks. Explain exactly what could not be established and the effect on confidence.

## What is the parent completion decision?

Apply the ACHIEVED/PARTIAL/BLOCKED semantics in [SKILL.md](../SKILL.md#completion-and-persistence). Decide from the actual objective, current relevant state, acceptance obligations, valid evidence, finding dispositions, integration, blockers/limitations, and preservation of unrelated work. This is one decision, not another mandatory test suite, review, or agent call. Sufficient evidence does not mean zero residual risk.

An ordinary task may return useful partial work when no justified progress remains available or remaining work is deliberately out of scope; identify the gap. An unverified optional or waived check need not prevent achievement if the remaining evidence suffices for the requested outcome. If a required outcome or confidence obligation remains unmet, reporting the limitation does not establish achievement.

For a concrete blocker, state affected progress, attempts, completed parts, what can still proceed, and what change would unblock it. Persistent objectives retain incomplete work and use actual runtime lifecycle rules; these outcome terms do not create a second goal-state machine.

Before more significant work, identify the uncertainty/risk and expected new evidence. Stop adding orchestration once the requested outcome has sufficient valid support, material findings are resolved or appropriately triaged, integration is covered, and additional work offers little value. If progress is unavailable, report the appropriate partial/blocker state rather than claiming success or repeating empty cycles.
