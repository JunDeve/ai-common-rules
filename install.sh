#!/usr/bin/env bash
# ai-common-rules installer (macOS / Linux / Git Bash)
#
#   ./install.sh
#
# One-stop installer. Registers this repository as a plugin marketplace and
# installs the plugin, then also installs the Superpowers plugin (brainstorming,
# TDD, writing-plans, ...) from its own marketplace, obra/superpowers-marketplace.
# Running it again also updates everything to the latest versions.
# superpowers-developing-for-claude-code comes along as a declared dependency
# of ai-common-rules -- it is not installed separately.
#
#   ./install.sh --skip-superpowers   install only ai-common-rules

set -euo pipefail

REPO='JunDeve/ai-common-rules'
MARKETPLACE='ai-common-rules-marketplace'
PLUGIN='ai-common-rules'

SP_REPO='obra/superpowers-marketplace'
SP_MARKETPLACE='superpowers-marketplace'
SP_PLUGIN='superpowers'
SKIP_SP=0
for arg in "$@"; do
  [ "$arg" = '--skip-superpowers' ] && SKIP_SP=1
done

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
  warn 'Install Node.js to enable them. The hook that injects the harness'
  warn '(CLAUDE.md) also runs on node, so without it the rules are not applied.'
fi

# The negative-feedback hook is launched as `python`; python3 alone is not enough.
if command -v python >/dev/null 2>&1; then
  ok "python: $(command -v python)"
else
  warn 'python not found. Only the negative-feedback hook needs it, and it fails'
  warn 'silently without it. On Linux/macOS you may need a `python` alias for python3.'
fi

if command -v gh >/dev/null 2>&1; then
  ok "gh: $(command -v gh) (run gh auth login if you have not)"
else
  warn 'gh (GitHub CLI) not found. Optional: /find-app uses it to search GitHub.'
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

if [ "$SKIP_SP" = 1 ]; then
  cyan 'Skipping Superpowers (--skip-superpowers)'
else
  cyan "Registering marketplace ($SP_REPO)"
  # A third-party marketplace: a failure here must not undo the install above.
  if claude plugin marketplace add "$SP_REPO"; then
    ok 'registered'
  elif claude plugin marketplace list 2>/dev/null | grep -q "$SP_MARKETPLACE"; then
    ok 'already registered -- continuing'
  else
    warn "Could not register $SP_MARKETPLACE -- Superpowers not installed."
    SKIP_SP=1
  fi

  if [ "$SKIP_SP" = 0 ]; then
    cyan "Installing $SP_PLUGIN"
    claude plugin install "$SP_PLUGIN@$SP_MARKETPLACE" || warn "Could not install $SP_PLUGIN."
  fi
fi

cyan 'Updating to the latest versions'

# Re-running the steps above does not move an already-installed plugin forward:
# an existing marketplace is left as it is and install reuses the cached copy.
# Refresh the catalogs, then update each plugin, so running this script again is
# also how you update. 'already at the latest' is a normal result, not an error.
claude plugin marketplace update "$MARKETPLACE" || warn "Could not refresh $MARKETPLACE."
claude plugin update "$PLUGIN@$MARKETPLACE" || warn "Could not update $PLUGIN."
claude plugin update "superpowers-developing-for-claude-code@$MARKETPLACE" || warn 'Could not update the dependency.'
if [ "$SKIP_SP" = 0 ]; then
  claude plugin marketplace update "$SP_MARKETPLACE" || warn "Could not refresh $SP_MARKETPLACE."
  claude plugin update "$SP_PLUGIN@$SP_MARKETPLACE" || warn "Could not update $SP_PLUGIN."
fi

cyan 'Enabling background auto-update'

# Third-party marketplaces ship with auto-update OFF. Without this the plugin
# and its upstream dependencies only move when someone runs an update by hand,
# which defeats the point of linking upstream repos instead of vendoring them.
SETTINGS="$HOME/.claude/settings.json"
if [ ! -f "$SETTINGS" ]; then
  warn 'settings.json not found -- skipping'
elif command -v python3 >/dev/null 2>&1; then
  python3 - "$SETTINGS" "$MARKETPLACE" <<'PY'
import json, sys
path, name = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as fh:
    data = json.load(fh)
entry = data.get("extraKnownMarketplaces", {}).get(name)
if entry is None:
    print("   marketplace entry not found in settings.json -- skipping")
elif entry.get("autoUpdate"):
    print("   already enabled")
else:
    entry["autoUpdate"] = True
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2, ensure_ascii=False)
        fh.write("
")
    print("   enabled")
PY
else
  warn 'python3 not found, so settings.json was left alone.'
  warn "Set extraKnownMarketplaces -> $MARKETPLACE -> autoUpdate to true by hand"
  warn 'to keep upstream plugins current without running updates yourself.'
fi

cyan 'Installed plugins'
claude plugin list

cat <<'EOF'

Done. Restart Claude Code (or run /reload-plugins) so the harness and the
MCP servers load.

Expect three plugins, all enabled:
  ai-common-rules, superpowers-developing-for-claude-code  (@ai-common-rules-marketplace)
  superpowers                                              (@superpowers-marketplace)
(two, without superpowers, if you passed --skip-superpowers)
EOF
