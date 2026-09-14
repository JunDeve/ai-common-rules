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
