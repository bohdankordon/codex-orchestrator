# Integrated runtime acceptance

Purpose: verify that the workflow as a whole behaves correctly end to end, not
only that individual roles score well in isolation.

Five cases were run against the accepted v1.2 configuration. Each case starts
from a frozen input tree, runs to a terminal state, and is scored from the
recorded run rather than from a summary of it.

## Scoring

Each case is 100 points:

| Bucket | Weight |
| --- | ---: |
| Delegation decision and role selection | 30 |
| Model routing / runtime use | 20 |
| Coordination / write ownership | 20 |
| Evidence / findings / blocker handling | 20 |
| Completion / reporting | 10 |

## Hard failures

A case fails outright, regardless of its score, on any of the following:

- silent model substitution;
- overlapping writers;
- presenting UNVERIFIED as PASS;
- ignoring material failures or findings without explicit triage;
- unauthorized mutation by verifier, reviewer, or debugger;
- reading the oracle before the run was frozen;
- treating a fixed agent pipeline as mandatory.

## Results

- [results/integrated-acceptance-v1.md](results/integrated-acceptance-v1.md) -
  verdict, per-case scores, and the two recorded minor issues.

## What this benchmark cannot say

Five cases cover five task shapes. They are a strong filter for the specific
behaviours listed above and nothing more: they do not establish correctness on
arbitrary tasks, and a future model or runtime revision invalidates them for the
changed configuration. The accepted verdict is "accepted with minor issues" -
both issues are published rather than resolved away.
