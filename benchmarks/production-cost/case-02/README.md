# case-02 - stale persisted event fixture after migration

## Objective

A persisted-event test fails after the event-format migration. Production emits
version 2, version 1 is intentionally unsupported, and production validation must
not be weakened. The task is to diagnose the cause, make the smallest
cause-removing correction so the migrated fixture succeeds while version 1 input
is still rejected, keep the version-2-only contract intact, verify the relevant
behaviour, and do no unrelated cleanup.

## What the case tests

- whether the failure is diagnosed as a stale fixture rather than treated as a
  parser defect;
- whether the intentional version-1 rejection is preserved instead of "fixed" by
  relaxing validation;
- whether the correction stays inside the test fixture, where the cause actually
  is;
- whether unrelated retention and migration documentation stays untouched.

This is the reference case for the direct-root path: nothing in the task requires
an independent behavioural challenge, a mapping pass, or a separate writer, and
the measured run correctly used none of them.

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

Change set: production source files changed **0**, added **0**, deleted **0**.
Exactly one fixture file was modified. Protected documentation artifacts were
byte-identical to the baseline. The project suite passed with exit code 0, one
test file, one test, zero failures, and the suite was confirmed to fail when the
fixture is stale.

## Cost record

| Metric | Value |
| --- | ---: |
| Root requests | 8 |
| Root input / cached / uncached | 261,065 / 244,352 / 16,713 |
| Root cache hit | 93.6% |
| Root output / reasoning | 2,328 / 876 |
| Native verifier requests | 0 |
| Native low-effort helper requests | 1 |
| Provider-hosted worker requests | 0 |
| Native 5h quota delta | +2 percentage points, no reset |

No provider-hosted worker traffic was spent at all. The single low-effort native
helper request is an ordinary runtime helper call, reported separately and never
counted as verifier work.

## Notes

This case is published as evidence that no delegation can be the correct answer.
The benchmark scores the omitted delegation as a pass, because the direct-root
path satisfied every evidence obligation the task created.
