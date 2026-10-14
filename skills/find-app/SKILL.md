---
name: find-app
description: Find candidates for a feature the user wants to understand or port — open-source implementations first, then analyzable apps already installed on this machine, then other apps known to have it — and hand the chosen one to /reverse-port. Manual-only; finds, never downloads or analyzes.
argument-hint: [the feature you want]
disable-model-invocation: true
---

# Find App

Turn "I want a feature like X" into a short, ranked list of concrete candidates,
ending in one ready-to-run `/reverse-port` line. This skill only finds. It does
not download, install, clone or analyze anything.

## 1. Pin down the feature

Restate the feature in one sentence from the user's point of view, plus two or
three observable behaviors (what goes in, what comes out) to judge matches by.
Infer the user's stack from the current directory (`package.json`,
`pyproject.toml`, `*.csproj` and the like) before asking. Ask at most one
question, and only if the feature or stack is still unclear.

## 2. Search in this order

### A. Open source

```
gh search repos "<keywords>" --license mit --license apache-2.0 --sort stars --limit 10
gh search code "<distinctive phrase or API>" --language <stack>
```

Use two or three short keywords per `gh search repos` query, not the feature
sentence: a long phrase returned nothing when tried, while a single keyword
returned results, so run several short queries and merge them. Repeating
`--license` returned results too, so it widens the search. Also use
WebSearch. For each candidate, check with
`gh repo view <owner/repo> --json licenseInfo,pushedAt,stargazerCount,isArchived,description`,
then confirm the feature is really implemented by reading its README or the
relevant file (`gh api` or WebFetch). Descriptions and star counts do not
establish that, and popularity is not verification.

License decides what the user may do:

- **MIT, Apache-2.0, BSD, ISC** — reuse is fine with attribution.
- **GPL, AGPL, LGPL** — reading is fine; copying code carries obligations.
- **No license** — all rights reserved: read it to understand, do not copy.

If an open-source match really does the thing, say so and stop: reading the
source beats reverse engineering a binary, and no `/reverse-port` is needed.

### B. Installed on this machine

Read-only and cheap. Look only at application install directories, never user
data, profiles or config folders, and print names and paths only.

- Windows: Electron/JavaScript apps keep `resources\app.asar` (or
  `resources\app`) under `%LOCALAPPDATA%\Programs`, `%ProgramFiles%` and
  `%ProgramFiles(x86)%`. Installed names come from `winget list`.
- macOS: `/Applications/*.app/Contents/Resources/app.asar`.
- Linux: `dpkg -l`, `snap list`, `flatpak list`.

Match names against the feature, then confirm the app is really there. Judge
how analyzable each is with REA (see `/reverse-port` for the routing):

| Kind | Analyzability |
|---|---|
| Electron/JavaScript (`app.asar`) | Good — static, no engine needed |
| .NET assembly | Good — static, no engine needed |
| Go or Rust binary | Build metadata only |
| Native C/C++ | Needs Ghidra, Hopper or IDA already installed |
| Anything else | Unknown — say so |

### C. Other apps known to have it

WebSearch and WebFetch. Every claim needs a source. Mark a candidate *verified*
only if you opened the page and it shows the feature; otherwise mark it
*unverified*. Search summaries can be wrong, so go to the primary page. Keep
local app names and paths out of web queries unless the name itself is the
subject. The user has to obtain these apps themselves.

## 3. Present the candidates

At most six rows, ordered: usable open source, then installed and analyzable,
then the rest.

| # | Candidate | Where | Evidence it has the feature | Openness / license | Analyzable with REA? | Next step |
|---|---|---|---|---|---|---|

After the table, give a one-paragraph recommendation and a short list of what
you did not verify.

## 4. Hand off

- **Open-source pick** — no `/reverse-port`. Offer to read its source and
  propose a port through the normal `[PLAN]` workflow.
- **Installed or other app** — end with exactly one line for the chosen
  candidate:

  `/reverse-port <absolute path or app name> — <the feature in one sentence>`

  `/reverse-port` is manual-only, so the user types it; it asks about
  authorization before anything runs.

## Don't

- Download, install or clone anything. Reading through `gh api` or WebFetch is
  fine; if the user wants a clone, ask first.
- Point to cracked or pirated copies, unofficial mirrors, or anything that
  bypasses licensing.
- Say a candidate has the feature without a source for it.
