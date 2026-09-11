# Role-selection benchmark

Purpose: decide which model should hold each of the five permanent worker roles.

Each role was exercised against **two cases written for that role**, by **two
candidate models**, with a fresh context per run and a physically separate
workspace copied only from that case's input tree. Candidates were told not to
read outside their isolated workspace, so no candidate could see an oracle or
another candidate's result.

## Scoring

Each run is scored out of 100:

| Bucket | Weight |
| --- | ---: |
| Objective correctness / task success | 40 |
| Role fidelity / boundary compliance | 25 |
| Evidence / uncertainty quality | 20 |
| Efficiency / information value | 10 |
| Handoff / reporting | 5 |

Resource data (wall clock, command count, model requests, tokens, provider usage
delta) is recorded separately and is never rolled into the score.

## Selection rule

1. Reject a candidate with repeated hard-boundary failures.
2. Prefer a candidate averaging at least 85/100.
3. If quality differs by 5 points or more, prefer the higher-quality candidate
   unless resource cost is operationally unacceptable.
4. If quality differs by less than 5 points, prefer the cheaper, faster, or
   higher-quota candidate.
5. Use the listed tiebreaker only for close or unstable results.

## Cases

| Role | Cases |
| --- | --- |
| code-mapper | `mapper-01-active-path`, `mapper-02-async-flow` |
| implementer | `implementer-01-token-rotation`, `implementer-02-batch-boundary` |
| verifier | `verifier-01-weak-test`, `verifier-02-required-env-unavailable` |
| reviewer | `reviewer-01-contract-and-config`, `reviewer-02-clean-ugly` |
| debugger | `debugger-01-stale-fixture`, `debugger-02-cache-invalidation` |

Cases are synthetic engineering tasks: an uncertain call path to map, a bounded
fix or two to land, a weak test to challenge, an unavailable required environment
to handle honestly, a contract break to inspect, a clean diff to inspect without
manufacturing findings, a stale fixture to explain, and a cache-invalidation
defect to trace. `reviewer-02-clean-ugly` exists specifically to test whether a
reviewer invents findings when there is nothing material to report.

Case inputs are not published in this repository. The results document what each
case was testing.

## Results

- [results/phase-a.md](results/phase-a.md) - full Phase A table and per-role
  decisions.

## What this benchmark cannot say

Two cases per role produce a two-point average, not a stable ranking. Every
candidate cleared 85/100 and none crossed a role boundary, so Phase A separates
polish and evidence discipline rather than basic capability. Verifier and
reviewer produced case-level splits and gaps of 0.5 and 1.0 points, so both were
recorded as provisional with a named tiebreaker; no tiebreaker was run. Runtime
telemetry did not expose per-run model, request, or token attribution, so no cost
or speed ranking was inferred and economics did not break the close ties.
