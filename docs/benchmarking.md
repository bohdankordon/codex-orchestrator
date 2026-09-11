# Benchmarking and evidence

This document explains how the v1.2 claims were produced, what each layer of
evidence is allowed to say, and where the limits are. Published numbers live in
[`benchmarks/`](../benchmarks/).

## Why evidence is packaged with the workflow

The orchestrator makes a cost/benefit decision on every task: delegate or not,
and if so, to whom. That decision is only trustworthy if it is backed by
recorded observations rather than preference. Three separate questions are
asked, and they are answered by three separate benchmarks so that no single
result has to carry more weight than it can bear.

| Question | Layer |
| --- | --- |
| Which model should hold each role? | role-selection |
| Does the whole workflow behave correctly end to end? | integrated-acceptance |
| What does a real task actually cost? | production-cost |

## Layer 1 - role / model selection

Each role was exercised against two purpose-built cases by two candidate models.
Runs were scored out of 100 with fixed weights: objective correctness 40, role
fidelity and boundary compliance 25, evidence and uncertainty quality 20,
efficiency 10, handoff and reporting 5. Resource data (wall clock, command
count, requests, tokens) was recorded separately and never rolled into the score.

Selection rule, applied in order:

1. reject a candidate with repeated hard-boundary failures;
2. prefer a candidate averaging at least 85/100;
3. if quality differs by 5 points or more, prefer the higher-quality candidate
   unless the resource cost is operationally unacceptable;
4. if quality differs by less than 5 points, prefer the cheaper, faster, or
   higher-quota candidate;
5. use the listed tiebreaker for close or unstable results.

What this layer can prove: how each candidate behaved on these two cases, and
whether a candidate stayed inside its role boundary while producing evidence.

What it cannot prove: that the winner is the best available model in general, or
that a two-case average is a stable ranking. Verifier and reviewer were close
enough that both were recorded as provisional with a named tiebreaker rather
than treated as settled. See
[`benchmarks/role-selection/results/`](../benchmarks/role-selection/results/).

## Layer 2 - integrated runtime acceptance

Five cases exercised the workflow as a whole, each scored out of 100: delegation
decision and role selection 30, model routing and runtime use 20, coordination
and write ownership 20, evidence and blocker handling 20, completion and
reporting 10.

A case can fail hard, independent of its score, on any of these behaviours:

- silently substituting a different model than the one requested;
- allowing overlapping writers on the same files or logical area;
- presenting UNVERIFIED evidence as PASS;
- ignoring a material failure or finding without explicit triage;
- mutation by a verifier, reviewer, or debugger that should not have written;
- consulting the oracle before the run was frozen;
- treating a fixed agent pipeline as mandatory.

Hard failures are listed separately from the score because a workflow that
scores well by cutting a safety corner is not acceptable evidence.

What this layer can prove: that on these five cases the workflow selected
delegation sensibly, used the configured routes, kept write ownership clean, and
kept honest evidence states. What it cannot prove: coverage of every task shape.
Five cases are a smoke screen against the failures above, not a proof of
correctness. The accepted result carried two recorded minor issues, both of
which are documented rather than hidden.

## Layer 3 - production-cost

Two independent engineering cases were run in real Codex sessions on the
accepted v1.2 workflow, one case per measurement window. The measured window
covers only the ordinary engineering turn: setup, workspace preparation,
judging, and cost accounting were all performed outside it.

Correctness was scored deterministically (60 correctness, 15 scope and
minimality, 15 regression evidence, 10 unrelated-state preservation) by a
harness that never considers agent count, model choice, root versus worker
implementation, or patch text. Cost and correctness are therefore independent
observations of the same run, not two views of one judgement.

Reported metrics per case: request counts and token figures per model, cache hit
rate, output and reasoning tokens, OpenCode Go traffic, and the native 5-hour
quota delta observed across the window.

What this layer can prove: what these two tasks cost in this environment on this
date, and that the direct-root path can be correct with no delegated worker at
all. What it cannot prove: a general cost model. Quota percentages are reported
at account-pool level, the upstream API does not expose per-model percentage
cost, and raw input tokens must not be conflated with uncached input tokens.

The case definitions and the deterministic evaluator are published, so the
engineering cases can be rebuilt and scored locally without any private
material. The published cost figures are a different kind of artifact: they are
evidence from the original measured runs, and the account/quota collector used
to capture them is intentionally not bundled because it was specific to one
environment and account pool. Reproducing cost telemetry therefore requires a
compatible measurement method of your own.

## Methodology shared by all three layers

- Cases are prepared from a frozen pristine tree with a deterministic hash
  baseline, so a run either matches the prepared state or is rejected.
- Expected findings live in a private oracle that the measured session cannot
  read, and terminal runs are frozen with hashes before judging begins.
- Scoring scripts are deterministic. They take no model input and make no model
  calls.
- Measurements that would reveal account-level or environment-specific state are
  aggregated before publication. See the exclusions listed in
  [`benchmarks/README.md`](../benchmarks/README.md).

## What the published numbers are not

- They are not a leaderboard. No model is declared best, and no vendor ordering
  is implied.
- They are not vendor benchmarks. They were produced by this project for its own
  routing decisions, on the tasks this workflow is built to handle.
- They are not guarantees. Environment, account pool, model revision, and task
  shape all affect the numbers, and the published results state that where it
  matters.

## Adding evidence

A change that affects delegation, ownership, routing, or role boundaries should
arrive with evidence proportionate to the change: an updated case result, a new
case in the appropriate layer, or an explicit note that the change is
documentation-only. Adding a case means adding a `USER_TASK.txt`, a `pristine`
tree, and the private acceptance criteria that score it; the public package
documents the file contract in
[`benchmarks/production-cost/`](../benchmarks/production-cost/).
