# Trigger sync hook for "올리기::message" and "내리기::message".
# It runs Git sync commands, then blocks prompt submission with a result message.

$ErrorActionPreference = "Stop"

function Write-HookJson {
  param(
    [string]$Permission,
    [string]$UserMessage,
    [string]$AgentMessage
  )

  $payload = @{
    permission = $Permission
    user_message = $UserMessage
    agent_message = $AgentMessage
  }

  $payload | ConvertTo-Json -Compress
}

function Invoke-Git {
  param([string]$Command)
  $output = & cmd /c $Command 2>&1
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed: $Command`n$output"
  }
  return ($output | Out-String).Trim()
}

function Get-UserPrompt {
  param([object]$HookInput)
  if ($null -ne $HookInput.prompt) { return [string]$HookInput.prompt }
  if ($null -ne $HookInput.text) { return [string]$HookInput.text }
  return ""
}

function Invoke-Cli {
  param([string]$Command)
  $output = & cmd /c $Command 2>&1
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed: $Command`n$output"
  }
  return ($output | Out-String).Trim()
}

function Has-OriginRemote {
  & cmd /c "git remote get-url origin" *> $null
  return ($LASTEXITCODE -eq 0)
}

function Has-Upstream {
  & cmd /c "git rev-parse --abbrev-ref --symbolic-full-name @{u}" *> $null
  return ($LASTEXITCODE -eq 0)
}

function Ensure-OriginRemote {
  param(
    [string]$GithubOwner,
    [bool]$CreateRepoIfMissing = $false
  )

  if (Has-OriginRemote) {
    return
  }

  & cmd /c "gh --version" *> $null
  if ($LASTEXITCODE -ne 0) {
    throw "GitHub CLI (gh) is required to auto-create the repository."
  }

  $repoName = Split-Path -Leaf (Get-Location)
  if ([string]::IsNullOrWhiteSpace($repoName)) {
    throw "Could not detect project root folder name."
  }

  $repoFullName = "$GithubOwner/$repoName"

  & cmd /c "gh repo view $repoFullName --json name -q .name" *> $null
  if ($LASTEXITCODE -ne 0) {
    if ($CreateRepoIfMissing) {
      # Default to private for safety. Change to --public if preferred.
      Invoke-Cli "gh repo create $repoFullName --private --source . --remote origin"
      return
    }
    throw "Remote repository not found: $repoFullName"
  }

  Invoke-Git "git remote add origin https://github.com/$repoFullName.git" | Out-Null
}

try {
  $rawInput = [Console]::In.ReadToEnd()
  if ([string]::IsNullOrWhiteSpace($rawInput)) {
    Write-HookJson -Permission "allow" -UserMessage "" -AgentMessage ""
    exit 0
  }

  $hookInput = $rawInput | ConvertFrom-Json
  $userPrompt = (Get-UserPrompt -HookInput $hookInput).Trim()
  if ([string]::IsNullOrWhiteSpace($userPrompt)) {
    Write-HookJson -Permission "allow" -UserMessage "" -AgentMessage ""
    exit 0
  }

  if (($userPrompt -notlike "올리기::*") -and ($userPrompt -notlike "내리기::*")) {
    Write-HookJson -Permission "allow" -UserMessage "" -AgentMessage ""
    exit 0
  }

  if ($userPrompt -eq "올리기::" -or $userPrompt -eq "내리기::") {
    Write-HookJson -Permission "deny" -UserMessage "[SYNC] 형식 오류: 올리기::메세지내용 또는 내리기::메세지내용으로 입력하세요." -AgentMessage "Invalid trigger format."
    exit 0
  }

  $branch = Invoke-Git "git branch --show-current"
  if ([string]::IsNullOrWhiteSpace($branch)) {
    throw "Could not determine current branch."
  }

  if ($userPrompt -like "올리기::*") {
    $commitMessage = $userPrompt.Substring("올리기::".Length).Trim()
    if ([string]::IsNullOrWhiteSpace($commitMessage)) {
      Write-HookJson -Permission "deny" -UserMessage "[SYNC] 형식 오류: 올리기::메세지내용 형식으로 입력하세요." -AgentMessage "Missing commit message for upload trigger."
      exit 0
    }

    Ensure-OriginRemote -GithubOwner "JunDeve" -CreateRepoIfMissing $true

    Invoke-Git "git pull --rebase origin $branch" | Out-Null
    Invoke-Git "git add -A" | Out-Null

    $status = Invoke-Git "git status --porcelain"
    if (-not [string]::IsNullOrWhiteSpace($status)) {
      $safeCommitMessage = $commitMessage.Replace('"', '\"')
      $commitCommand = 'git commit -m "{0}"' -f $safeCommitMessage
      Invoke-Git $commitCommand | Out-Null
    }

    if (Has-Upstream) {
      Invoke-Git "git push origin $branch" | Out-Null
    } else {
      Invoke-Git "git push -u origin $branch" | Out-Null
    }
    Write-HookJson -Permission "deny" -UserMessage "[SYNC] 업로드 완료: origin/$branch (message: $commitMessage)" -AgentMessage "Handled trigger: 올리기::"
    exit 0
  }

  if ($userPrompt -like "내리기::*") {
    $pullMessage = $userPrompt.Substring("내리기::".Length).Trim()
    if ([string]::IsNullOrWhiteSpace($pullMessage)) {
      Write-HookJson -Permission "deny" -UserMessage "[SYNC] 형식 오류: 내리기::메세지내용 형식으로 입력하세요." -AgentMessage "Missing message for download trigger."
      exit 0
    }

    Ensure-OriginRemote -GithubOwner "JunDeve" -CreateRepoIfMissing $false

    Invoke-Git "git pull --rebase origin $branch" | Out-Null
    Write-HookJson -Permission "deny" -UserMessage "[SYNC] 내려받기 완료: origin/$branch (message: $pullMessage)" -AgentMessage "Handled trigger: 내리기::"
    exit 0
  }

  Write-HookJson -Permission "allow" -UserMessage "" -AgentMessage ""
  exit 0
}
catch {
  $message = $_.Exception.Message
  Write-HookJson -Permission "deny" -UserMessage "[SYNC] 실패: $message" -AgentMessage "Sync trigger failed."
  exit 0
}
