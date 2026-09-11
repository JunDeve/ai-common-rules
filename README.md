# ai-common-rules

**Claude Code only.** A single plugin that bundles a behavior harness, on-demand skills, and always-on MCP servers into one install.

> 한국어 문서: [README.ko.md](README.ko.md)

---

## What's Included

| Component | Name | Type | Role |
|---|---|---|---|
| **Harness** | `CLAUDE.md` | Auto-injected rules | Controls how Claude behaves in every session — response identifiers, security guardrails, approval workflow, token compression, anti-pattern tracking |
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
│   ├── marketplace.json               ← Marketplace catalog (this repo + upstream plugins)
│   └── plugin.json                    ← Plugin manifest + dependencies + MCP servers (Playwright, Context7)
├── CLAUDE.md                          ← Harness rules (always injected)
├── PATTERNS.md                        ← M/L anti-patterns (on-demand, loaded on negative feedback)
├── PLAYWRIGHT.md                      ← Playwright MCP rules (on-demand, loaded for browser tasks)
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

This repo is itself a **plugin marketplace**. One install pulls in the harness, the skills, the MCP servers, and the curated upstream plugins.

### Recommended — from GitHub (auto-updating)

```bash
claude plugin marketplace add JunDeve/ai-common-rules
```
```bash
claude plugin install ai-common-rules@ai-common-rules-marketplace
```

`superpowers` and `superpowers-developing-for-claude-code` are declared as dependencies, so they install and enable automatically. Afterwards the marketplace refreshes over `git pull` — no manual re-upload, ever.

To pin to a tag instead of tracking the default branch:
```bash
claude plugin marketplace add JunDeve/ai-common-rules@v2.1.0
```

### Local development

```bash
claude --plugin-dir <path-to-ai-common-rules>
```

### Claude Desktop App (manual upload)

Only needed if you can't reach GitHub. Zip the folder (must include `.claude-plugin/plugin.json`), then **Code** tab → **Customize** → **Personal Plugins +** → **Upload Plugin**. Note: manually uploaded copies do **not** auto-update.

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

- **Token Compression (Caveman Lite)** — Drops articles, fillers, and pleasantries. Uses fragments, abbreviations, and causal arrows. Suspended inside `[CAUTION]`/`[CRITICAL]` blocks for clarity.

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

---

## Why Superpowers Is a Dependency, Not a Rival

`ai-common-rules` handles behavior control — approval workflow, response identifiers, security guardrails. It deliberately does not define an execution methodology. Superpowers does, and the two meet at the approval boundary: `/grill-me` validates a plan *before* execution starts, Superpowers picks up *right after* approval, turning an approved `[PLAN]` into a spec, a task breakdown, and test-driven implementation. Zero overlap — which is why it's bundled rather than merely suggested.

### Claude Mem — deliberately excluded

Claude Mem adds persistent cross-session memory (SQLite + vector store, auto-summarized from tool activity). Skip it if you're already relying on Claude Code's built-in auto-memory system — running both means duplicate context injection and no single source of truth for project state.
