# ai-common-rules

**Claude Code only.** A single plugin that bundles a behavior harness, on-demand skills, and always-on MCP servers into one install.

> 한국어 문서: [README.ko.md](README.ko.md)

---

## What's Included

| Component | Name | Type | Role |
|---|---|---|---|
| **Harness** | `CLAUDE.md` | Auto-injected rules | Controls how Claude behaves in every session — MODE system, response identifiers, security guardrails, approval workflow, token compression, anti-pattern tracking |
| **Skill** | `/grill-me` | On-demand slash command | Stress-tests a plan by walking the decision tree one question at a time before any code is written |
| **Skill** | `/improve-codebase-architecture` | On-demand slash command | Finds architectural deepening opportunities — detects shallow modules, proposes refactors, drives collaborative design |
| **Skill** | `/frontend-design` | On-demand slash command | Generates distinctive, production-grade UI by committing to a bold aesthetic direction before coding |
| **MCP** | Playwright | Always-on browser control | Lets Claude directly navigate, interact with, and inspect web pages via `browser_*` tools |
| **MCP** | Context7 | Always-on docs lookup | Fetches real-time, version-specific official documentation to prevent hallucinated or deprecated API usage |

---

## Structure

```
ai-common-rules/
├── .claude-plugin/
│   └── plugin.json                    ← Plugin manifest + bundled MCP servers (Playwright, Context7)
├── CLAUDE.md                          ← Harness rules (single source of truth)
└── skills/
    ├── grill-me/
    │   └── SKILL.md                   ← /grill-me slash command
    ├── improve-codebase-architecture/
    │   └── SKILL.md                   ← /improve-codebase-architecture slash command
    └── frontend-design/
        └── SKILL.md                   ← /frontend-design slash command
```

---

## Installation

### Option A — Claude Code CLI

Clone this repo, then run once inside Claude Code:
```
/plugin add <path-to-ai-common-rules>
/plugin enable ai-common-rules
```

### Option B — Claude Desktop App

1. Clone this repo
2. Zip the entire folder (must include `.claude-plugin/plugin.json`)
3. Open Claude Desktop → **Code** tab → **Customize** → **Personal Plugins +** → **Upload Plugin**
4. Upload the `.zip` file

Quick zip command (PowerShell):
```powershell
Compress-Archive -Path "<path-to-ai-common-rules>\*" -DestinationPath "ai-common-rules.zip"
```

Once uploaded, toggle ON/OFF from **Personal Plugins** in the sidebar.

---

## Harness (CLAUDE.md)

Injected automatically into every session when the plugin is enabled. No invocation needed.

### What it does

- **MODE System** — Claude declares its current mode on the first line of every response and is blocked from actions outside that mode's scope

| Mode | Allows | Blocks |
|---|---|---|
| `[MODE:EXPLORE]` | File reads, search | Edits, execution |
| `[MODE:EXECUTE]` | File edits, command execution | Anything outside approved scope |
| `[MODE:REVIEW]` | Delta report, security scan | Starting new work |

- **Response Identifiers** — Every response starts with a mandatory identifier so intent is always explicit

| Identifier | When used |
|---|---|
| `[PLAN]` | Unexecuted plan, awaiting user approval |
| `[ANALYSIS]` | Evidence-based reasoning, RCA, trade-offs |
| `[CODE]` | Implementation or patch |
| `[INFO]` | Status update, general information |
| `[QUESTION]` | Requesting a user decision |
| `[CAUTION]` | Before any destructive action — re-approval required |
| `[CRITICAL]` | Security threat — immediate stop |

- **Approval Workflow** — Claude reports purpose, target files, blast radius, and security check before acting. Execution only starts after explicit user approval.

- **Security Guardrails** — API keys and secrets masked (`[MASKED]`), system paths blocked (`[CRITICAL]`), 5+ file changes require `[CAUTION]` and a Git checkpoint recommendation.

- **Token Compression (Caveman Lite)** — Drops articles, fillers, and pleasantries. Uses fragments, abbreviations, and causal arrows. Suspended inside `[CAUTION]`/`[CRITICAL]` blocks for clarity.

- **Anti-Pattern Tracking** — On negative feedback, Claude proposes adding the violation to the PATTERNS section. Items with Hits ≥ 3 are reviewed for tier promotion.

- **Playwright MCP Rules** — Snapshot-first workflow, capability gating, and security guardrails for all `browser_*` tool usage (see `## PLAYWRIGHT MCP` in `CLAUDE.md`).

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

No separate state file. Uses Claude Code built-ins:

| Role | Tool |
|---|---|
| Planning | Claude Code Plan Mode |
| Task tracking | TodoWrite |
| Plan stress-testing | `/grill-me` |
| Architecture improvement | `/improve-codebase-architecture` |
| UI generation | `/frontend-design` |
