# Benchmark evidence

This directory holds the evidence behind the v1.2 decisions. It is organised in
three independent layers, because a single benchmark cannot honestly answer all
three questions the project needs answered.

| Layer | Question | Result |
| --- | --- | --- |
| [role-selection](role-selection/) | Which model should hold each role? | Each of the five roles exercised twice by two candidates |
| [integrated-acceptance](integrated-acceptance/) | Does the whole workflow behave correctly? | 5 cases, average 97.2/100, no hard failures |
| [production-cost](production-cost/) | What does a real task actually cost? | 2 cases, 100/100 each, measured Sol and OpenCode Go traffic |

Methodology, weights, selection rules, and the limits of each layer are described
in [docs/benchmarking.md](../docs/benchmarking.md).

## What each layer can prove

**Role-selection** can show how a candidate model behaved on two purpose-built
cases for one role, and whether it stayed inside that role's authority boundary.
It cannot show that a winner is the best available model in general. Verifier and
reviewer were close enough that both were recorded as provisional with a named
tiebreaker rather than treated as settled.

**Integrated-acceptance** can show that on five end-to-end cases the workflow
selected delegation sensibly, used the exact configured routes, kept a single
active writer, and kept dishonest evidence states out. It cannot show coverage of
every task shape. The accepted verdict carried two recorded minor issues.

**Production-cost** can show what these two tasks cost, in this environment, on
this date, and that the direct-root path can be the correct answer with no
delegated worker at all. It cannot produce a general cost model: quota
percentages are account-pool level, the upstream API does not expose per-model
percentage cost, and raw input tokens are not the same measurement as uncached
input tokens.

## What is deliberately not published

The measured sessions must not be able to read what they are being measured
against, so each layer separates public material from private material. Not
published here:

- graders' oracles, expected-finding sets, and the reference corrections used to
  validate that a case can be passed;
- hidden acceptance checks that discriminate a correct fix from a plausible one;
- raw per-request telemetry ledgers, account quota captures, account identifiers,
  account labels, and provider configuration dumps;
- frozen run trees and spawn logs from internal execution;
- the measurement and cost-analysis helper scripts used around a measured
  window; the harness scripts name those helpers without shipping them;
- superseded internal runs, including one pre-configuration run that was
  quarantined and never used as input.

What is published instead: case definitions that a reader can inspect and
rebuild, aggregate results, the weights, the hard-failure list, and the
deterministic scoring scripts where they can run without the private material.

## What a reader can and cannot reproduce

- **Reproducible:** the production-cost engineering benchmark. Its case
  definitions, starting trees, and deterministic evaluator are published, so a
  reader can rebuild a case from its pristine tree and score a run offline. The
  evaluator expects a case-local check suite; that suite is not published, and a
  reader supplies their own checks against the documented contract.
- **Published as evidence, not as a rerun:** the sanitized cost results. They
  record what the original measured runs actually spent, and a new user cannot
  regenerate those figures end to end from this repository alone.
- **Intentionally not bundled:** the account/quota telemetry collector used for
  those historical measurements. It was specific to one environment and one
  account pool, so it would not produce comparable numbers elsewhere.
- **Published as sanitized aggregates:** the role-selection and
  integrated-acceptance results. Their case sets and run trees are not bundled,
  for the same measurement-purity reason.
- **Runnable without the private tooling:** the engineering benchmark and its
  deterministic evaluator. Cost telemetry instead needs a compatible
  measurement method of the reader's own.

## Reading the numbers

These results were produced by this project, for this project's routing and
delegation decisions, on the task shapes this workflow is designed to handle.

- No model is declared best in general, and no vendor ordering is implied.
- No result is a guarantee. Model revisions, account pools, and environment all
  affect the numbers, and where that matters the result says so.
- Scores are not comparable across layers. Role-selection and acceptance weights
  differ deliberately because they measure different obligations.
