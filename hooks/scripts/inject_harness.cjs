// SessionStart hook: puts the harness (CLAUDE.md) into the session context.
//
// Claude Code does not load a CLAUDE.md that sits at a plugin's root
// (`claude plugin validate` warns about exactly that), so the rules never
// reached a session that got them by installing the plugin. A SessionStart
// hook's plain stdout is added to the context, so this prints the file.
//
// Any problem exits 0 with no output. A missing harness is better than a
// broken session start; scripts/validate.py guards the size and the wiring.

const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..", "..");

let rules;
try {
  rules = fs.readFileSync(path.join(root, "CLAUDE.md"));
} catch {
  return;
}

const header =
  "ai-common-rules harness, injected by the plugin's SessionStart hook because " +
  "Claude Code does not load a plugin's CLAUDE.md. Files the rules below name by " +
  "relative path (PATTERNS.md, PLAYWRIGHT.md, scripts/bump_pattern_hits.py) live " +
  `under the plugin root: ${root}\n` +
  "Read and run them from there, not from the project directory.\n\n";

// Raw bytes in, raw bytes out: no re-encoding of the Korean text.
process.stdout.write(Buffer.concat([Buffer.from(header, "utf8"), rules]));
