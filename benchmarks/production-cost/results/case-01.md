# Production-cost result - case-01

| Field | Value |
| --- | --- |
| Case | `case-01` - auth refresh-token rotation leaves the old token usable |
| Verdict | pass |
| Score | **100 / 100** |
| Hard failure | no |
| Unsatisfied task requirements | 0 |
| Root model | GPT-5.6 Sol, High |

## Score

| Bucket | Awarded | Max |
| --- | ---: | ---: |
| Correctness | 60 | 60 |
| Scope / minimality | 15 | 15 |
| Regression evidence | 15 | 15 |
| Unrelated-state preservation | 10 | 10 |

## Change set

| Kind | Count |
| --- | ---: |
| Production source files changed | 1 |
| Files added | 0 |
| Files deleted | 0 |
| Files modified in total | 2 |

Protected documentation artifacts were byte-identical to the baseline.
Unrelated modifications: 0. Unexpected additions: 0.

## Project suite

Exit code 0, 1 test file, 2 tests reported, 0 failures. The suite was separately
confirmed to fail when the defect is restored, so the coverage is durable rather
than incidental.

## Usage

| Model | Effort | Requests | Input | Cached | Uncached | Cache % | Output | Reasoning |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| gpt-5.6-sol | high | 20 | 883,237 | 803,968 | 79,269 | 91.03 | 6,397 | 1,845 |
| gpt-5.6-luna | max | 7 | 170,534 | 134,656 | 35,878 | 78.96 | 12,172 | 9,493 |
| gpt-5.6-luna | low | 4 | 38,270 | 27,648 | 10,622 | 72.24 | 287 | 131 |
| provider-hosted worker traffic | - | 13 | 370,321 | 310,084 | 60,237 | 83.76 | 7,220 | 3,398 |

The 7 native max-effort requests are delegated worker traffic inside the measured
root conversation and represent the verifier route. The 4 low-effort requests are
ordinary runtime helper calls, reported separately and never counted as verifier
work. Provider-hosted traffic split across two models, 5 and 8 requests.

## Native quota

| Pool | Before | After | Delta | Reset detected |
| --- | ---: | ---: | ---: | --- |
| native account pool | 0 | 5 | +5 pp | no |

## Caveats

- Quota percentage is account-pool level. The exact per-model percentage cost is
  not exposed upstream, and native root and native verifier traffic share one
  pool, so the split between them is not separable.
- Raw input is not uncached input. Cached input dominates the input column.
- Attribution is model-level. No per-role or per-agent traffic is claimed.
- These are controlled observations from one environment, not a cost guarantee.
