# ai-common-rules installer (Windows PowerShell)
#
#   Right-click this file -> Run with PowerShell
#   or:  powershell -ExecutionPolicy Bypass -File install.ps1
#
# Registers this repository as a plugin marketplace and installs the plugin.
# superpowers and superpowers-developing-for-claude-code come along as declared
# dependencies -- they are not installed separately.
#
# Written for Windows PowerShell 5.1, so no '&&', no ternary, no null-coalescing.

$ErrorActionPreference = 'Stop'

$Repo        = 'JunDeve/ai-common-rules'
$Marketplace = 'ai-common-rules-marketplace'
$Plugin      = 'ai-common-rules'

function Write-Step($text) { Write-Host "`n== $text" -ForegroundColor Cyan }
function Write-Ok($text)   { Write-Host "   $text"   -ForegroundColor Green }
function Write-Warn($text) { Write-Host "   $text"   -ForegroundColor Yellow }

Write-Step 'Checking prerequisites'

$claude = Get-Command claude -ErrorAction SilentlyContinue
if ($null -eq $claude) {
    Write-Host @'
claude CLI not found on PATH.

Install Claude Code first (https://claude.com/claude-code), open a new
terminal so PATH refreshes, then run this script again.
'@ -ForegroundColor Red
    exit 1
}
Write-Ok "claude: $($claude.Source)"

$npx = Get-Command npx -ErrorAction SilentlyContinue
if ($null -eq $npx) {
    Write-Warn 'npx not found. The plugin installs fine, but its Playwright and'
    Write-Warn 'Context7 MCP servers launch through npx and will not start.'
    Write-Warn 'Install Node.js to enable them.'
} else {
    Write-Ok "npx: $($npx.Source)"
}

Write-Step "Registering marketplace ($Repo)"

# Re-adding an existing marketplace is not an error worth stopping for -- the
# catalog is already registered, which is the outcome this step wants.
try {
    claude plugin marketplace add $Repo
    Write-Ok 'registered'
} catch {
    Write-Warn 'add reported an error; checking whether it is already registered'
    $existing = claude plugin marketplace list 2>$null | Out-String
    if ($existing -match [regex]::Escape($Marketplace)) {
        Write-Ok 'already registered -- continuing'
    } else {
        Write-Host "Could not register the marketplace: $_" -ForegroundColor Red
        exit 1
    }
}

Write-Step "Installing $Plugin (with dependencies)"
claude plugin install "$Plugin@$Marketplace"

Write-Step 'Installed plugins'
claude plugin list

Write-Host @'

Done. Restart Claude Code (or run /reload-plugins) so the harness and the
MCP servers load.

Expect three plugins, all enabled, all on @ai-common-rules-marketplace:
  ai-common-rules, superpowers, superpowers-developing-for-claude-code
'@ -ForegroundColor Cyan
