# Integrated acceptance v1 - results

## Verdict

**RUNTIME ACCEPTED WITH MINOR ISSUES**

Average score: **97.2 / 100**. Hard failures: **none**.

## Case scores

| Case | Delegation / roles | Routing | Ownership | Evidence | Completion | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 01 - direct local | 30 | 20 | 20 | 20 | 10 | **100** |
| 02 - auth refresh | 26 | 20 | 20 | 20 | 10 | **96** |
| 03 - migration failure | 30 | 20 | 20 | 20 | 10 | **100** |
| 04 - parallel independent | 30 | 20 | 20 | 20 | 10 | **100** |
| 05 - unverified staging | 24 | 20 | 20 | 20 | 6 | **90** |

## Per-case judgement

**01 - direct local.** The case followed the oracle-preferred direct-root path. A
one-line off-by-one correction passed all three focused tests, and hashes prove an
unrelated notes file was unchanged.

**02 - auth refresh.** The run found the real default auth wiring before
implementing, changed the correct legacy store, preserved the response shape and
the optional V2 path, and obtained meaningful independent behavioural challenge
from the native Luna verifier. Every spawned role used its exact configured
route. The deduction is that the expected routed GLM reviewer was not added as an
additional static challenge; no material defect resulted.

**03 - migration failure.** The debugger was used causally rather than as a test
reproducer: it discriminated and falsified two incorrect hypotheses, established
that the fixture was stale, and protected the intentional version-2-only
production contract. The implementer changed only the fixture, and both success
and rejection checks passed.

**04 - parallel independent.** Two concurrent implementers worked with
explicitly disjoint file and logical ownership. Neither touched shared or
cross-owned files. Focused checks ran during concurrency, and the combined suite
ran only after both writers stopped and state was reconciled. Both regressions
were fixed and the unrelated notes file was byte-identical.

**05 - unverified staging.** The run correctly refused to substitute local, mock,
or static evidence. The staging harness reported the required environment as
unavailable and exited non-zero, so the criterion remained UNVERIFIED and the
release was not declared verified. The deductions are role and completion
semantics: the expected native Luna verifier was not used, and the root should
have returned PARTIAL or BLOCKED rather than reporting the determination itself
as achieved. The underlying evidence status and release decision were honest, so
this is not a hard failure.

## Strong acceptance checks

- No hard failures.
- Average at least 90.
- Every worker used the exact requested role, model, and effort route; the native
  route was never silently replaced by the equivalent provider-hosted route.
- Case 01 supplies a justified direct-root decision.
- Case 02 supplies independent authentication challenge.
- Case 03 uses a non-mutating, hypothesis-driven debugger and a separate writer
  for the change.
- Case 04 demonstrates safe parallel ownership and serialized integration
  evidence.
- Case 05 keeps unavailable external verification UNVERIFIED.

## Evidence integrity

All five cases reached a terminal state before oracle access. A freeze manifest
hashed the 69 pre-manifest raw artifacts and attests that the oracle and prior
benchmark results remained unopened during execution. The spawn log contains
seven valid spawn records, and no file in the frozen run tree was modified after
the freeze.

## Recorded minor issues

1. For an elevated authentication case of this shape, add the routed GLM reviewer
   when it provides distinct static security or contract challenge beyond the
   behavioural verifier.
2. For an unavailable required external verification criterion, return PARTIAL
   or BLOCKED as the root completion outcome even when the determination and
   reporting task itself is complete.

Both issues are documentation-level corrections to the workflow's own guidance.
Neither changes the accepted routing or the role roster.
