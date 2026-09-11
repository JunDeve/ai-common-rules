---
name: next-move
description: Reconstruct where a dormant project stopped and propose what to do next, from evidence in the repository. Use when reopening a project after a long gap, inheriting an unfamiliar repository, or when the user asks "where did I leave off", "what should I work on first", or "what was I doing here".
---

# Next Move

Answer two questions about a project nobody has touched in a while: **where did
this stop**, and **what is worth doing next**.

Every other tool here assumes the user already holds the context.
`/improve-codebase-architecture` finds shallow modules but never asks why work
stopped. `writing-plans` starts from a goal already chosen. This skill runs
before them and produces the input they need.

Work through the four stages in order. Do not skip ahead to recommendations —
a candidate that does not trace back to collected evidence is a guess.

## Stage 1 — Static collection

Read-only. No side effects. Run these before forming any opinion.

**git**

```
git log -1 --format='%H %ci %s'
git log -20 --format='%ci %s'
git branch -a --sort=-committerdate --format='%(refname:short) %(committerdate:short)'
git stash list
git status --short
```

For each branch that is not the default one, get its divergence:
`git rev-list --left-right --count <default>...<branch>`. A branch that is far
ahead and months old is usually where the work stopped.

**Code markers**

Find `TODO`, `FIXME`, `HACK`, `XXX`. Date each one with `git blame` on its line
and sort oldest first — an eighteen-month-old `FIXME` says more about the
project than a fresh one.

**Stack**

Detect from marker files, then read the run commands out of the marker file
itself. Never hardcode a command this table does not source.

| Marker file | Commands live in |
|---|---|
| `package.json` | `scripts` |
| `pyproject.toml` | `[tool.*]` sections, `[project.scripts]` |
| `requirements.txt` | no commands — look for `tox.ini`, `pytest.ini`, `Makefile` |
| `go.mod` | conventional `go build ./...`, `go test ./...` |
| `Cargo.toml` | conventional `cargo build`, `cargo test` |
| `pom.xml` | `mvn` lifecycle |
| `build.gradle`, `build.gradle.kts` | `tasks` block |
| `*.csproj`, `*.sln` | `dotnet build`, `dotnet test` |
| `Gemfile` | `Rakefile` tasks |
| `composer.json` | `scripts` |
| `Makefile`, `justfile`, `Taskfile.yml` | target list |

**When no marker file matches, ask.** Do not infer a build command from
directory names or file extensions.

**Docs**

Check what the README claims against what exists — commands it documents,
files it references, features it describes. A README that documents a command
the repo no longer has is itself evidence about when work stopped. Also read
`docs/adr/` for decisions recorded but never acted on, and `CONTEXT.md` if
present.

**CI**

Note whether `.github/workflows/` or equivalent exists. If the `gh` CLI is
available, get recent run results; otherwise record CI status as unknown rather
than assuming it passes.

## Stage 2 — Timeline

Write one paragraph narrating what the evidence shows. Every claim must trace
to a value collected in stage 1.

> Last commit eight months ago. The five commits before it are all on OAuth
> token refresh, and `feat/oauth` sits 3 ahead / 40 behind `master` with two
> stashes on top. Three `FIXME`s in the token path date from the same week.

Do not speculate about intent beyond what the evidence supports. "Work stopped
mid-feature" is a reading of the evidence; "the developer got pulled onto
something else" is not.

## Stage 3 — Execution gate

Static collection cannot tell you whether the project currently builds. Running
it can — but running it has side effects, so it needs approval.

Present the detected commands with their consequences, marked `[CAUTION]`, and
call out dependency installation separately from test execution because it
mutates the working tree:

> `[CAUTION]` 실행 예정
> 1. `npm ci` — 의존성 설치. 네트워크 발생, `node_modules/` 생성. 약 2분.
> 2. `npm test` — 테스트 실행. 부작용 없음.
>
> 거부해도 진행합니다. 빌드·테스트 상태가 "미검증"으로 기록됩니다.

A refusal does not abort the pipeline. Stage 4 proceeds with less evidence, and
`Verified:` in the written document records exactly that. Never report a test
suite as passing when it was not run.

## Stage 4 — Candidates and handoff

Propose exactly three candidates. Each one names the evidence it came from.

| # | Candidate | Evidence | Impact | Cost | Risk |
|---|---|---|---|---|---|
| 1 | Repair the three failing tests | `npm test`: 3 failed in `auth/` | H | S | L |
| 2 | Resume or retire `feat/oauth` | 3 ahead / 40 behind, 8 months old | M | L | M |
| 3 | Migrate the two major-version deps | lockfile vs `package.json` | L | M | H |

Impact, cost, and risk are H/M/L judgments — state the reasoning in one clause
each, do not present them as measurements.

Retiring work is a legitimate candidate. A branch that has fallen 40 commits
behind is often cheaper to delete and redo than to rebase, and saying so is
more useful than listing it as work to resume.

Once the user picks one:

1. Write `PROJECT_STATE.md` to the target project's root (template below).
2. Invoke the `writing-plans` skill with the chosen candidate and the evidence
   behind it.

This skill answers *what to do*. `writing-plans` answers *how*. Do not write
the implementation plan here.

## PROJECT_STATE.md

```markdown
# PROJECT_STATE
<!-- Generated by /next-move. Hand edits are fine. -->

Scanned: YYYY-MM-DD
HEAD-at-scan: <short sha>
Stack: <detected stack, or "undetected — asked user">
Verified: <"static scan only (build and tests not run)" | "build and tests run">

## Where it stopped
(the stage 2 paragraph)

## Evidence
| Item | Value | Source |
|---|---|---|

## Next moves
| # | Candidate | Impact | Cost | Risk | Status |
|---|---|---|---|---|---|
| 1 | ... | H | S | L | chosen |

## Invalidation
HEAD is no longer <short sha> → this document is stale. Do not trust its
contents; re-run /next-move.
```

Two fields carry the weight.

**`Verified:`** records how much was actually checked. When the stage 3 gate is
declined, the file says so. This is what stops a session six months from now
from reading "tests pass" into a document that never ran them.

**`Invalidation`** binds the document's lifetime to the commit it was built
from. `PATTERNS.md` T06 requires verifying that a prior session's decisions are
still valid; comparing current HEAD against the recorded one is that check.

If `PROJECT_STATE.md` already exists when this skill runs, read it first and
compare its `HEAD-at-scan` against current HEAD. Matching means the prior scan
still holds — offer it instead of rescanning. Not matching means it is stale;
overwrite it.
