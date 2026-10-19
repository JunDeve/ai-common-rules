# Changelog

All notable changes to this repository are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

Entries are reconstructed from `git log` and `git tag` as far back as the
plugin-based rewrite (`v2.0.0`). History before that (single-file Cursor
rules, pre-`plugin.json`) is not itemized.

> **Note:** `v2.1.0` and `v2.2.0` are declared in `.claude-plugin/plugin.json`
> and installable today, but do not yet have a matching git tag — only
> `v2.0.0` through `v2.0.5` are tagged. A tag-pinned install
> (`claude plugin marketplace add JunDeve/ai-common-rules@vX.Y.Z`) only works
> for tagged versions; see [README.md](README.md#updating-on-demand). Tag
> each release with `claude plugin tag` to close this gap.

## [2.7.1] - 2026-10-19 (untagged)
### Fixed
- **Re-running the installer did not update anything.** An already-registered marketplace is left as it is and `claude plugin install` reuses the cached copy, so `install.bat` / `install.ps1` / `install.sh` could report success while the machine stayed on an old version. They now refresh the marketplaces and run `claude plugin update` for `ai-common-rules`, its dependency and (unless skipped) Superpowers. "Already at the latest" is treated as a normal result. Running the script again is now the one-step update.

## [2.7.0] - 2026-10-19 (untagged)
### Changed
- **Response identifiers are now internal signals and are no longer printed in replies.** `[PLAN]`, `[CAUTION]`, `[CRITICAL]` and `[CONFIDENCE:LOW]` still classify Claude's own actions (and keep the approval and re-approval rules), but the user sees the same meaning in plain words ("Plan: …", "Caution: …", "Stopping: …", "Not sure: …"). The optional identifiers (`[ANALYSIS]`, `[CODE]`, `[INFO]`, `[QUESTION]`, `[REF]`) are not used in replies. `CLAUDE.md` (the self-audit now catches a leaked tag), `/next-move`, `/reverse-port`, `/find-app`, `PLAYWRIGHT.md`, `PATTERNS.md` and both READMEs follow. `[MASKED]` is a redaction placeholder, not an identifier, and is unchanged. `CLAUDE.md` rules version stays v4.2 in number but its text changed; the plugin version carries the release.

## [2.6.0] - 2026-10-19 (untagged)
### Added
- `install.bat` — double-click installer for Windows; wraps `install.ps1` with `-ExecutionPolicy Bypass` and keeps the window open at the end.
- `install.ps1` and `install.sh` now also install Superpowers: they register `obra/superpowers-marketplace` and install `superpowers@superpowers-marketplace` after the main plugin, so one run gives a complete setup. A failure in this step only warns; the `ai-common-rules` install is not rolled back. `-SkipSuperpowers` / `--skip-superpowers` restores the previous two-plugin install.
### Changed
- README Installation, Quick Reference and the start-of-project coverage note describe the new behavior. Superpowers is still not a `dependencies` entry and is not in this marketplace (v2.3.0 stands); the installers add it from its own marketplace.

## [2.5.2] - 2026-10-19 (untagged)
### Changed
Documentation only; no behavior change.
- README Installation gains **Confirm it works** (harness line at session start, skills listed, two plugins enabled, a `.env` read refused) and **What doesn't come with the install** (Claude login, personal `settings.json`, history and memory, `gh auth login`, the optional deny rules, and that a local clone is not the installed plugin).
- The installer paragraph now says what the scripts check: they stop without `claude`, warn about `node`, `python` and `gh`, and turn on auto-update, which the manual steps do not.
- The "verified on Claude Code v2.1.116 and later" note is replaced by what was actually exercised, v2.1.204. Minimum versions for `SessionStart`, `PowerShell` rules, `disallowed-tools` and `disable-model-invocation` are still unchecked.

## [2.5.1] - 2026-10-14 (untagged)
### Fixed
- **Installing the plugin never applied the harness.** Claude Code does not load a `CLAUDE.md` at a plugin's root; the Claude Code docs say so and `claude plugin validate` warns about it on this very repo. The rules (response identifiers, approval workflow, security prompts, token compression) therefore only took effect when this repo was itself the open project, and the README's "injected automatically into every session" was wrong. A `SessionStart` hook (`hooks/scripts/inject_harness.cjs`, matcher `startup|resume|clear|compact`) now prints `CLAUDE.md` and Claude Code adds that to the context. The text names the plugin root so `PATTERNS.md` and `PLAYWRIGHT.md` can be found from any project. Needs Node; without it the harness is silently absent and the session starts normally.
- The negative-feedback hook told Claude to read `PATTERNS.md` and run `scripts/bump_pattern_hits.py` by relative path, which only resolves inside this repo. It now passes absolute paths.
- `scripts/validate.py` fails if a root `CLAUDE.md` exists without the `SessionStart` wiring, or if `CLAUDE.md` outgrows the 10,000-character hook-output cap (it is 4,156 now).
### Changed
- README prerequisites list Python (feedback hook) and the GitHub CLI (`/find-app`); `install.ps1` and `install.sh` warn, without failing, when `node`, `python` or `gh` is missing.
### Known limit
- Installed as a plugin, `PATTERNS.md` and its Hits counts sit in the versioned plugin cache, which Claude Code replaces on update, so they only persist in a checkout. Not redesigned here.

## [2.5.0] - 2026-10-14 (untagged)
### Added
- `/find-app` skill — turns "I want a feature like X" into a ranked list of candidates and ends with a ready `/reverse-port` line. Manual-only (`disable-model-invocation: true`). Searches in a fixed order: open source first (`gh search` plus web, license checked and the feature confirmed in the code, since a real open-source match makes reverse engineering unnecessary), then analyzable apps already installed on the machine (read-only look at install directories, never user data), then other apps known to have the feature (each marked verified or unverified). It finds only: no downloads, installs or clones, and it pre-approves no tools.

## [2.4.2] - 2026-10-14 (untagged)
### Fixed
Three gaps found by testing v2.4.1 on Windows:
- **PowerShell had no security rules.** The hook matchers named only `Bash` and `Read`, so every PowerShell call bypassed them; `Get-Content` on a `.env` file read straight through, and PowerShell is the default shell on Windows. Added a `PowerShell` group mirroring the Bash rules (`Get-Content *.env*`, `Remove-Item *-Recurse*`, `git push --force*`/`-f *`, `git reset --hard*`, `sudo *`, `Start-Process *RunAs*`). `scripts/validate.py` now fails if a Bash group exists without a PowerShell one.
- **The `.env` Read rule only matched under the working directory.** `Read(**/.env*)` follows gitignore semantics, so a `.env` elsewhere on disk passed. Added `Read(//**/.env*)`, the root-anchored form (Windows paths are normalized to `/c/...` first).
- **`/grill-me` wasn't read-only on Windows.** Its `disallowed-tools` named `Bash` but not `PowerShell`, which stayed available (it ran during a test). Added `PowerShell`, and to `validate.py`'s known tools and blanket-pre-approval check.

### Changed
- README Security Hooks lists what the rules still can't stop (argument variants, other ways to read a file, best-effort Grep/Glob coverage) and adds an opt-in `~/.claude/settings.json` deny snippet for hard enforcement. The earlier "deterministic" wording is softened to match.
- Not verified live: `Read(//**/.env*)` and the PowerShell alias canonicalization are from the Claude Code docs, not exercised here.

## [2.4.1] - 2026-10-14 (untagged)
### Fixed
- Security hooks blocked silently: a denied call showed only `No stderr output`. Each deny rule in `hooks/hooks.json` is now paired with an entry that runs `hooks/scripts/explain_block.cjs`, which prints why. The original bare `exit 2` entry stays, because it needs no interpreter and a script-based hook would fail open on a machine without Node (a failed spawn is non-blocking). `scripts/validate.py` fails any rule that loses its bare `exit 2` entry.
- Documented why a legitimate command can be blocked: when Claude Code cannot parse a Bash command with confidence, it runs every `if`-filtered hook anyway. Reproduced with a Python heredoc whose `'''` string contained an apostrophe. Removing the apostrophe made the same command pass.
- Skill tool permissions were set up on a wrong premise. `allowed-tools` **pre-approves** tools for the turn that invokes a skill (no permission prompt); it does not restrict anything. The earlier change used it as if it scoped what each skill could touch, which left `next-move` with a blanket Bash/Write/Edit pre-approval and `grill-me` not actually read-only. Removed the pre-approvals from `next-move`, `frontend-design` and `improve-codebase-architecture`, and gave `grill-me` a real restriction with `disallowed-tools: Write, Edit, NotebookEdit, Bash`.
- `scripts/validate.py` no longer requires `allowed-tools` on every skill. It now rejects a blanket `Bash`/`Write`/`Edit`/`NotebookEdit` pre-approval (a `Bash(...)` pattern is fine) and validates tool names in both `allowed-tools` and `disallowed-tools`.
- README descriptions of `/next-move` said it always invokes `writing-plans`; since v2.3.0 that skill is optional, and the text now says so.

## [2.4.0] - 2026-10-14 (untagged)
### Added
- `/reverse-port` skill — analyzes an existing app, binary or package with [REA](https://github.com/morluto/rea) and ports one feature's behavior into the user's own project. Manual-only (`disable-model-invocation: true`), asks about authorization first, and invokes REA as a pinned one-off `npx -y rea-agents@6.5.0 <command>`. REA is deliberately not a plugin dependency or bundled MCP server: nothing is registered with Claude Code, and the skill does not pre-approve Bash.

## [2.3.0] - 2026-09-27 (untagged)
### Removed
- `superpowers` dropped from `dependencies` and from the marketplace catalog entirely — it no longer installs automatically, and isn't reachable via `@ai-common-rules-marketplace` at all. `superpowers-developing-for-claude-code` is unaffected and still bundled. Install `superpowers` yourself from its own source (`claude plugin marketplace add obra/superpowers`) if you want it.
### Changed
- `skills/next-move/SKILL.md` no longer unconditionally invokes the `writing-plans` skill (from `superpowers`) at handoff — it checks whether the skill is available first and hands the candidate to the user directly otherwise.
- README "Coverage" note reworded: the empty-repo start stage is now an acknowledged gap rather than something `superpowers` fills by default.

## [2.2.0] - 2026-09-11 (untagged)
### Added
- `/next-move` skill — reconstructs where a dormant project stopped from
  repository evidence and proposes what to do next.
- `install.ps1` / `install.sh` — one-command installers that register the
  marketplace, install the plugin with its dependencies, and enable
  background auto-update.
- `scripts/validate.py` + `.github/workflows/validate.yml` — structural CI
  validation (manifest parsing, dependency resolution, SKILL.md frontmatter,
  relative link checks, README section parity).
### Fixed
- Marketplace `autoUpdate` now enabled by default so unattended installs
  stay current.

## [2.1.0] - 2026-09-11 (untagged)
### Added
- Marketplace hub — this repo now curates `superpowers` and
  `superpowers-developing-for-claude-code` as installable dependencies.
### Removed
- MODE system (`[MODE:EXPLORE]` / `[MODE:EXECUTE]` / `[MODE:REVIEW]`) removed
  from `CLAUDE.md`.

## [2.0.5] - 2026-05-22
### Changed
- `CLAUDE.md` lightened — identifiers, PATTERNS, and PLAYWRIGHT rules split
  into their own on-demand files.

## [2.0.4] - 2026-05-20
### Changed
- README rewritten with full role descriptions and usage examples for every
  component.

## [2.0.3] - 2026-05-20
### Added
- Playwright MCP integration (always-on browser control).

## [2.0.2] - 2026-05-18
### Changed
- `CLAUDE.md` consolidated into a single source of truth; the old `.ai/`
  folder removed.

## [2.0.1] - 2026-05-15
### Added
- Desktop app installation guide and initial `plugin.json` manifest.

## [2.0.0] - 2026-05-15
### Changed
- Rewritten as a Claude Code plugin: behavior harness + on-demand skills,
  replacing the earlier single-file Cursor rules setup.
