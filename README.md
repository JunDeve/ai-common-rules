# ai-common-rules

**Claude Code only.** A plugin that controls a harness (behavior rules) + skills (task tools) from one place.
Planning and task tracking are delegated to Claude Code's built-in features (Plan Mode, TodoWrite).

> 한국어 문서: [README.ko.md](README.ko.md)

---

## Structure

```
ai-common-rules/
├── .claude-plugin/
│   └── plugin.json                    ← Plugin manifest (required for Desktop app upload)
├── CLAUDE.md                          ← Harness rules injected when plugin is enabled
├── .ai/                               ← Harness source files (edit here)
│   ├── AI_COMMON_RULES.md             ← Behavior rules, identifiers, modes, security, token compression
│   └── PATTERNS.md                    ← Anti-pattern DB (accumulated from negative feedback)
└── skills/
    ├── grill-me/
    │   └── SKILL.md                   ← /grill-me slash command
    └── improve-codebase-architecture/
        └── SKILL.md                   ← /improve-codebase-architecture slash command
```

---

## Installation

### Option A — Claude Code CLI

Clone this repo, then run once inside Claude Code:
```
/plugin add <path-to-ai-common-rules>
```

Enable:
```
/plugin enable ai-common-rules
```

### Option B — Claude Desktop App (Customize → Plugin Upload)

1. Clone this repo
2. Zip the entire folder contents (must include `.claude-plugin/plugin.json`)
3. Open Claude Desktop → **Code** tab → **Customize** → **개인 플러그인 +** → **플러그인 업로드**
4. Upload the `.zip` file

Quick zip command (PowerShell):
```powershell
Compress-Archive -Path "<path-to-ai-common-rules>\*" -DestinationPath "ai-common-rules.zip"
```

Once uploaded, the plugin appears under **개인 플러그인** in the sidebar — toggle ON/OFF from there.

---

## Control

### Harness + Skills

| Command | Effect |
|---|---|
| `/plugin enable ai-common-rules` | Harness rules ON + skills available |
| `/plugin disable ai-common-rules` | Everything OFF |

### Skills (on-demand only)

| Command | Purpose |
|---|---|
| `/grill-me` | Stress-test a plan before submitting `[PLAN]`. Walks the decision tree one question at a time. |
| `/improve-codebase-architecture` | Analyze codebase structure. Detect shallow modules → propose deep refactors → collaborative design. |

Skills are slash commands — inactive until invoked.

---

## Harness Rules (AI_COMMON_RULES.md)

Injected into every session when the plugin is enabled.

### MODE System
| Mode | Allow | Block |
|---|---|---|
| `[MODE:EXPLORE]` | File reads, search | Edits, execution |
| `[MODE:EXECUTE]` | File edits, command execution | Anything outside approved scope |
| `[MODE:REVIEW]` | Delta report, security scan | Starting new work |

Current mode must be declared on the **first line** of every response.

### Identifiers (required on first line)
| Identifier | When to use |
|---|---|
| `[PLAN]` | Unexecuted plan, awaiting approval |
| `[ANALYSIS]` | Evidence, analysis, RCA, trade-offs |
| `[CODE]` | Implementation, patch |
| `[INFO]` | Status, general info |
| `[QUESTION]` | Requesting user decision |
| `[CAUTION]` | Before destructive action, re-approval required |
| `[CRITICAL]` | Security threat, immediate stop |

### Security Guardrails
- API keys and secrets must never be printed → `[MASKED]`
- System path access blocked → `[CRITICAL]`
- 5+ files affected → `[CAUTION]` + Git checkpoint recommended
- Delete or overwrite requires `[CAUTION]` + re-approval

### Token Compression — Caveman Lite
Lightweight compression rules adapted from [Caveman](https://github.com/JuliusBrussee/caveman) by Julius Brussee,
modified to avoid conflicts with harness identifiers, Delta Report format, and code blocks.

- Drop articles (a/an/the), fillers (just, really, basically), pleasantries (sure, certainly)
- Use fragments, abbreviations (DB, auth, config, fn), causal arrows (X → Y)
- Suspend compression inside `[CAUTION]` · `[CRITICAL]` blocks — clarity first

### Anti-Pattern Accumulation (PATTERNS.md)
On negative feedback ("that's wrong", "don't do that"), propose adding an entry to PATTERNS.md.
Items with Hits ≥ 3 are reviewed for tier promotion.

---

## Planning & Task Tracking

No separate state file. Uses Claude Code built-ins:

| Role | Tool |
|---|---|
| Planning | Claude Code Plan Mode |
| Task tracking | TodoWrite |
| Design validation | `/grill-me` |
| Architecture improvement | `/improve-codebase-architecture` |

On first run of `/improve-codebase-architecture`, these are auto-created in your project:
- `CONTEXT.md` — domain glossary
- `docs/adr/` — architecture decision records
