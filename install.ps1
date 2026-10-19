# ai-common-rules installer (Windows PowerShell)
#
#   Right-click this file -> Run with PowerShell
#   or:  powershell -ExecutionPolicy Bypass -File install.ps1
#
# One-stop installer. Registers this repository as a plugin marketplace and
# installs the plugin, then also installs the Superpowers plugin (brainstorming,
# TDD, writing-plans, ...) from its own marketplace, obra/superpowers-marketplace.
# Running it again also updates everything to the latest versions.
# superpowers-developing-for-claude-code comes along as a declared dependency
# of ai-common-rules -- it is not installed separately.
#
# Pass -SkipSuperpowers to install only ai-common-rules.
#
# Written for Windows PowerShell 5.1, so no '&&', no ternary, no null-coalescing.

param([switch]$SkipSuperpowers)

$ErrorActionPreference = 'Stop'

$Repo        = 'JunDeve/ai-common-rules'
$Marketplace = 'ai-common-rules-marketplace'
$Plugin      = 'ai-common-rules'

$SpRepo        = 'obra/superpowers-marketplace'
$SpMarketplace = 'superpowers-marketplace'
$SpPlugin      = 'superpowers'

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
    Write-Warn 'Install Node.js to enable them. The hook that injects the harness'
    Write-Warn '(CLAUDE.md) also runs on node, so without it the rules are not applied.'
} else {
    Write-Ok "npx: $($npx.Source)"
}

# The negative-feedback hook is launched as `python`.
$python = Get-Command python -ErrorAction SilentlyContinue
if ($null -eq $python) {
    Write-Warn 'python not found. Only the negative-feedback hook needs it, and it fails'
    Write-Warn 'silently without it.'
} else {
    Write-Ok "python: $($python.Source)"
}

$gh = Get-Command gh -ErrorAction SilentlyContinue
if ($null -eq $gh) {
    Write-Warn 'gh (GitHub CLI) not found. Optional: /find-app uses it to search GitHub.'
} else {
    Write-Ok "gh: $($gh.Source) (run gh auth login if you have not)"
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

if ($SkipSuperpowers) {
    Write-Step 'Skipping Superpowers (-SkipSuperpowers)'
} else {
    Write-Step "Registering marketplace ($SpRepo)"
    # A third-party marketplace: a failure here must not undo the install above.
    try {
        claude plugin marketplace add $SpRepo
        Write-Ok 'registered'
    } catch {
        $existing = claude plugin marketplace list 2>$null | Out-String
        if ($existing -match [regex]::Escape($SpMarketplace)) {
            Write-Ok 'already registered -- continuing'
        } else {
            Write-Warn "Could not register $SpMarketplace -- Superpowers not installed: $_"
        }
    }

    Write-Step "Installing $SpPlugin"
    try {
        claude plugin install "$SpPlugin@$SpMarketplace"
    } catch {
        Write-Warn "Could not install ${SpPlugin}: $_"
    }
}

Write-Step 'Updating to the latest versions'

# Re-running the steps above does not move an already-installed plugin forward:
# an existing marketplace is left as it is and install reuses the cached copy.
# Refresh the catalogs, then update each plugin, so running this script again is
# also how you update. 'already at the latest' is a normal result, not an error.
claude plugin marketplace update $Marketplace
claude plugin update "$Plugin@$Marketplace"
claude plugin update "superpowers-developing-for-claude-code@$Marketplace"
if (-not $SkipSuperpowers) {
    claude plugin marketplace update $SpMarketplace
    claude plugin update "$SpPlugin@$SpMarketplace"
}

Write-Step 'Enabling background auto-update'

# Third-party marketplaces ship with auto-update OFF. Without this the plugin
# and its upstream dependencies only move when someone runs an update by hand,
# which defeats the point of linking upstream repos instead of vendoring them.
$settingsPath = Join-Path $HOME '.claude\settings.json'
if (Test-Path $settingsPath) {
    try {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        $entry = $settings.extraKnownMarketplaces.$Marketplace
        if ($null -eq $entry) {
            Write-Warn "marketplace entry not found in settings.json -- skipping"
        } elseif ($entry.PSObject.Properties.Name -contains 'autoUpdate' -and $entry.autoUpdate) {
            Write-Ok 'already enabled'
        } else {
            $entry | Add-Member -NotePropertyName autoUpdate -NotePropertyValue $true -Force
            # Depth matters: the default of 2 would flatten the nested source object.
            $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding utf8
            Write-Ok 'enabled'
        }
    } catch {
        Write-Warn "could not update settings.json: $_"
        Write-Warn 'Set extraKnownMarketplaces -> autoUpdate to true by hand to keep upstreams current.'
    }
} else {
    Write-Warn 'settings.json not found -- skipping'
}

Write-Step 'Installed plugins'
claude plugin list

Write-Host @'

Done. Restart Claude Code (or run /reload-plugins) so the harness and the
MCP servers load.

Expect three plugins, all enabled:
  ai-common-rules, superpowers-developing-for-claude-code  (@ai-common-rules-marketplace)
  superpowers                                              (@superpowers-marketplace)
(two, without superpowers, if you passed -SkipSuperpowers)
'@ -ForegroundColor Cyan
