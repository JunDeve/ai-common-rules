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
| **Harness** | `CLAUDE.md` | Auto-injected rules | Controls how Claude behaves in every session — response identifiers, security guardrails, approval workflow, token compression, anti-pattern tracking |
| **Skill** | `/grill-me` | On-demand slash command | Stress-tests a plan by walking the decision tree one question at a time before any code is written |
| **Skill** | `/improve-codebase-architecture` | On-demand slash command | Finds architectural deepening opportunities — detects shallow modules, proposes refactors, drives collaborative design |
| **Skill** | `/frontend-design` | On-demand slash command | Generates distinctive, production-grade UI by committing to a bold aesthetic direction before coding |
| **Skill** | `/next-move` | On-demand slash command | Reconstructs where a dormant project stopped from repository evidence, then proposes three candidates for what to do next |
| **MCP** | Playwright | Always-on browser control | Lets Claude directly navigate, interact with, and inspect web pages via `browser_*` tools |
| **MCP** | Context7 | Always-on docs lookup | Fetches real-time, version-specific official documentation to prevent hallucinated or deprecated API usage |
| **Dependency** | `superpowers` | Auto-installed plugin | `brainstorm → spec → plan → TDD` execution methodology, systematic debugging, git branch workflow |
| **Dependency** | `superpowers-developing-for-claude-code` | Auto-installed plugin | Skills + bundled official docs for authoring plugins, skills, and MCP servers |

---

## Quick Reference

**Install on a new machine** — clone, then run one script. Nothing else.

```bash
git clone https://github.com/JunDeve/ai-common-rules && cd ai-common-rules
```
```bash
powershell -ExecutionPolicy Bypass -File install.ps1
```

