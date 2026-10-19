---
name: reverse-port
description: Analyze an existing application, binary, or package with REA and port the behavior of one feature into the user's own project. Manual-only; invoke when the user explicitly asks to analyze and port something.
disable-model-invocation: true
allowed-tools: Read, Glob, Grep
---

# Reverse Port

Understand how one feature works in software the user already has, from the
shipped artifact rather than source, then re-implement it in the user's own
project. Nothing is registered or left running: REA is invoked as a one-off CLI
command, and only when this skill is.

## Gate 1 — authorization

Before running anything, ask one question: is the target the user's own
software, or are they licensed or otherwise authorized to analyze it for this
purpose (open source whose license allows it, interoperability, security
research)?

- **Yes** — continue.
- **Third-party proprietary, or unsure** — continue only at the level of
  *behavior*: what it does, its inputs, outputs, edge cases, file formats and
  protocols. Never its code or assets; the port is written from that
  description. Say this limit out loud before the first command.
- **Stop entirely** if the goal is bypassing DRM, license checks, anti-cheat or
  access controls, or copying protected code or assets. REA's own
  [DISCLAIMER](https://github.com/morluto/rea/blob/rea-agents-6.5.0/DISCLAIMER.md)
  excludes these too.

## Gate 2 — what runs

REA runs as `npx -y rea-agents@6.5.0 <command>`. The version is pinned on
purpose: do not switch to `@latest`, and do not bump the pin without reading
the release notes first. The first run downloads the package (about 25 MB).
This skill does not pre-approve Bash, so each command goes through the normal
permission prompt.

Static commands read files without executing the target. Anything that
*executes* the target, attaches to a process or a browser or Electron debug
port, uses `adb`, captures network traffic, or installs software is a runtime
action. Present it as a caution (plain words, no bracketed tag) with its effect and wait for approval.

Never install Hopper, Ghidra, IDA, JADX, a JDK or Node.js to make a command
work. If a required engine is missing, say so and stop that path.

## Route the target

Use absolute paths. Add `--json` to every command.

| Target | Command |
|---|---|
| Extracted JavaScript/Electron app directory, or `.asar` | `analyze-javascript-application <path>` |
| .NET assembly | `inspect-managed-artifact <dll>`, then `inspect-managed-members <dll> [--type Full.Name]` |
| SQLite database | `inspect-sqlite-database <path> [--table NAME --row-limit 20]` |
| Go binary | `inspect-go-binary <path>` |
| Rust binary | `inspect-rust-binary <path>` |
| Native binary (needs Hopper, Ghidra or IDA already installed) | `analyze <path> --provider <id>`, then `search`, `function`, `decompile`, `xrefs`, `trace` |

For anything else, run `npx -y rea-agents@6.5.0 --help` and the command's own
`--help`. Several workflows are Linux-only; on Windows, check the command's
help before promising a result.

## Handle the output

Real application Evidence can be hundreds of megabytes. Redirect it to a file
outside the target and outside the user's project, and never print it whole.
Read it through REA's summary and page views; the
[CLI guide](https://github.com/morluto/rea/blob/rea-agents-6.5.0/docs/cli.md#run-a-command)
shows how to build them.

## Report with evidence

Explain the feature from what REA returned. Tie every claim to a module,
function or path from its output, and mark each as *observed* or *inferred*.
Pass along the unknowns and limitations REA reports. Where REA could not
establish something, say so rather than filling the gap with a guess.

## Port

1. Write a behavior spec from the evidence: inputs, outputs, state, edge cases,
   dependencies. No code yet.
2. Present a plan for implementing it in the user's project: target files,
   blast radius, risk. Wait for approval.
3. Implement fresh against the project's own architecture and conventions.
   For third-party targets, never paste decompiled or extracted code. For the
   user's own code, reuse is fine.

## Not for

Ordinary analysis of a source repository you can already read: use normal tools
or `/improve-codebase-architecture`. And do not run REA diagnostics before the
first command; run the command and react to what fails.
