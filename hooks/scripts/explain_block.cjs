// Says why a security hook blocked a tool call, then exits 2 to deny it.
//
// Every deny rule in hooks/hooks.json is paired with a bare `exit 2` entry that
// blocks with no dependencies. This script only supplies the explanation, so if
// node is missing the call is still denied -- just silently.
//
// Usage: node explain_block.cjs <read-env|bash>

const messages = {
  "read-env":
    "ai-common-rules hook blocked this Read: reading .env files is denied " +
    "(CLAUDE.md SECURITY, Zero-Exfiltration).",
  bash:
    "ai-common-rules hook blocked this Bash command. Either it matched a deny " +
    "rule (cat/type of .env files, rm -rf, git push --force or -f, git reset " +
    "--hard, sudo), or Claude Code could not parse it with confidence and the " +
    "rules fail closed -- for example an odd number of single quotes inside a " +
    "heredoc. Simplify the command, or write the script to a file first and run " +
    "that. Rules live in hooks/hooks.json (README: Security Hooks).",
};

console.error(messages[process.argv[2]] || messages.bash);
process.exitCode = 2;