On macOS, Linux, or Git Bash run `./install.sh` instead. Restart Claude Code
afterwards. Details and the manual path: [Installation](#installation).

**Slash commands from this plugin**

| Command | What it does |
|---|---|
| `/next-move` | Reconstructs where a dormant project stopped, proposes three candidates |
| `/grill-me` | Interviews you about a plan until every decision branch is resolved |
| `/improve-codebase-architecture` | Finds shallow modules and proposes deepening refactors |
| `/frontend-design` | Builds UI committed to a deliberate aesthetic direction |

**From the bundled dependencies** — mostly invoked by Claude when the situation
calls for them rather than typed. The ones worth knowing by name:

| Skill | When it takes over |
|---|---|
| `brainstorming` | Before any creative work — turns an idea into an approved design |
| `writing-plans` | Turns an approved design into an implementation plan |
| `test-driven-development` | Before writing implementation code |
| `systematic-debugging` | On any bug or unexpected behavior, before proposing a fix |
| `requesting-code-review` | Before merging |
| `verification-before-completion` | Before claiming anything is done — demands evidence |
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

## Structure

```
ai-common-rules/
├── .claude-plugin/
│   ├── marketplace.json               ← Marketplace catalog (this repo + upstream plugins)
│   └── plugin.json                    ← Plugin manifest + dependencies + MCP servers (Playwright, Context7)
├── install.ps1                        ← One-command installer (Windows PowerShell)
├── install.sh                         ← One-command installer (macOS / Linux / Git Bash)
├── scripts/
│   └── validate.py                    ← Structural checks, run by CI and locally
├── .github/workflows/
│   └── validate.yml                   ← Runs the checks on every push and PR
├── CLAUDE.md                          ← Harness rules (always injected)
├── PATTERNS.md                        ← M/L anti-patterns (on-demand, loaded on negative feedback)
├── PLAYWRIGHT.md                      ← Playwright MCP rules (on-demand, loaded for browser tasks)
└── skills/
    ├── grill-me/
    │   └── SKILL.md                   ← /grill-me slash command
    ├── improve-codebase-architecture/
    │   └── SKILL.md                   ← /improve-codebase-architecture slash command
    ├── frontend-design/
    │   └── SKILL.md                   ← /frontend-design slash command
    └── next-move/
        └── SKILL.md                   ← /next-move slash command
```

---

## Installation

### Prerequisites

| Requirement | Why | Check |
|---|---|---|
| Claude Code CLI | Runs every command below | `claude --version` |
| Node.js + `npx` | Playwright and Context7 MCP servers launch via `npx` | `npx --version` |
| Git over HTTPS to GitHub | The marketplace is cloned and refreshed with `git` | `git ls-remote https://github.com/JunDeve/ai-common-rules` |

Verified on Claude Code v2.1.116 and later.

### One command (recommended)

Clone the repo and run the installer for your shell. It registers the
marketplace, installs the plugin with its dependencies, and prints the
resulting plugin list. Re-running it is safe.

```bash
git clone https://github.com/JunDeve/ai-common-rules && cd ai-common-rules
```

**Windows** — right-click `install.ps1` → *Run with PowerShell*, or:

```bash
powershell -ExecutionPolicy Bypass -File install.ps1
```

**macOS / Linux / Git Bash**

```bash
./install.sh
```

Both check for `claude` on PATH before doing anything, warn (without failing)
when `npx` is missing since the MCP servers need it, and treat an
already-registered marketplace as success rather than an error.

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

`superpowers` and `superpowers-developing-for-claude-code` are declared as `dependencies` in `plugin.json`, so they are fetched and enabled in the same step — you do not install them separately.

**3. Verify**

```bash
claude plugin list
```

Three plugins, all `✔ enabled`, all on `@ai-common-rules-marketplace`:

```
❯ ai-common-rules@ai-common-rules-marketplace                        enabled
❯ superpowers@ai-common-rules-marketplace                            enabled
❯ superpowers-developing-for-claude-code@ai-common-rules-marketplace enabled
```

**4. Restart Claude Code** (or `/reload-plugins`) so the harness and MCP servers load.

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

> A manually uploaded copy does **not** auto-update and does **not** resolve `dependencies` — Superpowers must then be installed separately. Prefer the marketplace route.

---

## Bundled Upstream Plugins

The marketplace links these upstream repos directly — no vendored copies, no submodules. Each stays on its own release line and updates independently.

| Plugin | Upstream | Role |
|---|---|---|
| `superpowers` | [obra/superpowers](https://github.com/obra/superpowers) | `brainstorm → spec → plan → TDD` execution methodology, systematic debugging, git branch workflow |
| `superpowers-developing-for-claude-code` | [obra/superpowers-developing-for-claude-code](https://github.com/obra/superpowers-developing-for-claude-code) | Skills + bundled official docs for authoring plugins, skills, and MCP servers |

To customize one, fork it and swap the `source` URL in `.claude-plugin/marketplace.json` — no structural change needed.

---

## Harness (CLAUDE.md)

Injected automatically into every session when the plugin is enabled. No invocation needed.

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

- **Anti-Pattern Tracking** — On negative feedback, Claude reads `PATTERNS.md` directly and proposes adding the violation. Items with Hits ≥ 3 are reviewed for promotion to the always-on tier in `CLAUDE.md`.

- **Playwright MCP Rules** — Snapshot-first workflow, capability gating, and security guardrails for all `browser_*` tool usage. Full rules in `PLAYWRIGHT.md` (loaded on-demand for browser tasks).

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

**Role:** Reconstructs where a project stopped from repository evidence, then proposes three candidates for what to do next and hands the chosen one to `writing-plans`.

**When to use:** Reopening a project after a long gap, inheriting an unfamiliar repository, or any time the honest answer to "what should I do here?" is "I don't remember."

```
/next-move
```

What happens:

1. **Static collection** — commit cadence, branch divergence, stashes, uncommitted work, dated `TODO`/`FIXME` markers, stack detection from marker files, README claims checked against reality, CI presence. Read-only, no side effects.
2. **Timeline** — one paragraph narrating what the evidence shows. Every claim traces to a collected value; nothing is inferred about intent.
3. **Execution gate** — builds and tests run only after a `[CAUTION]` approval, with dependency installation called out separately because it mutates the working tree. Declining does not abort the scan; it records the reduced confidence instead.
4. **Candidates** — three, each naming the evidence behind it, scored H/M/L on impact, cost, and risk. Retiring stale work counts as a candidate. Picking one writes `PROJECT_STATE.md` and invokes `writing-plans`.

Run commands are read out of whichever marker file was detected rather than hardcoded, so a new ecosystem costs nothing. When no marker file matches, the skill asks instead of guessing.

See [`PROJECT_STATE.md`](#project_statemd) for the artifact it writes and how staleness is decided.

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

## Why Superpowers Is a Dependency, Not a Rival

`ai-common-rules` handles behavior control — approval workflow, response identifiers, security guardrails. It deliberately does not define an execution methodology. Superpowers does, and the two meet at the approval boundary: `/grill-me` validates a plan *before* execution starts, Superpowers picks up *right after* approval, turning an approved `[PLAN]` into a spec, a task breakdown, and test-driven implementation. Zero overlap — which is why it's bundled rather than merely suggested.

### Caveman — Token Compression, cited not copied

The `TOKEN COMPRESSION (Caveman Lite)` rule in `CLAUDE.md` shares its name and core idea — compress the surrounding prose, leave code/commands/paths/errors untouched — with [`JuliusBrussee/caveman`](https://github.com/JuliusBrussee/caveman) (measured at ~65% output / ~33% input token reduction). The difference: caveman is a proxy that compresses both directions for any client; this repo's version is Claude Code-specific output discipline, wired into the response identifiers and Delta Report format rather than sitting in front of the model.

### Claude Mem — deliberately excluded

Claude Mem adds persistent cross-session memory (SQLite + vector store, auto-summarized from tool activity). Skip it if you're already relying on Claude Code's built-in auto-memory system — running both means duplicate context injection and no single source of truth for project state.

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
