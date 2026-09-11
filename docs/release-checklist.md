# Release checklist

The procedure for cutting a release. It is written down so the steps are the same
every time. **It has not been executed for v1.2.0:** this repository has no git
history, no tag, and no published release yet.

## 1. Confirm the baseline is the accepted baseline

- [ ] The production source has not drifted. If an orchestrator is installed
      locally, `scripts\Compare-Installed.ps1` should report every file as
      identical. Otherwise compare against the recorded hashes in the
      [release manifest](../manifests/).
- [ ] No worker TOML has gained a model, provider, or effort pin. Roles stay
      model-neutral; routing stays in the routing reference.
- [ ] The five roles are still exactly code-mapper, implementer, verifier,
      reviewer, debugger. A roster change is an architecture change and needs an
      ADR plus evidence, not a release step.

## 2. Validate the repository

- [ ] `scripts\Test-Repository.ps1` passes under Windows PowerShell 5.1.
- [ ] `scripts\Test-Repository.ps1` passes under PowerShell 7.
- [ ] Every PowerShell script parses under Windows PowerShell 5.1.
- [ ] The Markdown links in the changed documents resolve.

## 3. Refresh the release material

- [ ] `VERSION` holds the version being released.
- [ ] `scripts\New-ReleaseManifest.ps1` regenerates `manifests\v<version>.sha256`
      and reports no change to the production source hashes.
- [ ] `CHANGELOG.md` has an entry for the version and the date.
- [ ] `README.md` and `BASELINE.md` name the same version.
- [ ] If routing changed, the routing table in `README.md`, `BASELINE.md`, and
      `docs\model-routing.md` agree with the routing reference.
- [ ] If behaviour changed, the change carries evidence or an explicit note
      saying why evidence was not needed. See [benchmarking.md](benchmarking.md).

## 4. Re-read the public surface

- [ ] No account identifiers, quota dumps, raw telemetry, personal absolute
      paths, or credentials anywhere in the tree.
- [ ] No benchmark number has been added that is not in the recorded evidence.
- [ ] Caveats still describe what the benchmarks do and do not show.
- [ ] Tone check: no vendor affiliation implied, no unsupported superiority
      claim, no roadmap.

## 5. Publish

- [ ] The working tree contains only intended files.
- [ ] One clean commit on `main`: `feat: publish orchestrator v1.2 baseline`
      for the first release, or a squash-merged change for later ones.
- [ ] Tag the commit `v<version>`.
- [ ] Create the release, titled `v1.2.0 - First public production baseline` for
      the first release.
- [ ] Attach or link nothing that is not already in the tree.

Steps in this section are the only ones that touch a remote, and they are
deliberately last. See [git-workflow.md](git-workflow.md).
