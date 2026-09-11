# Planner integration

Codex Orchestrator does not replace product or architecture planning. It
replaces execution orchestration inside the repository.

An external planning conversation—ChatGPT is a common example—can retain the
decisions and context that led to an engineering task. Codex should receive
that task contract, then use `$orchestrator` to inspect and execute the work in
the real repository.

Product / architecture planning
: external ChatGPT or another planner conversation

Repository execution planning
: Codex root using `$orchestrator`

The planner may decide what must be true. It should generally not decide how
the orchestrator distributes repository work among specialist agents.

For example, this is useful established context:

> Registration must send a verification email. The verification token expires
> after 30 minutes, resend is rate-limited, and the existing API response
> contract must remain compatible.

This is normally an inappropriate handoff:

> First spawn Code Mapper, then use DeepSeek Implementer, then Luna Verifier,
> then Reviewer.

## Planner vs orchestrator responsibilities

| External planner | `$orchestrator` in Codex |
| --- | --- |
| Clarifies the objective and preserves established requirements. | Inspects the real repository and selects evidence obligations. |
| Reasons with the user about product and architecture choices. | Chooses direct-root execution or delegation. |
| Identifies scope, compatibility constraints, and acceptance criteria. | Selects workers through the validated routing overlay. |
| Carries useful project context into a self-contained handoff. | Manages sequencing, parallelism, ownership, and worker reuse. |
| Distinguishes known facts from assumptions. | Decides when independent verification or review matters, integrates results, and determines completion. |

A zero-worker, direct-root result is valid when delegation would not improve the
needed evidence or outcome.

## What a good handoff contains

Include only what is relevant, but provide these when known:

- objective;
- observed or current behaviour;
- desired behaviour;
- established context from the planning conversation;
- acceptance criteria;
- scope boundaries and constraints;
- interfaces or contracts that must remain compatible;
- relevant paths or components only when genuinely known;
- verification expectations and known evidence;
- uncertainties or assumptions Codex should verify; and
- preservation requirements such as `Preserve unrelated work.`

Do not invent implementation details merely to make the prompt look precise.
If the planner knows what must happen but has not established how the repository
currently implements it, state the requirement and let `$orchestrator` inspect
the real code path.

## What the planner should not prescribe

Normally, do not tell Codex to:

- spawn Code Mapper first or use Implementer next;
- always run Reviewer or Verifier;
- use a specific worker model or reasoning effort;
- keep a worker alive for caching;
- resume or spawn a worker according to an external policy; or
- force delegation for every task.

Those decisions already belong to `$orchestrator`. Exceptions are legitimate
when worker, routing, or orchestration behaviour is itself the subject of the
task or a benchmark.

## Fresh Codex thread

A fresh Codex thread cannot assume access to the external planning conversation,
so the generated task should be self-contained. A useful general shape is:

```text
Use $orchestrator.

<Objective>

<Relevant established context>

<Required behaviour / acceptance criteria>

<Constraints and things that must remain unchanged>

<Relevant known paths/interfaces, only when genuinely known>

<Verification expectations>

Preserve unrelated work.
```

This is a shape, not a rigid template. Do not add empty headings merely to make
a prompt look formal.

For the current v1.2 baseline, the default root recommendation is **GPT-5.6 Sol
— High**. When an external planner is asked which model to choose for a Codex
task, it should normally recommend only that root model. It should not choose
models for Code Mapper, Implementer, Verifier, Reviewer, or Debugger; those are
owned by the current validated routing overlay. Future releases may change this
routing recommendation.

## Continuing the same Codex thread

When the user is continuing the same existing Codex thread and the relevant
context is already there, the planner may produce a shorter incremental prompt.
Focus on the delta:

- new objective;
- changed requirement;
- new evidence;
- invalidated assumption;
- additional constraint; or
- next bounded task.

Do not repeat unchanged context unnecessarily. This is different from worker
reuse inside `$orchestrator`: the external planner does not manage worker
lifecycle.

## Copy-paste instruction for an existing planning chat

Paste the following once into an existing ChatGPT project or another planning
conversation to change future Codex handoffs:

```text
From now on, change the implementation workflow for this project.

We now use Codex Orchestrator v1.2.0 for repository engineering work.

Continue helping me normally with product decisions, architecture,
requirements, UX, debugging ideas, implementation approaches, and trade-offs.
However, when I ask you to prepare a prompt for Codex, do not act as the
execution orchestrator anymore.

For Codex engineering tasks:

- Assume the root model is GPT-5.6 Sol — High.
- Normally begin the Codex task with `Use $orchestrator.`
- Do not prescribe a fixed worker pipeline.
- Do not select worker models or worker reasoning efforts.
- Do not require delegation simply because a specialist exists.
- Let $orchestrator decide direct-root versus delegation, evidence obligations,
  worker selection, sequencing, reuse, independence, ownership, verification,
  and integration.

Your job is to produce a high-quality task contract. Include relevant:

- objective;
- established project context;
- desired behaviour;
- acceptance criteria;
- constraints;
- compatibility requirements;
- known interfaces or paths when genuinely established;
- verification expectations;
- known evidence; and
- uncertainties or assumptions that Codex should verify.

Do not invent implementation details merely to make the prompt more specific.
Preserve useful conclusions we already reached in this conversation. Do not
force Codex to rediscover product decisions or requirements already established.

Clearly distinguish established facts, user requirements, and hypotheses or
assumptions Codex should verify.

For a fresh Codex thread, make the task self-contained. If I explicitly say
this is a continuation in the same existing Codex thread, provide a shorter
incremental prompt containing only the relevant delta, new evidence, changed
constraints, or next objective.

Do not include worker caching, spawn/resume, ownership, or verification
sequencing instructions unless those mechanisms are themselves the subject of
the task.

When I ask which model to choose, normally recommend only:

GPT-5.6 Sol — High

Worker routing is $orchestrator's responsibility.
```

## Handoff examples

### Complex bug

Bad handoff:

```text
Use Muse to map the auth code.
Then spawn DeepSeek to implement the fix.
Then Luna must verify it.
```

Good handoff:

```text
Use $orchestrator.

Users can currently reuse the old refresh token after successful rotation.

Make the smallest correct change so a successful rotation invalidates the
presented token while the newly issued token remains valid.

Keep the existing response contract and optional SESSION_V2 path unchanged.

Add or adjust directly relevant durable regression coverage and verify the
behaviour changed.

Preserve unrelated work.
```

### Small change

The planner still writes a bounded task contract:

```text
Use $orchestrator.

<small bounded requirement>

<acceptance criteria and constraints>

Preserve unrelated work.
```

It does not artificially require a worker. The orchestrator may correctly
choose direct-root execution.
