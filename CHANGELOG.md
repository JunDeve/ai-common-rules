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
