# Production-cost benchmark

Purpose: measure what a real engineering task costs when it is run on the
accepted v1.2 workflow, and score the resulting change independently of the cost
measurement.

Two cases, two independent measurement windows, one case per window.

| Case | Measurement name | Objective |
| --- | --- | --- |
| [case-01](case-01/) | `prod-v12-case01` | Auth refresh-token rotation leaves the presented old token usable |
| [case-02](case-02/) | `prod-v12-case02` | A persisted-event test fails after the version 2 migration |

## What was measured, and what was kept outside the window

The measured window covers only the ordinary engineering turn. Everything else -
workspace preparation, freezing, acceptance judging, cost accounting, and any
review of the produced change - happens outside it.

Purity rules applied between the start and the stop of a window:

1. no unrelated Codex, OpenCodex, or model work on the machine;
2. no reading, grepping, or judging of the produced diff until the window was
   stopped;
3. no manual quota refresh or account switching;
4. a fresh root thread per case, never a resumed or pre-warmed one;
5. the working directory exactly as prepared by the harness;
6. no benchmark file attached, referenced, or mentioned in the conversation;
7. only the contents of `USER_TASK.txt` sent, with no preamble and no reminder
   about agents;
8. the window stopped immediately after the thread produced its ordinary final
   answer, with no follow-up questions and no request for metrics.

## What the measured thread saw

Only the contents of the case `USER_TASK.txt`. It reads like a normal request
from a developer on the team. It mentions `$orchestrator`, because the workflow
under measurement is the subject, and it contains no benchmark vocabulary, no
scoring rules, no expected agents, no expected models, and no hint about where
the defect lives.

The measured session could not see the baseline inventory, the private
acceptance checks, the reference correction, the evaluator, or the cost
analyzer.

## Cost metrics

Reported per case, per model: request count, input tokens, cached input tokens,
uncached input tokens, cache hit rate, output tokens, and reasoning tokens. Plus
the observed change in the native 5-hour quota pool across the window, and the
provider-hosted worker traffic that was actually spent.

Three distinctions are load-bearing:

- **Raw input is not uncached input.** Cache hits dominate the input figures, so
  the input column overstates fresh work by roughly an order of magnitude.
- **Quota percentage is account-pool level.** The upstream surface does not
  expose an exact per-model percentage cost, so a percentage delta cannot be
  attributed to one model.
- **Telemetry is model-level, not role-level.** The runtime does not expose a
  proven agent-id mapping, so no per-role or per-worker traffic is claimed
  anywhere in this repository. Requests are attributed to a model only.

In addition, native root and native verifier traffic share one physical account
quota pool, so the split between them is not separable from the outside.

## Correctness scoring

Scoring is deterministic and runs offline:

| Bucket | Weight |
| --- | ---: |
| Correctness | 60 |
| Scope / minimality | 15 |
| Regression evidence | 15 |
| Unrelated-state preservation | 10 |

The scorer never considers agent count, model choice, root versus worker
implementation, or patch text. Cost and correctness are therefore independent
observations of the same run rather than two views of one judgement.

Scope is scored against the smallest correct change: in a case where the
production source does not need to change, an edit to production source costs
scope rather than earning credit.

## Published results

| Case | Score | Hard failures | Root requests | Native 5h delta | Worker traffic |
| --- | ---: | --- | ---: | ---: | --- |
| case-01 | 100/100 | none | 20 | +5 pp | 13 provider-hosted worker requests |
| case-02 | 100/100 | none | 8 | +2 pp | none |

- [results/case-01.md](results/case-01.md)
- [results/case-02.md](results/case-02.md)

Case 02 is published precisely because it used **no delegated worker at all**.
The direct-root path was the correct answer there, the benchmark scored it
100/100, and the harness treats a correct no-delegation decision as a pass rather
than a missed opportunity. It is the counterexample to reading this workflow as a
mandatory pipeline.

## Layout and file contract

```
case-01/  USER_TASK.txt, pristine/     the exact starting tree and the request text
case-02/  USER_TASK.txt, pristine/     the exact starting tree and the request text
scripts/  Prepare-ProductionCase.ps1   rebuilds generated/runs/<case>/work from pristine
scripts/  Evaluate-ProductionCase.ps1  freezes, diffs, scores, and writes reports
results/  case-01.md, case-02.md        sanitized aggregate results
```

`Prepare-ProductionCase.ps1` is self-contained: it copies one case's `pristine`
tree into `generated/runs/<case>/work`, writes a deterministic SHA-256 baseline
outside the work tree, and refuses to hand out a work directory that still
contains benchmark material. It makes no model calls and never starts a
measurement.

`Evaluate-ProductionCase.ps1` requires a case-local check suite at
`case-XX/private/checks/hidden-checks.mjs` and refuses with a clear message when
it is absent. That suite is intentionally **not published**: it contains the
discriminating acceptance checks, and a measured session that could read it would
no longer be measured. The contract is small:

- the check script is invoked as `node hidden-checks.mjs <work> <pristine> <baseline.json> <temp>`;
- it prints one line beginning `OCXRESULT ` followed by JSON with a `checks`
  array of `{ id, title, status, detail }` entries, where `status` is `pass` or
  anything else;
- it exits 0 or 2 for a usable run; any other exit code, a timeout, or a missing
  `OCXRESULT` line is treated as a failed runner rather than as a pass.

The evaluator then maps check ids onto the published weights, runs the project's
own test suite on a disposable copy of the frozen tree, and writes
`evaluation.json` and `evaluation.md`.

## Published and unpublished material

Published: the case definitions, the starting trees, the request text, the
scoring model, the two harness scripts above, and the aggregate results.

Not published: the acceptance-check implementations, the reference corrections
used to validate that each case is passable, the frozen work trees, the spawn
log, the request ledger, the raw quota captures, the raw measurement directory,
and the measurement and cost-analysis helpers the operator instructions name
(`Measure-OcxUsage.ps1`, `Analyze-ProductionUsage.ps1`). Those contain
account-scoped telemetry and oracle material.

This is a deliberate split between what can be rerun and what is evidence:

- **Reproducible here:** the engineering benchmark and its deterministic
  evaluator. Both harness scripts run offline, make no model calls, and need no
  private material; the unpublished check suite is replaced by the reader's own
  checks against the documented contract.
- **Historical evidence:** the published cost figures. They record what the
  original measured runs actually spent on one machine and one account pool, and
  they cannot be regenerated end to end without the private collector.
- **Not bundled:** that collector was environment- and account-specific, which
  is exactly why it is not published. Measuring cost with this benchmark
  requires the reader's own compatible measurement method, while running and
  scoring the engineering case does not.

## Limits

These are two tasks measured on one machine, one account pool, and one date.
They are controlled observations, not a universal cost model, and the quota delta
in particular depends on the environment and the account pool rather than on the
workflow alone.
