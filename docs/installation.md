# Installation

Installation copies files into your own Codex/OpenCodex configuration. It does not
call any model, does not change routing configuration, and does not touch
provider credentials.

## Requirements

- Windows with Windows PowerShell 5.1 or later (PowerShell 7 works as well).
- OpenCodex multi-agent runtime **v1**, which is the accepted baseline.
- Codex with custom agent support, so that worker TOMLs under
  `%USERPROFILE%\.codex\agents\` are discovered.

## Target layout

| Source in this repository | Installed location |
| --- | --- |
| `orchestrator\SKILL.md` | `%USERPROFILE%\.agents\skills\orchestrator\SKILL.md` |
| `orchestrator\agents\openai.yaml` | `%USERPROFILE%\.agents\skills\orchestrator\agents\openai.yaml` |
| `orchestrator\references\*.md` | `%USERPROFILE%\.agents\skills\orchestrator\references\*.md` |
| `agents\*.toml` | `%USERPROFILE%\.codex\agents\*.toml` |

Five worker files are expected at the destination:

```
code-mapper.toml
implementer.toml
verifier.toml
reviewer.toml
debugger.toml
```

## Install

```
git clone <your-fork-or-remote>
cd codex-orchestrator

.\scripts\Install-Orchestrator.ps1 -WhatIf    # dry run: prints what would change
.\scripts\Install-Orchestrator.ps1            # install
```

The script refuses to run if a required source file is missing, backs up every
existing target file before replacing it, and prints the installed path and
SHA-256 for each file. It writes only to the two directories above.

Useful parameters:

```
.\scripts\Install-Orchestrator.ps1 -SkillsRoot <path> -AgentsRoot <path>
```

The defaults are `%USERPROFILE%\.agents\skills` and `%USERPROFILE%\.codex\agents`.

## Verify

Compare the repository source against what is installed:

```
.\scripts\Compare-Installed.ps1
```

It reports each file as identical, modified, missing, or extra, and never writes
anything. Validate the repository itself with:

```
.\scripts\Test-Repository.ps1
```

Test-Repository.ps1 checks required files, TOML structure, worker model
neutrality, references, local Markdown links, personal-data and secret patterns,
the release manifest, JSON parsing, YAML structure, and the recorded benchmark
values. It prints one line per check and exits non-zero if any of them fail.

## Release manifest

`manifests\v<version>.sha256` pins every file in the production source set: the
skill entry point, its four references, the skill metadata file
`orchestrator\agents\openai.yaml`, and the five worker TOMLs. That is the set the
install script copies, so a file that ships without a hash would be a file that
nothing verifies.

```
.\scripts\New-ReleaseManifest.ps1 -WhatIf   # print the manifest
.\scripts\New-ReleaseManifest.ps1           # rewrite manifests\v<version>.sha256
```

The format is standard `sha256sum` output, so a pinned set can also be checked
without PowerShell. See [manifests/README.md](../manifests/README.md).

## The three layers, kept separate

| Layer | What it is | Where it lives |
| --- | --- | --- |
| Role definitions | Who a worker is, what it may do, what it must refuse | `agents\*.toml`, `orchestrator\SKILL.md` |
| Routing configuration | Which model and effort runs an already-chosen role | `orchestrator\references\model-routing.md` |
| Provider credentials and authentication | Your accounts, tokens, and provider access | Your own Codex/OpenCodex configuration |

This repository ships the first two and never the third.

## Routing prerequisites

Routing names specific providers and models. Before expecting the validated
baseline to behave as documented, confirm that:

- the OpenCode Go provider is reachable and the routed models are available to it;
- the native ChatGPT/Codex model used by the Verifier route is available;
- agent discovery picks up all five worker TOMLs;
- the root model and effort match the [routing table](model-routing.md), or you
  are deliberately overriding it.

If a route is unavailable, the root decides an explicit fallback rather than
substituting silently. See [model-routing.md](model-routing.md).

## Credentials

Never store credentials in this repository, in a worker TOML, or in the routing
reference. Worker contracts intentionally contain no authentication material and
no provider secrets. If your environment needs a token, it belongs in your own
provider configuration, outside this repository.

## Uninstalling

Remove `%USERPROFILE%\.agents\skills\orchestrator\` and the five worker TOMLs
under `%USERPROFILE%\.codex\agents\`. Backups written by the install script
remain next to the files they replaced.
