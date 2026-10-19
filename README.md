# ai-common-rules

**Claude Code only.** This repo is both a **plugin** and its own **marketplace** — one install brings the behavior harness, the on-demand skills, two always-on MCP servers, and the curated upstream plugins it depends on.

```bash
claude plugin marketplace add JunDeve/ai-common-rules
```
```bash
claude plugin install ai-common-rules@ai-common-rules-marketplace
```

Full walkthrough: [Installation](#installation).

> 한국어 문서: [README.ko.md](README.ko.md)

---

## What's Included

| Component | Name | Type | Role |
|---|---|---|---|
| **Harness** | `CLAUDE.md` | Rules injected at session start by a hook | Controls how Claude behaves in every session — response identifiers, security guardrails, approval workflow, token compression, anti-pattern tracking |
| **Skill** | `/grill-me` | On-demand slash command | Stress-tests a plan by walking the decision tree one question at a time before any code is written |
| **Skill** | `/improve-codebase-architecture` | On-demand slash command | Finds architectural deepening opportunities — detects shallow modules, proposes refactors, drives collaborative design |
| **Skill** | `/frontend-design` | On-demand slash command | Generates distinctive, production-grade UI by committing to a bold aesthetic direction before coding |
| **Skill** | `/next-move` | On-demand slash command | Reconstructs where a dormant project stopped from repository evidence, then proposes three candidates for what to do next |
| **Skill** | `/find-app` | Manual-only slash command | Finds candidates for a feature you want — open-source implementations first, then analyzable apps already installed here, then other apps known to have it — and hands the pick to `/reverse-port` |
| **Skill** | `/reverse-port` | Manual-only slash command | Analyzes an existing app, binary or package with [REA](https://github.com/morluto/rea) from the shipped artifact, then ports one feature's behavior into your own project — after an authorization check |
| **MCP** | Playwright | Always-on browser control | Lets Claude directly navigate, interact with, and inspect web pages via `browser_*` tools |
| **MCP** | Context7 | Always-on docs lookup | Fetches real-time, version-specific official documentation to prevent hallucinated or deprecated API usage |
| **Dependency** | `superpowers-developing-for-claude-code` | Auto-installed plugin | Skills + bundled official docs for authoring plugins, skills, and MCP servers |

---

## What Changes

Two concrete comparisons — illustrative, not benchmarks. No token-count or "X% smaller" numbers appear here: a real one would need the same model, the same task, and several repetitions to be worth trusting, and this README isn't going to publish a number it can't back up. What follows is what actually differs, described plainly instead.

**A file read that shouldn't happen.** Ask an unmodified Claude Code session to read a `.env` file and whether it complies is a judgment call the model makes in the moment. With this plugin installed, the common cases aren't: `hooks/hooks.json`'s `PreToolUse` hooks deny reads of `.env` files before the tool call ever runs, and do the same for `rm -rf`, forced pushes and hard resets, in both Bash and PowerShell (see [Security Hooks](#security-hooks)). Those are pattern rules, so a determined workaround exists, and the section lists exactly where; but the usual request never reaches the model's discretion.

**How a completed task gets reported.** Without a harness, a typical completion reads like *"I've gone ahead and updated the auth module to use JWT tokens instead of sessions! I added expiration validation in src/auth.js and bumped the connection pool size in middleware/session.js. Let me know if you'd like any adjustments!"* — representative prose, not a captured transcript. `CLAUDE.md`'s Delta Report format requires the same completion to look like this instead, taken verbatim from `CLAUDE.md`'s own `GOLDEN EXAMPLES`:

```
Δ
+ src/auth.js L44: JWT 만료 시간 검증 로직 추가
~ middleware/session.js L12: pool size 10→20 변경
Risk: M / Files: 2
```

---

## Quick Reference

**Install on a new machine** — clone, then run one script. Nothing else.

```bash
git clone https://github.com/JunDeve/ai-common-rules && cd ai-common-rules
```
```bash
powershell -ExecutionPolicy Bypass -File install.ps1
```

On Windows you can also just double-click `install.bat`. On macOS, Linux, or Git Bash run `./install.sh` instead.
Each installs `ai-common-rules` **and** Superpowers in one go. Restart Claude Code
afterwards. Details and the manual path: [Installation](#installation).

**Slash commands from this plugin**

| Command | What it does |
|---|---|
| `/next-move` | Reconstructs where a dormant project stopped, proposes three candidates |
| `/find-app` | Finds apps or open-source projects that have a feature you want, then points you at `/reverse-port` |
| `/reverse-port` | Analyzes software you already have with REA, then ports one feature into your project |
| `/grill-me` | Interviews you about a plan until every decision branch is resolved |
| `/improve-codebase-architecture` | Finds shallow modules and proposes deepening refactors |
| `/frontend-design` | Builds UI committed to a deliberate aesthetic direction |

**From the bundled dependency** — invoked by Claude when the situation calls
for it rather than typed:

| Skill | When it takes over |
|---|---|
| `developing-claude-code-plugins` | When working on a plugin, including this one |

**Managing the install**

| Task | Command |
|---|---|
| See what is installed | `claude plugin list` |
| Pull updates now | `claude plugin marketplace update ai-common-rules-marketplace` |
| Remove | `claude plugin uninstall ai-common-rules@ai-common-rules-marketplace` |
| Check the repo itself | `python scripts/validate.py` |

Background updates run on their own once `autoUpdate` is set — the installers
set it. See [Staying current](#staying-current-while-you-leave-the-project-alone).

---

## Recent Changes

Current release: **v2.5.2**. Full history, including everything older: [CHANGELOG.md](CHANGELOG.md).

**2026-10-19**

- **Installation guide filled in** (v2.5.2). New [Confirm it works](#confirm-it-works) checklist and [What doesn't come with the install](#what-doesnt-come-with-the-install) (login, personal settings, history, `gh auth login`, the optional deny rules, the local clone). The installer paragraph now matches what the scripts check, and the "verified on v2.1.116 and later" claim is replaced with what was actually run: v2.1.204.

**2026-10-14**

- **Fixed: the harness was never applied by installing the plugin** (v2.5.1). Claude Code doesn't load a `CLAUDE.md` at a plugin's root, so the rules (identifiers, approval workflow, token compression) only ever took effect when this repo itself was the open project, and the README claiming otherwise was wrong. A `SessionStart` hook now injects it, and `validate.py` checks the wiring and the size. The feedback hook also named `PATTERNS.md` and its script by relative path, which only resolve inside this repo; it now uses absolute paths. Prerequisites now list Python and the GitHub CLI.
- **Added `/find-app`** (v2.5.0). Manual-only skill that finds candidates for a feature you want: open-source implementations first, then analyzable apps already installed on this machine, then other apps known to have it. It ends with a ready `/reverse-port` line. Finds only; downloads and installs nothing.
- **Added `/reverse-port`** (v2.4.0). Manual-only skill that analyzes an app, binary or package you already have with [REA](https://github.com/morluto/rea), then ports one feature's behavior into your project. It asks about authorization first and runs REA as a pinned one-off `npx` command; nothing is registered with Claude Code. See [Related Projects](#related-projects) for why REA is invoked, not bundled.
- **Fixed skill tool permissions.** `allowed-tools` pre-approves tools for the turn, it doesn't restrict them. `next-move`, `frontend-design` and `improve-codebase-architecture` no longer pre-approve Bash/Write/Edit, and `grill-me` is now genuinely read-only through `disallowed-tools`. `validate.py` rejects a blanket Bash/Write/Edit pre-approval from now on.
- **Fixed silent security-hook blocks.** A blocked command used to show only `No stderr output`; it now says why. The deny itself is unchanged and still dependency-free, and `validate.py` enforces that. Commands Claude Code can't parse (typically an odd number of single quotes in a heredoc) are blocked too; the message and [Security Hooks](#security-hooks) explain the workaround.
- **Fixed** `/next-move` docs claiming it always calls `writing-plans`, which stopped being bundled in v2.3.0.
- **Closed three security gaps found by testing on Windows** (v2.4.2). The PowerShell tool had no rules at all, so `Get-Content .env` read straight through; the `.env` Read rule only matched inside the working directory; and `/grill-me` still had PowerShell, so it wasn't read-only. All three are covered now, the README lists what the rules still can't stop, and it includes an opt-in `settings.json` snippet for hard enforcement.

**Earlier**

- 2026-09-27, v2.3.0 — `superpowers` removed as a dependency and from the marketplace.
- 2026-09-14 — security hooks, negative-feedback automation, CHANGELOG, Caveman attribution, skill frontmatter, before/after section.

---

## Structure

```
ai-common-rules/
├── .claude-plugin/
│   ├── marketplace.json               ← Marketplace catalog (this repo + upstream plugins)
│   └── plugin.json                    ← Plugin manifest + dependencies + MCP servers (Playwright, Context7)
├── install.bat                        ← Double-click installer (Windows) — wraps install.ps1
├── install.ps1                        ← One-command installer (Windows PowerShell)
├── install.sh                         ← One-command installer (macOS / Linux / Git Bash)
├── hooks/
│   ├── hooks.json                     ← PreToolUse security + UserPromptSubmit feedback hooks (auto-discovered)
│   └── scripts/
│       ├── explain_block.cjs          ← Prints why a security hook blocked a call (the deny itself is a bare `exit 2`)
│       ├── inject_harness.cjs         ← SessionStart hook body -- puts CLAUDE.md into the session context
│       └── negative_feedback.py       ← UserPromptSubmit hook body -- detects negative feedback, never blocks
├── scripts/
│   ├── validate.py                    ← Structural checks, run by CI and locally
│   └── bump_pattern_hits.py           ← Increments a PATTERNS.md entry's Hits count deterministically
├── .github/workflows/
│   └── validate.yml                   ← Runs the checks on every push and PR
├── CLAUDE.md                          ← Harness rules (injected by the SessionStart hook)
├── PATTERNS.md                        ← M/L anti-patterns (on-demand, loaded on negative feedback)
├── PLAYWRIGHT.md                      ← Playwright MCP rules (on-demand, loaded for browser tasks)
└── skills/
    ├── grill-me/
    │   └── SKILL.md                   ← /grill-me slash command
    ├── improve-codebase-architecture/
    │   └── SKILL.md                   ← /improve-codebase-architecture slash command
    ├── frontend-design/
    │   └── SKILL.md                   ← /frontend-design slash command
    ├── next-move/
    │   └── SKILL.md                   ← /next-move slash command
    ├── find-app/
    │   └── SKILL.md                   ← /find-app slash command (manual-only)
    └── reverse-port/
        └── SKILL.md                   ← /reverse-port slash command (manual-only)
```

---

## Installation

### Prerequisites

| Requirement | Why | Check |
|---|---|---|
| Claude Code CLI | Runs every command below | `claude --version` |
| Node.js + `npx` | Playwright and Context7 MCP servers launch via `npx`; the hooks that inject the harness and explain blocks run on `node`; `/reverse-port` runs REA through `npx` | `npx --version` |
| Python | The negative-feedback hook runs as `python` (it fails silently without it, so only that one feature is lost) | `python --version` |
| GitHub CLI, logged in | `/find-app` searches GitHub with `gh`; optional | `gh auth status` |
| Git over HTTPS to GitHub | The marketplace is cloned and refreshed with `git` | `git ls-remote https://github.com/JunDeve/ai-common-rules` |

Exercised on Claude Code v2.1.204, the only version this has been run on. The hooks, skills and settings used here (`SessionStart`, `PowerShell` rules, `disallowed-tools`, `disable-model-invocation`) were added over time and their minimum versions have not been checked, so treat anything older as untested. An earlier note claimed "v2.1.116 and later"; that was never established for the current feature set.

### One command (recommended)

Clone the repo and run the installer for your shell. It registers the
marketplace, installs the plugin with its dependencies, then registers
`obra/superpowers-marketplace` and installs Superpowers too, and prints the
resulting plugin list. Re-running it is safe. If Superpowers fails to install,
the rest still succeeds. Pass `-SkipSuperpowers` (`--skip-superpowers` for
`install.sh`) to install only `ai-common-rules`.

```bash
git clone https://github.com/JunDeve/ai-common-rules && cd ai-common-rules
```

**Windows** — double-click `install.bat`, or right-click `install.ps1` → *Run with PowerShell*, or:

```bash
powershell -ExecutionPolicy Bypass -File install.ps1
```

**macOS / Linux / Git Bash**

```bash
./install.sh
```

Both check for `claude` on PATH before doing anything and stop if it's missing.
They warn, without failing, when `node`/`npx` (MCP servers and the hook that
injects the harness), `python` (the feedback hook) or `gh` (`/find-app`) is
absent, and they treat an already-registered marketplace as success rather than
an error. They also turn on background auto-update, which the manual steps
below do not: see [Staying current](#staying-current-while-you-leave-the-project-alone).

### Click-only, no terminal

In the Claude desktop app: **Code** tab → **Customize** → **Personal Plugins**,
add `JunDeve/ai-common-rules` as a marketplace, then install `ai-common-rules`
from it. Dependencies resolve the same way they do on the command line.

> Declaring the plugin in `settings.json` alone does **not** work. Claude Code
> adds a marketplace from `extraKnownMarketplaces`, but a plugin whose source is
> an external repository still has to be installed — settings can enable it, not
> fetch it.

### Setting up a new machine, step by step

**1. Register this repo as a marketplace**

```bash
claude plugin marketplace add JunDeve/ai-common-rules
```

Expected tail: `✔ Successfully added marketplace: ai-common-rules-marketplace`.

**2. Install the plugin**

```bash
claude plugin install ai-common-rules@ai-common-rules-marketplace
```

`superpowers-developing-for-claude-code` is declared as a `dependencies` entry in `plugin.json`, so it's fetched and enabled in the same step — you do not install it separately.

**3. Verify**

```bash
claude plugin list
```

The two plugins from this marketplace, both `✔ enabled`:

```
❯ ai-common-rules@ai-common-rules-marketplace                        enabled
❯ superpowers-developing-for-claude-code@ai-common-rules-marketplace enabled
```

Superpowers is not part of this marketplace. The installer scripts add it separately; to do the same by hand:

```bash
claude plugin marketplace add obra/superpowers-marketplace
```
```bash
claude plugin install superpowers@superpowers-marketplace
```

Then `claude plugin list` shows a third entry, `superpowers@superpowers-marketplace`.

**4. Restart Claude Code** (or `/reload-plugins`) so the harness and MCP servers load.

### Confirm it works

After the restart, check these in a fresh session:

- **The harness is active.** The start of the session shows a `SessionStart:<matcher> hook success: ai-common-rules harness, injected by the plugin's SessionStart hook…` line (seen on resume; the `startup` variant is expected to look the same). If it's missing, check that `node --version` works; the injector needs Node and fails silently without it.
- **The skills are there.** `/grill-me`, `/next-move`, `/find-app`, `/reverse-port`, `/frontend-design` and `/improve-codebase-architecture` appear when you type `/`, possibly shown with an `ai-common-rules:` prefix.
- **The plugins are enabled.** `claude plugin list` shows each `✔ enabled`: two from `@ai-common-rules-marketplace`, plus `superpowers@superpowers-marketplace` if you used the installer or added it by hand.
- **The security hooks fire.** Ask Claude to read a `.env` file inside a project; the call should be refused with `ai-common-rules hook blocked this Read`. If Claude declines before making the call, that is the harness rule working instead of the hook.

### What doesn't come with the install

The plugin carries the skills, hooks, harness rules and MCP server definitions. A new machine still has to supply the rest itself:

- **Your Claude login** and anything in your own `~/.claude/settings.json`, such as theme. The installers add only the marketplace entry (with auto-update) and the enabled plugins.
- **Conversation history and any saved memory.** Both are per machine.
- **`gh auth login`.** `/find-app` needs a logged-in GitHub CLI; the plugin can't log in for you.
- **The optional deny rules.** The `permissions.deny` snippet in [Security Hooks](#security-hooks) lives in your own settings file and isn't installed for you.
- **A local clone of this repo, unless you develop it.** The clone only supplies the installer scripts. The installed plugin is a separate copy under `~/.claude/plugins`, updated by `claude plugin update` or auto-update, not by `git pull`.

### Migrating a machine that has an older setup

Uninstall first, then install — two plugins with the same name from different marketplaces will both load and double up their skills.

```bash
claude plugin uninstall ai-common-rules@local-desktop-app-uploads
```
```bash
claude plugin uninstall superpowers@superpowers-marketplace
```
```bash
claude plugin marketplace remove superpowers-marketplace
```
```bash
claude plugin marketplace remove local-desktop-app-uploads
```

Also uninstall `superpowers` if a version 2.2.0-or-earlier install pulled it in as a dependency — since v2.3.0 it's no longer bundled:

```bash
claude plugin uninstall superpowers@ai-common-rules-marketplace
```

Then run the *Setting up a new machine* steps above.

> **Windows PowerShell 5.1:** `&&` is not a valid statement separator — `'&&' 토큰은 이 버전에서 올바른 문 구분 기호가 아닙니다.` Run each command on its own line, or chain with `;` / `if ($?) { ... }`.

### Staying current while you leave the project alone

Linking upstream repos instead of vendoring them only pays off if the links
actually move. **Third-party marketplaces ship with auto-update turned off**, so
a fresh install updates nothing until someone runs an update by hand — which is
exactly what a dormant project never gets.

The installers turn it on. If you set things up manually, add `autoUpdate` to
the marketplace entry in `~/.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "ai-common-rules-marketplace": {
      "source": { "source": "github", "repo": "JunDeve/ai-common-rules" },
      "autoUpdate": true
    }
  }
}
```

With that set, Claude Code refreshes the marketplace and updates installed
plugins in the background shortly after each session starts — this plugin and
both upstream dependencies, with no command from you.

> **Why not git submodules?** A submodule pins a fixed commit. Advancing it
> means running `git submodule update --remote`, committing, and pushing — by
> hand, forever, and cloning needs `--recursive`. That is the opposite of
> staying current unattended. Marketplace `source` links carry no pinned SHA, so
> the upstream's own releases flow through on their own.

### Updating on demand

To pull immediately rather than waiting for the background refresh:

```bash
claude plugin marketplace update ai-common-rules-marketplace
```
```bash
claude plugin update ai-common-rules@ai-common-rules-marketplace
```

Bump `version` in `.claude-plugin/plugin.json` on every release — Claude Code skips an update when the resolved version matches what is cached. See [CHANGELOG.md](CHANGELOG.md) for what changed in each release; the plugin's `version` and the `AI AGENT CORE RULES vX.Y` number at the top of `CLAUDE.md` track separately — the harness rules can revise without a plugin release and vice versa.

To track a fixed tag instead of the default branch:

```bash
claude plugin marketplace add JunDeve/ai-common-rules@v2.0.5
```

Only tagged releases can be pinned this way — check `git tag -l` in this repo for what's currently tagged. Newer `plugin.json` versions without a matching tag (see the note at the top of [CHANGELOG.md](CHANGELOG.md)) can only be installed by tracking the default branch. Maintainers: tag each release with `claude plugin tag`.

### Uninstalling

```bash
claude plugin uninstall ai-common-rules@ai-common-rules-marketplace
```
```bash
claude plugin prune
```

`prune` removes the two dependencies once nothing requires them. `claude plugin marketplace remove ai-common-rules-marketplace` drops the catalog entry too.

### Local development

Load the working copy directly, without installing:

```bash
claude --plugin-dir <path-to-ai-common-rules>
```

### Claude Desktop App (manual upload)

Only when GitHub is unreachable. Zip the folder (must include `.claude-plugin/plugin.json`), then **Code** tab → **Customize** → **Personal Plugins +** → **Upload Plugin**.

> A manually uploaded copy does **not** auto-update and does **not** resolve `dependencies` — `superpowers-developing-for-claude-code` must then be installed separately. Prefer the marketplace route.

---

## Bundled Upstream Plugins

The marketplace links this upstream repo directly — no vendored copy, no submodule. It stays on its own release line and updates independently.

| Plugin | Upstream | Role |
|---|---|---|
| `superpowers-developing-for-claude-code` | [obra/superpowers-developing-for-claude-code](https://github.com/obra/superpowers-developing-for-claude-code) | Skills + bundled official docs for authoring plugins, skills, and MCP servers |

To customize one, fork it and swap the `source` URL in `.claude-plugin/marketplace.json` — no structural change needed.

---

## Harness (CLAUDE.md)

Active in every session once the plugin is enabled. No invocation needed.

**How it gets there.** Claude Code does not load a `CLAUDE.md` that sits at a plugin's root (`claude plugin validate` warns about exactly that), so installing this plugin alone never applied these rules. A `SessionStart` hook (`hooks/scripts/inject_harness.cjs`) prints the file and Claude Code adds that output to the context at session start, on resume, after `/clear`, and after compaction. Output is capped at 10,000 characters, so `scripts/validate.py` fails if `CLAUDE.md` outgrows it. The hook needs Node; without it the session starts normally and the harness is silently absent. The injected text tells Claude where the plugin lives, so the on-demand files the rules name (`PATTERNS.md`, `PLAYWRIGHT.md`) can be found from any project. Opening this repo itself loads `CLAUDE.md` twice, once as the project's own file and once through the hook; that is harmless.

### What it does

- **Response Identifiers** — Required identifiers enforce explicit intent on critical actions; optional identifiers add clarity when helpful

**Required (must be used when condition is met):**

| Identifier | When used |
|---|---|
| `[PLAN]` | Unexecuted plan, awaiting user approval |
| `[CAUTION]` | Before any destructive action — re-approval required |
| `[CRITICAL]` | Security threat — immediate stop |
| `[CONFIDENCE:LOW]` | High reasoning uncertainty |

**Optional (used when clarity is needed):**
`[ANALYSIS]` `[CODE]` `[INFO]` `[QUESTION]` `[REF]`

- **Approval Workflow** — Claude reports purpose, target files, blast radius, and security check before acting. Execution only starts after explicit user approval.

- **Security Guardrails** — API keys and secrets masked (`[MASKED]`), system paths blocked (`[CRITICAL]`), 5+ file changes require `[CAUTION]` and a Git checkpoint recommendation.

- **Token Compression (Caveman Lite)** — Drops articles, fillers, and pleasantries. Uses fragments, abbreviations, and causal arrows. Suspended inside `[CAUTION]`/`[CRITICAL]` blocks for clarity. Name and approach cited from [`JuliusBrussee/caveman`](https://github.com/JuliusBrussee/caveman) — see [below](#caveman--token-compression-cited-not-copied) for how the two differ.

- **Anti-Pattern Tracking** — On negative feedback, Claude reads `PATTERNS.md` directly and proposes adding the violation. Items with Hits ≥ 3 are reviewed for promotion to the always-on tier in `CLAUDE.md`. Detection is a `hooks/hooks.json` `UserPromptSubmit` hook (regex, Korean and English) rather than something Claude has to remember to notice; the Hits count itself is incremented by `scripts/bump_pattern_hits.py`, not hand-edited. **Known limit:** installed as a plugin, `PATTERNS.md` and its Hits live in the plugin's versioned cache directory, which Claude Code replaces on update, so counts only persist in a checkout. Not redesigned yet.

- **Playwright MCP Rules** — Snapshot-first workflow, capability gating, and security guardrails for all `browser_*` tool usage. Full rules in `PLAYWRIGHT.md` (loaded on-demand for browser tasks).

---

## Security Hooks

The `## SECURITY` rules in `CLAUDE.md` are prompt instructions — Claude can violate them if it misjudges a situation. The rules below instead block before the tool call runs, via `hooks/hooks.json`'s `PreToolUse` hooks. A plugin cannot ship this through `settings.json` (Claude Code only reads the `agent`/`subagentStatusLine` keys from a plugin's own `settings.json`); `hooks/hooks.json` is the supported mechanism, auto-discovered by file convention with no `plugin.json` change needed.

(`hooks/hooks.json` also carries a `UserPromptSubmit` hook unrelated to blocking — see Anti-Pattern Tracking above.)

| Blocked pattern | Backs which `CLAUDE.md` rule |
|---|---|
| `Read(**/.env*)`, `Read(//**/.env*)` | Zero-Exfiltration |
| `Bash(cat *.env*)`, `Bash(type *.env*)`, `PowerShell(Get-Content *.env*)` | Zero-Exfiltration |
| `Bash(rm -rf *)`, `PowerShell(Remove-Item *-Recurse*)` | Destructive Gate / Anti-Pattern T05 |
| `git push --force*` and `git push -f *`, in Bash and PowerShell | Destructive Gate |
| `git reset --hard*`, in Bash and PowerShell | Destructive Gate |
| `Bash(sudo *)`, `PowerShell(sudo *)`, `PowerShell(Start-Process *RunAs*)` | Destructive Gate |

PowerShell is a separate tool from Bash and the default shell on Windows, so a Bash-only matcher leaves every PowerShell call outside the rules; `scripts/validate.py` fails if a Bash group exists without a PowerShell one. Claude Code canonicalizes PowerShell aliases before matching, so the `Get-Content` rule is meant to cover `cat`, `type` and `gc` too. There are two `Read` rules because the first (`**/.env*`) only matches at or under the working directory, as gitignore-style patterns do; `//**/.env*` is the anchored-at-root form that matches anywhere on disk. On Windows, paths are normalized to POSIX form first (`C:\Users\x` becomes `/c/Users/x`).

Each rule has two entries. The first denies unconditionally (`exit 2`) rather than running a script to decide, deliberately: the `if` matcher already narrows to an exact pattern, and an inline command has to work identically whether Claude Code runs it through Git Bash or PowerShell (Windows without Git Bash falls back to PowerShell) — `exit <code>` is the only construct guaranteed to mean the same thing in both. It also needs no interpreter, so the rule still blocks on a machine without Node. A script-based hook would fail *open* there, because a failed spawn is non-blocking.

The second entry runs `hooks/scripts/explain_block.cjs`, which prints why the call was blocked to stderr. Without it a block shows only `No stderr output`. `scripts/validate.py` fails any rule left without its bare `exit 2` entry.

**When a command is blocked and shouldn't be.** If Claude Code cannot parse a Bash command with confidence, it runs every `if`-filtered hook anyway, so the deny rules fail closed. The usual trigger is an odd number of unquoted single quotes inside a heredoc, for example a Python `'''` string containing an apostrophe. Simplify the command, or write the script to a file first and run that.

**What these rules don't stop.** They match patterns, and Claude Code's own docs call the `if` filter best-effort and recommend the permission system for a hard deny. In practice:

- Argument variants slip through: `rm -fr`, split flags, an abbreviated PowerShell parameter such as `Remove-Item -r`.
- Other ways to read a `.env` aren't covered: `head`, `grep`, `Select-String`. Claude Code applies `Read` rules to Grep and Glob only on a best-effort basis.
- The `.env` rule outside the working directory (`//**/.env*`) and the PowerShell alias handling are taken from the docs and were not exercised live here. The Bash and in-directory `Read` rules were.

**Hard enforcement is yours to opt into.** A plugin can't ship `permissions` (see above), but you can add deny rules to your own `~/.claude/settings.json`. The permission system, unlike an `if` filter, is what Claude Code enforces. This repo doesn't write your settings. The syntax comes from the permissions docs and has not been tested here:

```json
{
  "permissions": {
    "deny": [
      "Read(//**/.env*)",
      "Bash(rm -rf *)",
      "Bash(git push --force*)",
      "Bash(git push -f *)",
      "Bash(git reset --hard*)",
      "PowerShell(Remove-Item *-Recurse*)",
      "PowerShell(git push --force*)",
      "PowerShell(git push -f *)",
      "PowerShell(git reset --hard*)"
    ]
  }
}
```

---

## Skills

Skills are slash commands — inactive until explicitly invoked.

### `/grill-me`

**Role:** Stress-tests a plan before execution. Prevents premature `[PLAN]` submissions by walking every branch of the decision tree.

**When to use:** Before starting any non-trivial task. Invoke it, describe what you're planning to do, and Claude will interview you — one focused question at a time — until all decision branches are resolved.

```
/grill-me
I'm planning to refactor the auth module to use JWT instead of sessions
```

What happens:
1. Claude asks one question at a time about your plan (scope, risks, alternatives, edge cases)
2. Provides a recommended answer for each question
3. Explores the codebase to answer questions it can verify itself
4. Continues until the full decision tree is resolved

---

### `/improve-codebase-architecture`

**Role:** Finds architectural deepening opportunities in a codebase. Detects shallow modules, proposes refactors, and drives collaborative design using domain language.

**When to use:** When a codebase feels hard to navigate, has tightly coupled modules, or you want to improve testability and long-term maintainability.

```
/improve-codebase-architecture
```

What happens:
1. Reads `CONTEXT.md` (domain glossary) and `docs/adr/` (architecture decisions) if they exist
2. Identifies deepening candidates — modules with low interface leverage
3. Presents candidates with files, problem, proposed solution, and benefits
4. Grilling loop: you pick a candidate → Claude walks the design tree with you
5. Side effects: unknown terms added to `CONTEXT.md`, rejected candidates proposed as ADRs in `docs/adr/`

On first run, these are auto-created in your project:
- `CONTEXT.md` — domain glossary
- `docs/adr/` — architecture decision records

---

### `/frontend-design`

**Source:** Adapted from Anthropic's official `frontend-design` skill, unlike the other five skills in this repo, which are original. Bundled inline rather than linked upstream like `superpowers-developing-for-claude-code` (see [Bundled Upstream Plugins](#bundled-upstream-plugins)) since Anthropic doesn't distribute it as its own plugin repo.

**Role:** Generates distinctive, production-grade UI by committing to a bold aesthetic direction before writing any code. Avoids generic AI defaults (Inter font, purple gradients, predictable layouts).

**When to use:** Any time you need a UI component, page, or full application built with intentional design rather than statistical-median aesthetics.

```
/frontend-design
Build a login page, React-based
```

What happens:
1. Claude analyzes purpose, audience, and constraints
2. Commits to a specific aesthetic direction (e.g., brutalist, retro-futuristic, editorial) before coding
3. Outputs production-ready code (HTML/CSS/JS, React, Vue, etc.) with distinctive typography, color, motion, and layout
4. Each generation intentionally varies — no two outputs converge on the same style

---

### `/next-move`

**Role:** Reconstructs where a project stopped from repository evidence, then proposes three candidates for what to do next and hands the chosen one to a planning skill such as `writing-plans` (from `superpowers`, not bundled) if one is installed — otherwise to you directly.

**When to use:** Reopening a project after a long gap, inheriting an unfamiliar repository, or any time the honest answer to "what should I do here?" is "I don't remember."

```
/next-move
```

What happens:

1. **Static collection** — commit cadence, branch divergence, stashes, uncommitted work, dated `TODO`/`FIXME` markers, stack detection from marker files, README claims checked against reality, CI presence. Read-only, no side effects.
2. **Timeline** — one paragraph narrating what the evidence shows. Every claim traces to a collected value; nothing is inferred about intent.
3. **Execution gate** — builds and tests run only after a `[CAUTION]` approval, with dependency installation called out separately because it mutates the working tree. Declining does not abort the scan; it records the reduced confidence instead.
4. **Candidates** — three, each naming the evidence behind it, scored H/M/L on impact, cost, and risk. Retiring stale work counts as a candidate. Picking one writes `PROJECT_STATE.md` and invokes `writing-plans` if that skill is available; otherwise the candidate and its evidence go straight back to you.

Run commands are read out of whichever marker file was detected rather than hardcoded, so a new ecosystem costs nothing. When no marker file matches, the skill asks instead of guessing.

See [`PROJECT_STATE.md`](#project_statemd) for the artifact it writes and how staleness is decided.

### `/find-app`

**Role:** Turns "I want a feature like X" into a short, ranked candidate list, so you don't have to know which app to analyze before you start `/reverse-port`.

**When to use:** You know what you want but not where it already exists. Manual-only (`disable-model-invocation`).

```
/find-app
a drag-to-reorder kanban board that works offline
```

It searches in a fixed order and stops early only on a strong open-source match:

1. **Open source first** — `gh search` plus web search, checking each candidate's license and that the feature is really implemented, not just described. If a real match exists, read its source; no reverse engineering needed and the license question is much simpler.
2. **Installed here** — a read-only look at application install directories (never user data) for apps worth analyzing, each rated for how analyzable REA finds it: Electron and .NET are easy, native code needs Ghidra.
3. **Other known apps** — web evidence only, each marked *verified* (page opened and it shows the feature) or *unverified*.

You get a table of up to six candidates and one ready line: `/reverse-port <app> — <feature>`. `/reverse-port` is manual-only, so you type that line yourself. This skill only finds: it downloads, installs and clones nothing, and pre-approves no tools, so every command prompts as usual. Its limit is the same as any web search's — for closed-source apps the quality of the list depends on what the search turns up, which is why every claim carries a source.

### `/reverse-port`

**Role:** Takes software you already have — an app, a binary, a package — figures out how one feature works from the shipped artifact with [REA](https://github.com/morluto/rea), and ports that behavior into your own project.

**When to use:** You want to understand and re-implement something you can run but can't read the source of. Manual-only (`disable-model-invocation`): Claude never starts it on its own.

```
/reverse-port
Find how the export dialog builds its file in /path/to/app and port it to this project
```

What happens:

1. **Authorization gate** — asks whether the target is yours or you're licensed to analyze it. If it's third-party proprietary software, the work stays at the level of behavior (inputs, outputs, edge cases, formats), never code or assets. Bypassing DRM, license checks, anti-cheat or access controls ends the run.
2. **Runtime gate** — REA runs as a pinned one-off `npx -y rea-agents@6.5.0 <command>`. Static commands never execute the target; anything that does, attaches to a debug port, uses `adb` or captures traffic needs a `[CAUTION]` approval first. No Bash pre-approval, so every command still prompts.
3. **Evidence report** — each claim tied to a module, function or path from REA's output and marked observed or inferred, with REA's own unknowns passed along.
4. **Port** — behavior spec first, then a `[PLAN]` for your project, then a fresh implementation. For third-party targets nothing extracted is pasted in.

REA is not bundled and nothing is registered with Claude Code; see [Related Projects](#related-projects) for why. Target routing (JavaScript/Electron, .NET, SQLite, Go, Rust, native) is in the skill itself. On Windows, native analysis needs Ghidra already installed, and several REA workflows are Linux-only.

### Coverage: where these skills don't reach

```
[start] ── [design] ────── [implement] ───────── [refactor] ──────────── [handoff]
   ?      grill-me     frontend-design      improve-codebase-...        next-move
```

Starting from an empty repo — no plan, no existing code to react to — isn't covered by any skill in this repo. `superpowers` (whose `brainstorming` skill covers exactly this) isn't bundled in this plugin or its marketplace as of v2.3.0, but since v2.6.0 the installers (`install.bat` / `install.ps1` / `install.sh`) install it from its own marketplace, `obra/superpowers-marketplace`, as a separate plugin. If you installed by hand instead, add it with `claude plugin marketplace add obra/superpowers-marketplace` then `claude plugin install superpowers@superpowers-marketplace`, or start from a plan you already have in hand.

---

## MCP Servers (Always-On)

Both are bundled in `plugin.json` and start automatically when the plugin is enabled. No separate install or API key needed.

### Playwright

**Role:** Gives Claude direct browser control — navigate pages, click elements, fill forms, take screenshots, and inspect accessibility trees.

**How it works:** Uses snapshot mode by default (accessibility tree → ref-based interaction, ~300 tokens). Screenshot/vision mode only for canvas or SVG UIs where the accessibility tree is unavailable.

| Tool category | Examples |
|---|---|
| Navigation | `browser_navigate`, `browser_navigate_back` |
| Interaction | `browser_click`, `browser_fill`, `browser_type`, `browser_select_option` |
| Inspection | `browser_snapshot` (recommended), `browser_take_screenshot` |
| Utilities | `browser_wait_for`, `browser_evaluate`, `browser_close` |

Standard workflow: `browser_navigate` → `browser_snapshot` → interact via refs → `browser_snapshot` → repeat → `browser_close`

Harness rules (snapshot priority, capability gating, security guardrails) are enforced automatically via `CLAUDE.md`.

### Context7

**Role:** Fetches real-time, version-specific official documentation for any library or framework Claude is working with. Prevents hallucinated props, deprecated APIs, and version mismatches.

**How it works:** When Claude writes code involving a known library (React, Next.js, Tailwind, etc.), Context7 queries the live registry and injects the correct API reference into context before generating code.

No configuration needed. Works out of the box.

---

## Planning & Task Tracking

Planning and task tracking stay on Claude Code built-ins. The one file this
plugin writes is `PROJECT_STATE.md`, and it is an output of `/next-move`, not a
running log — nothing appends to it during normal work.

| Role | Tool |
|---|---|
| Planning | Claude Code Plan Mode |
| Task tracking | TodoWrite |
| Reorienting in a dormant project | `/next-move` |
| Plan stress-testing | `/grill-me` |
| Architecture improvement | `/improve-codebase-architecture` |
| UI generation | `/frontend-design` |

### `PROJECT_STATE.md`

Written to the target project's root when `/next-move` finishes a scan. It
records where work stopped, the evidence behind that reading, the candidates
proposed, and which one was chosen.

Two fields decide whether a later session should trust it:

- `Verified:` — how much was actually checked. If the execution gate was
  declined, the file says the build and tests were never run, so a later
  session cannot read a passing suite into a document that never ran one.
- `Invalidation` — the commit the scan was built from. When current HEAD no
  longer matches, the document is stale and `/next-move` should be re-run.

This is what makes `PATTERNS.md` T06 executable: the rule requires verifying a
prior session's decisions are still valid, and comparing HEAD is that check.

---

## Related Projects

### Caveman — Token Compression, cited not copied

The `TOKEN COMPRESSION (Caveman Lite)` rule in `CLAUDE.md` shares its name and core idea — compress the surrounding prose, leave code/commands/paths/errors untouched — with [`JuliusBrussee/caveman`](https://github.com/JuliusBrussee/caveman) (measured at ~65% output / ~33% input token reduction). The difference: caveman is a proxy that compresses both directions for any client; this repo's version is Claude Code-specific output discipline, wired into the response identifiers and Delta Report format rather than sitting in front of the model.

### Claude Mem — deliberately excluded

[`thedotmack/claude-mem`](https://github.com/thedotmack/claude-mem) has rebranded upstream to "Grok Mem" (package still published as `claude-mem`), broadening from Claude Code specifically to agents generally — the exclusion judgment below isn't about that name, and holds regardless of it.

Claude Mem/Grok Mem adds persistent cross-session memory (SQLite + vector store, auto-summarized from tool activity). Skip it if you're already relying on Claude Code's built-in auto-memory system — running both means duplicate context injection and no single source of truth for project state. Excluding a memory layer only holds up if this repo's own substitute is solid: `PATTERNS.md`'s feedback loop is no longer prompt-only either (see [Anti-Pattern Tracking](#harness-claudemd)) — detection and Hits-counting are now hook-enforced, not something Claude has to remember to do on its own.

### REA — analysis engine, invoked not bundled

`/reverse-port` drives [`morluto/rea`](https://github.com/morluto/rea) (`rea-agents` on npm, MIT) through `npx -y rea-agents@6.5.0`. It is deliberately neither a plugin dependency nor a bundled MCP server like Playwright and Context7:

- **Weight.** Its MCP surface is 172 tools; REA's own measurement is about 496 KB of tool definitions (about 290 KB with its `compact` profile) when a client doesn't defer them. Registering that in every session works against this harness's token discipline, and a one-off CLI call costs nothing until used.
- **Risk class.** It can execute targets, attach debuggers, capture traffic and drive Android devices. Its own [SECURITY.md](https://github.com/morluto/rea/blob/rea-agents-6.5.0/SECURITY.md) says it is not a sandbox, and the `hooks/hooks.json` deny rules only cover the Bash tool, not MCP calls.
- **Provenance.** One maintainer does most of the work and the npm package dates from July 2026. This repo has not audited its code; it only checked that the published package declares no install scripts. The pin is manual on purpose: bump it after reading the release notes, not automatically.

REA's [DISCLAIMER](https://github.com/morluto/rea/blob/rea-agents-6.5.0/DISCLAIMER.md) excludes copying proprietary software, DRM and license circumvention, and unauthorized access. `/reverse-port` asks about authorization first for the same reason.

---

## Development

This repo ships markdown and JSON, so nothing compiles and there is no test
suite. What breaks instead is structural, and `scripts/validate.py` checks for
exactly that:

```bash
python scripts/validate.py
```

| Check | Catches |
|---|---|
| Manifests parse; marketplace lists this plugin | A malformed `plugin.json` or `marketplace.json` that fails at install time |
| Every `dependencies` entry resolves in the marketplace | A bare-name dependency pointing at nothing, which fails on the user's machine rather than here |
| Each `SKILL.md` has parseable frontmatter with `name` matching its directory | A skill that silently stops being invocable as `/<name>` |
| Relative `.md` links resolve | Docs pointing at files that were never written |
| Both READMEs have the same section count | A section added to one README and forgotten in the other |

`.github/workflows/validate.yml` runs this on every push to `master` and every
pull request, plus a second step that re-reads the manifests the way Claude Code
does when it clones this repo as a marketplace.

Every check exists because that mistake actually reached `master` at least once.
