# Changelog

Public history starts at v1.2.0. Earlier internal iterations were pre-public
development: they are represented by the architecture decision records in
`docs/decisions/` and by `BASELINE.md`, not by invented release entries.

Format follows a lightweight Keep a Changelog style; versions use semantic
versioning.

## [1.2.0] - 2026-09-11

First public production baseline.

### Added

- Adaptive root orchestrator skill and its four reference contracts.
- Five permanent worker role contracts: code-mapper, implementer, verifier,
  reviewer, debugger.
- Public benchmark documentation, sanitized results, and the deterministic
  case and evaluator scripts used to produce them.
- Install, comparison, repository validation, and release-manifest scripts.
- Continuous validation workflow for pull requests and `main`.

### Validated

- Integrated runtime acceptance: accepted, average 97.2/100, no hard failures.
- Production-cost case 01 (auth refresh-token rotation): 100/100, no hard failures.
- Production-cost case 02 (stale persisted event fixture): 100/100, no hard failures.

### Notes

- Worker TOMLs are intentionally model-neutral; routing is a separate overlay.
- Benchmark figures are controlled observations, not guarantees. See `benchmarks/`.
