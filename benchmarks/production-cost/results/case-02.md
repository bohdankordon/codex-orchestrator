# Production-cost result - case-02

| Field | Value |
| --- | --- |
| Case | `case-02` - stale persisted event fixture after migration |
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
| Production source files changed | 0 |
| Files added | 0 |
| Files deleted | 0 |
| Files modified in total | 1 |

Exactly one fixture file changed. Protected documentation artifacts were
byte-identical to the baseline. Unrelated modifications: 0. Unexpected
additions: 0.

## Project suite

Exit code 0, 1 test file, 1 test reported, 0 failures. The suite was separately
confirmed to fail while the fixture is stale.

## Usage

| Model | Effort | Requests | Input | Cached | Uncached | Cache % | Output | Reasoning |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| gpt-5.6-sol | high | 8 | 261,065 | 244,352 | 16,713 | 93.6 | 2,328 | 876 |
| gpt-5.6-luna | max | 0 | 0 | 0 | 0 | - | 0 | 0 |
| gpt-5.6-luna | low | 1 | 10,861 | 6,912 | 3,949 | 63.64 | 38 | 0 |
| provider-hosted worker traffic | - | 0 | 0 | 0 | 0 | - | 0 | 0 |

No delegated worker traffic was spent. The single low-effort request is an
ordinary runtime helper call, reported separately and never counted as verifier
work.

## Native quota

| Pool | Before | After | Delta | Reset detected |
| --- | ---: | ---: | ---: | --- |
| native account pool | 5 | 7 | +2 pp | no |

## Caveats

- Quota percentage is account-pool level. The exact per-model percentage cost is
  not exposed upstream and is not separable between models sharing the pool.
- Raw input is not uncached input.
- Attribution is model-level. No per-role or per-agent traffic is claimed.
- These are controlled observations from one environment, not a cost guarantee.
- A no-delegation result here is a correct decision, not a convention. It does
  not imply that delegation is avoided in general.
