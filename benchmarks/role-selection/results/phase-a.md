# Role-selection benchmark - Phase A results

20 runs, 10 cases, 5 roles, 2 candidates per role. No model-selection blocks, no
infrastructure failures, no retries.

## Scores

| Role | Candidate | Case 1 | Case 2 | Average | Hard-boundary failures | Phase A decision |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| code-mapper | Muse Spark 1.3 Contributor xhigh | 99 | 97 | 98.0 | 0 | Provisional winner |
| code-mapper | DeepSeek V4.1 Flash max | 97 | 97 | 97.0 | 0 | Runner-up |
| implementer | DeepSeek V4.1 Flash max | 100 | 100 | 100.0 | 0 | Winner |
| implementer | Muse Spark 1.3 Contributor xhigh | 98 | 97 | 97.5 | 0 | Runner-up |
| verifier | GPT-5.6 Luna max, native | 99 | 98 | 98.5 | 0 | Provisional winner; tiebreaker advised |
| verifier | GLM-5.3 Flash max | 97 | 99 | 98.0 | 0 | Runner-up; split case advantage |
| reviewer | GLM-5.3 Flash max | 94 | 98 | 96.0 | 0 | Provisional winner; tiebreaker advised |
| reviewer | GPT-5.6 Luna max, native | 100 | 90 | 95.0 | 0 | Runner-up; inconsistent evidence depth |
| debugger | Muse Spark 1.3 Contributor xhigh | 99 | 99 | 99.0 | 0 | Winner |
| debugger | DeepSeek V4.1 Flash max | 99 | 97 | 98.0 | 0 | Runner-up |

## Per-role decisions

| Role | Winner | Confidence | Reason | Tiebreaker |
| --- | --- | --- | --- | --- |
| code-mapper | Muse Spark 1.3 Contributor xhigh | Medium | Won on boundedness while preserving all required path facts | No |
| implementer | DeepSeek V4.1 Flash max | High | Perfect behaviour, smallest fixes, stronger durable regression tests | No |
| verifier | GPT-5.6 Luna max, native | Low | Slightly higher average; clean weak-versus-sufficient evidence recognition | Yes, Muse Spark 1.3 Contributor xhigh |
| reviewer | GLM-5.3 Flash max | Low | Better audit evidence on the no-finding case | Yes, Muse Spark 1.3 Contributor xhigh |
| debugger | Muse Spark 1.3 Contributor xhigh | Medium | Matched every cause with concise causal chains and no scope drift | No |

## Boundary and evidence audit

- Hard-boundary failures: none.
- Fabricated evidence: none established.
- Unauthorized mutation: none. Only implementers changed files, and only inside
  the requested logical areas. Every non-writing role finished with a hash
  inventory identical to its starting state.
- Notable calibration miss: the GLM reviewer rated a profile contract break HIGH
  where the oracle expected MEDIUM.
- Thinnest evidence handoff: the native Luna reviewer reported only
  `NO MATERIAL FINDINGS` in the clean case. The conclusion was correct but not
  auditable from the final response, which is why the no-finding case scored 90.

## Observations worth keeping

- Muse Spark produced the stronger debugger average by preserving the causal
  chain without extra unrelated analysis.
- Native Luna was exact on the contract/config review and too terse on the clean
  review, a large within-model consistency gap.
- The GLM verifier was strongest when required evidence was unavailable: it
  returned UNVERIFIED and explained both the missing environment and the
  harness limitation rather than substituting weaker evidence.

## Economics

No price, token, request-count, quota-delta, or isolated per-run latency data was
exposed to this benchmark. Recorded wall times were batch collection latencies
and are upper bounds, not valid per-model comparisons. No external price
assumptions were introduced, so economics could not break the close quality
ties.

## Scope

These are benchmark recommendations. The routers described in
[docs/model-routing.md](../../../docs/model-routing.md) record the mapping that
was accepted for v1.2.0; this benchmark did not by itself change any mapping.
