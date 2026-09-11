# Git workflow

The goal is a history that a reader can trust and skim: one meaningful commit
per accepted change, clean messages, and no reconstructed narrative.

## Branches

`main` holds the latest accepted production baseline. It is not a staging area.
Every commit on `main` should be a state that could be installed and used.

Meaningful changes use a short-lived branch, opened as a pull request and
deleted after merge:

```
feat/root-turn-economy
fix/resume-ownership
docs/install-guide
test/production-cost-case
```

Use `feat/`, `fix/`, `docs/`, `test/`, `chore/`, or `refactor/` as the prefix,
followed by a short hyphenated description. A branch lives for one change. If it
starts containing an unrelated second change, open a second branch.

Rules that matter:

- CI must pass before merge.
- Merge by **squash**, so `main` gains one commit per change.
- Delete the branch after merge.
- Never force-push `main`, and never rewrite published history.

Force-pushing your own short-lived branch is fine while the PR is open and no
one else is building on it.

## Commits

Lightweight Conventional Commits: `feat:`, `fix:`, `docs:`, `test:`, `chore:`,
`refactor:`. Add a scope only when it removes ambiguity, for example
`docs(install): ...`.

Write the subject in the imperative mood and make it readable on its own:

```
feat: add adaptive verifier routing
fix: preserve writer ownership after resume
docs: explain reuse-before-respawn policy
test: add production-cost migration case
chore: refresh release manifest
```

Not acceptable as a subject:

```
update
changes
wip
fix stuff
final
final final
```

Working commits are allowed on a branch. Commit as often as is useful while you
iterate; that messiness stays inside the branch. What reaches `main` is the
squashed commit, and **that** subject is what has to be clean:

```
feat: improve root turn economy (#12)
```

Use the body for the reasoning that the subject cannot carry: what changed, why
this shape, and what it was validated against. Keep it short and specific.

## Pull requests

A PR title should be concise, imperative or descriptive, and understandable
without opening the body. The template asks four questions and nothing else:
what changed, why, how it was validated, and compatibility impact. Answer them
in a few lines.

Architecture changes - delegation rules, ownership rules, role boundaries,
routing - should include the evidence that justifies them, or an explicit note
explaining why evidence was not needed. See
[benchmarking.md](benchmarking.md) and [CONTRIBUTING.md](../CONTRIBUTING.md).

## Initial history policy

Public history starts at **v1.2.0**. The first published commit is:

```
feat: publish orchestrator v1.2 baseline
```

and the first tag is `v1.2.0`, released as `v1.2.0 - First public production
baseline`.

There are deliberately **no** v1.0 or v1.1 commits. That work was internal
development, and reconstructing commits for it after the fact would produce a
history that never happened. The decisions from that period are represented
instead by:

- the ADRs in [decisions/](decisions/), which record what was decided and why;
- the benchmark evidence under [benchmarks/](../benchmarks/), which records what
  was measured;
- [CHANGELOG.md](../CHANGELOG.md), which states plainly that v1.2.0 is the first
  public baseline.

The first public commit should honestly represent the first published baseline,
including the fact that it arrives with documentation, evidence, and validation
tooling already in place.

## Releases

Cutting a release is a checklist rather than a judgement call: confirm the
baseline, validate, refresh the manifest and changelog, re-read the public
surface, publish. See [release-checklist.md](release-checklist.md). None of it
has been executed yet - v1.2.0 is a local release candidate with no history, no
tag, and no published release.
