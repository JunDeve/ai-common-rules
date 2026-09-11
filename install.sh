#!/usr/bin/env bash
# ai-common-rules installer (macOS / Linux / Git Bash)
#
#   ./install.sh
#
# Registers this repository as a plugin marketplace and installs the plugin.
# superpowers and superpowers-developing-for-claude-code come along as declared
# dependencies -- they are not installed separately.

set -euo pipefail

REPO='JunDeve/ai-common-rules'
MARKETPLACE='ai-common-rules-marketplace'
PLUGIN='ai-common-rules'

cyan()  { printf '\n\033[36m== %s\033[0m\n' "$1"; }
ok()    { printf '   \033[32m%s\033[0m\n' "$1"; }
warn()  { printf '   \033[33m%s\033[0m\n' "$1"; }
die()   { printf '\033[31m%s\033[0m\n' "$1" >&2; exit 1; }

cyan 'Checking prerequisites'

command -v claude >/dev/null 2>&1 || die 'claude CLI not found on PATH.

Install Claude Code first (https://claude.com/claude-code), open a new shell
so PATH refreshes, then run this script again.'
ok "claude: $(command -v claude)"

if command -v npx >/dev/null 2>&1; then
  ok "npx: $(command -v npx)"
else
  warn 'npx not found. The plugin installs fine, but its Playwright and'
  warn 'Context7 MCP servers launch through npx and will not start.'
  warn 'Install Node.js to enable them.'
fi

cyan "Registering marketplace ($REPO)"

# Re-adding an existing marketplace is not an error worth stopping for -- the
# catalog is already registered, which is the outcome this step wants.
if claude plugin marketplace add "$REPO"; then
  ok 'registered'
elif claude plugin marketplace list 2>/dev/null | grep -q "$MARKETPLACE"; then
  ok 'already registered -- continuing'
else
  die 'Could not register the marketplace.'
fi

cyan "Installing $PLUGIN (with dependencies)"
claude plugin install "$PLUGIN@$MARKETPLACE"

cyan 'Installed plugins'
claude plugin list

cat <<'EOF'

Done. Restart Claude Code (or run /reload-plugins) so the harness and the
MCP servers load.

Expect three plugins, all enabled, all on @ai-common-rules-marketplace:
  ai-common-rules, superpowers, superpowers-developing-for-claude-code
EOF
