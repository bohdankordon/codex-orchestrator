# case-01 - auth refresh-token rotation leaves the old token usable

## Objective

After a successful `POST /session/rotate`, the presented old refresh token is
still usable. The task is to find the real production-default path, make the
smallest correct fix so a successful rotation invalidates the presented token
while the newly issued token stays valid, preserve the response contract and the
optional V2 path exactly, add durable regression coverage, and preserve unrelated
work.

## What the case tests

- whether the default production path is identified before it is changed, rather
  than the first plausible-looking store being edited;
- whether the fix removes the cause instead of adding a check at the edge;
- whether the response shape and the optional alternate path stay byte-exact in
  behaviour;
- whether the added regression coverage actually fails when the defect is
  restored;
- whether unrelated files are preserved.

The starting tree contains a deliberately plausible wrong path, so a solution
that changes the wrong store can still look locally consistent.

## Layout

```
USER_TASK.txt    the exact request text sent to the measured thread
pristine/        the exact starting tree of the case
```

## Recorded result

Score **100/100**. Hard failures: none. Unsatisfied task requirements: none.

| Bucket | Awarded | Max |
| --- | ---: | ---: |
| Correctness | 60 | 60 |
| Scope / minimality | 15 | 15 |
| Regression evidence | 15 | 15 |
| Unrelated-state preservation | 10 | 10 |

Change set: production source files changed **1**, added **0**, deleted **0**.
One production store and one test file were modified. Protected documentation
artifacts were byte-identical to the baseline. The project suite passed with exit
code 0, one test file, two tests, zero failures, and the suite was confirmed to
fail when the defect is restored.

## Cost record

| Metric | Value |
| --- | ---: |
| Root requests | 20 |
| Root input / cached / uncached | 883,237 / 803,968 / 79,269 |
| Root cache hit | 91.03% |
| Root output / reasoning | 6,397 / 1,845 |
| Native verifier requests | 7 |
| Native low-effort helper requests | 4 |
| Provider-hosted worker requests | 13 |
| Provider-hosted input / cached / uncached | 370,321 / 310,084 / 60,237 |
| Provider-hosted output / reasoning | 7,220 / 3,398 |
| Native 5h quota delta | +5 percentage points, no reset |

Provider-hosted worker traffic split across two models (5 and 8 requests).

The four low-effort native helper requests are ordinary runtime helper calls,
reported separately and never counted as verifier work. They are not orchestrator
delegation.

## Notes

This case used delegated workers. Case-02 did not, and both scored 100/100 -
delegation is adaptive in this workflow, not mandatory.
