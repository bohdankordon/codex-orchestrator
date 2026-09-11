# Contributing

Short version: branch, change, validate, open a pull request, squash merge.

## Workflow

1. Branch from `main`. Use a short-lived, descriptive branch name
   (`feat/root-turn-economy`, `fix/resume-ownership`, `docs/install-guide`,
   `test/production-cost-case`).
2. Make the change, including the documentation it invalidates.
3. Validate locally:

   ```
   .\scripts\Test-Repository.ps1
   ```

  This runs the same checks as CI: required files, TOML syntax, model-neutral
  worker contracts, reference presence, VERSION format, manifest consistency,
  structured benchmark files, JSON and YAML structure, local links, secret
  patterns, and personal-path patterns.
4. Open a pull request. Answer what changed, why, how it was validated, and
   whether there is any compatibility impact. Working commits on the branch are
   fine and are not individually reviewed for perfection.
5. Squash merge. The squash commit is the durable artifact, so give it a clean
   conventional-commit title, for example `feat: improve root turn economy (#12)`.

Full policy and examples: [docs/git-workflow.md](docs/git-workflow.md).

## Architecture changes

Changes to delegation policy, write ownership, quality gates, role boundaries,
or routing are architecture changes. They need a rationale and usually evidence:

- update the matching record in `docs/decisions/`, or add a new one;
- state what the change makes better and what it costs;
- link any benchmark evidence to a case in `benchmarks/`.

Do not add measured-looking numbers that were never measured. Routing changes
should reference the benchmark or evaluation that motivated them.

## Changing the frozen baseline

`orchestrator/` and `agents/` hold the validated production source. They are
copied into the repository byte-for-byte and are covered by
`manifests/v1.2.0.sha256`. A change here is a baseline change: it needs an
accepted decision record, a refreshed manifest
(`scripts/New-ReleaseManifest.ps1`), and validation output that supports it.

## Scope

Please keep contributions proportional. This repository is a small, technical
project: documentation, role contracts, routing, benchmark evidence, and the
scripts that check them. Large process machinery, release automation, and
speculative abstraction are out of scope unless a concrete need already exists.

## Issues

Use the bug report form for behaviour that is wrong or unsafe, and the
improvement form for a proposed change. Keep either one short and concrete:
observed versus expected behaviour, reproduction, runtime and configuration
context, and the evidence you have.

Do not include credentials, account identifiers, or raw telemetry. See
[SECURITY.md](SECURITY.md).
