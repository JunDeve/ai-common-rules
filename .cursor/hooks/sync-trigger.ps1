# Git sync hooks:
#   create::title — GitHub 레포 생성/연결 + 동적 대상 저장 (JunDeve/<title>)
#   up::message   — commit + push (same remote resolution)
#   down::message — pull --rebase (same remote resolution)
# 대상 해석 순서: origin URL(JunDeve/*) → .cursor/git-sync-target.json → 폴더명 + git ls-remote
# gh: create:: 시 없으면 winget으로 설치 시도(Windows). up/down은 Git만으로도 가능.

$ErrorActionPreference = "Stop"

$Script:GithubOwner = "JunDeve"
$Script:SyncStateRel = ".cursor/git-sync-target.json"

function Write-HookJson {
  param(
    [string]$Permission,
    [string]$UserMessage,
    [string]$AgentMessage
  )

  $payload = @{
    permission    = $Permission
    user_message  = $UserMessage
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

function Get-SyncStatePath {
  return (Join-Path (Get-Location) $Script:SyncStateRel)
}

function Read-SyncState {
  $path = Get-SyncStatePath
  if (-not (Test-Path $path)) { return $null }
  try {
    $j = Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json
    $owner = [string]$j.owner
    $repo = [string]$j.repo
    if ([string]::IsNullOrWhiteSpace($owner) -or [string]::IsNullOrWhiteSpace($repo)) { return $null }
    return @{ Owner = $owner.Trim(); Repo = $repo.Trim() }
  }
  catch {
    return $null
  }
}

function Write-SyncState {
  param(
    [string]$Owner,
    [string]$Repo
  )
  $path = Get-SyncStatePath
  $dir = Split-Path $path -Parent
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  @{ owner = $Owner; repo = $Repo } | ConvertTo-Json -Compress | Set-Content -Path $path -Encoding UTF8 -NoNewline
}

function Normalize-RepoSlug {
  param([string]$Raw)
  if ([string]::IsNullOrWhiteSpace($Raw)) { return $null }
  $s = $Raw.Trim() -replace '\s+', '-'
  $s = $s -replace '[^a-zA-Z0-9._-]', ''
  if ([string]::IsNullOrWhiteSpace($s)) { return $null }
  return $s
}

function Get-OriginUrl {
  & cmd /c "git remote get-url origin" 2>&1 | Out-Null
  if ($LASTEXITCODE -ne 0) { return $null }
  $url = (& cmd /c "git remote get-url origin" 2>&1 | Out-String).Trim()
  if ([string]::IsNullOrWhiteSpace($url)) { return $null }
  return $url
}

function Parse-GitHubOwnerRepo {
  param([string]$Url)
  if ([string]::IsNullOrWhiteSpace($Url)) { return $null }
  $u = $Url.Trim()

  if ($u -match 'github\.com[:/]([^/]+)/([^/.]+)(?:\.git)?/?\s*$') {
    return @{ Owner = $Matches[1]; Repo = $Matches[2] }
  }
  return $null
}

function Test-GhAvailable {
  & cmd /c "gh --version" *> $null
  return ($LASTEXITCODE -eq 0)
}

function Refresh-SessionPath {
  $machine = [Environment]::GetEnvironmentVariable("Path", "Machine")
  $user = [Environment]::GetEnvironmentVariable("Path", "User")
  $env:Path = "$machine;$user"
}

function Prepend-GhFromCommonPaths {
  $dirs = @(
    "${env:ProgramFiles}\GitHub CLI",
    "${env:ProgramFiles(x86)}\GitHub CLI",
    (Join-Path $env:LOCALAPPDATA "Programs\GitHub CLI")
  )
  foreach ($d in $dirs) {
    $exe = Join-Path $d "gh.exe"
    if (Test-Path -LiteralPath $exe) {
      if ($env:Path -notlike "*$d*") {
        $env:Path = "$d;$env:Path"
      }
      return
    }
  }
}

# create:: 전용 — 새 레포를 만들 때 gh가 없으면 Windows에서는 winget으로 설치 시도
function Ensure-GhForMakeTrigger {
  if (Test-GhAvailable) { return }

  if ($env:OS -ne "Windows_NT") {
    throw "gh가 없습니다. macOS/Linux에서는 패키지 관리자로 설치한 뒤 다시 create:: 를 실행하세요. (예: brew install gh)"
  }

  $winget = $null
  $wingetApps = Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps\winget.exe"
  if (Test-Path -LiteralPath $wingetApps) {
    $winget = $wingetApps
  }
  else {
    $cmd = Get-Command winget -ErrorAction SilentlyContinue
    if ($null -ne $cmd) { $winget = $cmd.Source }
  }

  if ([string]::IsNullOrWhiteSpace($winget)) {
    throw "gh도 winget도 없습니다. Microsoft Store에서 '앱 설치 관리자(App Installer)'를 설치하거나 https://cli.github.com 에서 GitHub CLI를 설치하세요."
  }

  $proc = Start-Process -FilePath $winget -ArgumentList @(
    "install", "--id", "GitHub.cli", "-e", "--source", "winget",
    "--accept-package-agreements", "--accept-source-agreements", "--disable-interactivity"
  ) -Wait -PassThru -NoNewWindow

  $code = if ($null -ne $proc -and $null -ne $proc.ExitCode) { [int]$proc.ExitCode } else { -1 }

  Refresh-SessionPath
  Prepend-GhFromCommonPaths
  if (Test-GhAvailable) { return }

  if ($code -ne 0) {
    throw "winget으로 GitHub CLI 설치에 실패했습니다(exit: $code). 관리자 권한 터미널에서 재시도하거나 https://cli.github.com 에서 수동 설치하세요."
  }

  throw "GitHub CLI(gh)는 설치된 것으로 보이나 이 세션 PATH에서 찾지 못했습니다. Cursor를 재시작한 뒤 create:: 를 다시 실행하세요."
}

# Git만 사용: 공개 저장소·빈 저장소는 대부분 exit 0, 없으면 128. 비공개·미인증은 실패할 수 있음.
# GCM credential storage lock(일부 샌드박스) 회피: 익명 조회만 하므로 helper 비활성화
function Test-GitHubRepoReachable {
  param([string]$FullName)
  $url = "https://github.com/$FullName.git"
  & cmd /c "git -c credential.helper= ls-remote `"$url`"" 2>&1 | Out-Null
  return ($LASTEXITCODE -eq 0)
}

function Test-GhRepoExists {
  param([string]$FullName)
  if (Test-GitHubRepoReachable -FullName $FullName) { return $true }
  if (-not (Test-GhAvailable)) { return $false }
  & cmd /c "gh repo view $FullName --json name -q .name" *> $null
  return ($LASTEXITCODE -eq 0)
}

function Set-OriginToJunDeveRepo {
  param([string]$RepoSlug)
  $full = "$Script:GithubOwner/$RepoSlug"
  $httpsUrl = "https://github.com/$full.git"
  if ($null -ne (Get-OriginUrl)) {
    Invoke-Git "git remote set-url origin $httpsUrl" | Out-Null
  }
  else {
    Invoke-Git "git remote add origin $httpsUrl" | Out-Null
  }
  Write-SyncState -Owner $Script:GithubOwner -Repo $RepoSlug
}

function Resolve-TargetRepoSlug {
  # 1) origin → JunDeve/repo
  $origin = Get-OriginUrl
  $parsed = Parse-GitHubOwnerRepo -Url $origin
  if ($null -ne $parsed -and $parsed.Owner -eq $Script:GithubOwner -and -not [string]::IsNullOrWhiteSpace($parsed.Repo)) {
    Write-SyncState -Owner $Script:GithubOwner -Repo $parsed.Repo
    return $parsed.Repo
  }

  # 2) saved state (create::에서 기록)
  $state = Read-SyncState
  if ($null -ne $state -and $state.Owner -eq $Script:GithubOwner -and -not [string]::IsNullOrWhiteSpace($state.Repo)) {
    return $state.Repo
  }

  # 3) folder name → 원격에 이미 있으면 감지 (git ls-remote, 필요 시 gh)
  $folder = Split-Path -Leaf (Get-Location)
  if (-not [string]::IsNullOrWhiteSpace($folder)) {
    $slug = Normalize-RepoSlug -Raw $folder
    if ($null -ne $slug -and (Test-GhRepoExists -FullName "$Script:GithubOwner/$slug")) {
      Write-SyncState -Owner $Script:GithubOwner -Repo $slug
      return $slug
    }
  }

  return $null
}

function Ensure-OriginForSlug {
  param(
    [string]$RepoSlug,
    [bool]$CreateRepoIfMissing
  )

  $full = "$Script:GithubOwner/$RepoSlug"
  $exists = Test-GhRepoExists -FullName $full

  if ($exists) {
    Set-OriginToJunDeveRepo -RepoSlug $RepoSlug
    return
  }

  if ($CreateRepoIfMissing -and (Test-GhAvailable)) {
    $originPresent = $null -ne (Get-OriginUrl)
    if (-not $originPresent) {
      Invoke-Cli "gh repo create $full --private --source . --remote origin"
    }
    else {
      Invoke-Cli "gh repo create $full --private"
      Set-OriginToJunDeveRepo -RepoSlug $RepoSlug
    }
    Write-SyncState -Owner $Script:GithubOwner -Repo $RepoSlug
    return
  }

  if ($CreateRepoIfMissing) {
    Set-OriginToJunDeveRepo -RepoSlug $RepoSlug
    throw "GitHub에 아직 $full 이 없거나(또는 비공개) 원격을 확인하지 못했습니다. https://github.com/new 에서 같은 이름으로 저장소를 만든 뒤 다시 up:: 를 실행하세요. (gh 설치 없이 진행 가능)"
  }

  throw "원격 저장소를 찾을 수 없습니다: $full. `create::title`으로 연결하거나 GitHub에서 저장소를 만든 뒤 다시 시도하세요."
}

function Has-Upstream {
  & cmd /c "git rev-parse --abbrev-ref --symbolic-full-name @{u}" *> $null
  return ($LASTEXITCODE -eq 0)
}

try {
  # 비TTY 환경에서 Git이 터미널 입력을 요구하며 막히는 경우 완화(캐시된 자격 증명은 그대로 사용)
  $env:GIT_TERMINAL_PROMPT = '0'

  $utf8 = New-Object System.Text.UTF8Encoding $false
  # Cursor는 stdin(UTF-8). 로컬 터미널 검증 시 한글 깨짐 방지: $env:SYNC_TRIGGER_INPUT_FILE="...\hook-input.json"
  if ($env:SYNC_TRIGGER_INPUT_FILE -and (Test-Path -LiteralPath $env:SYNC_TRIGGER_INPUT_FILE)) {
    $rawInput = [System.IO.File]::ReadAllText($env:SYNC_TRIGGER_INPUT_FILE, $utf8)
  }
  else {
    $stdinReader = New-Object System.IO.StreamReader([Console]::OpenStandardInput(), $utf8)
    try {
      $rawInput = $stdinReader.ReadToEnd()
    }
    finally {
      $stdinReader.Dispose()
    }
  }

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

  $isMake = $userPrompt -like "create::*"
  $isUp = $userPrompt -like "up::*"
  $isDown = $userPrompt -like "down::*"

  if (-not ($isMake -or $isUp -or $isDown)) {
    Write-HookJson -Permission "allow" -UserMessage "" -AgentMessage ""
    exit 0
  }

  if ($isMake -and ($userPrompt -eq "create::")) {
    Write-HookJson -Permission "deny" -UserMessage "[SYNC] 형식 오류: create::repo-name 형식으로 입력하세요." -AgentMessage "Invalid trigger format for create::."
    exit 0
  }

  if ($isUp -and ($userPrompt -eq "up::")) {
    Write-HookJson -Permission "deny" -UserMessage "[SYNC] 형식 오류: up::commit message 형식으로 입력하세요." -AgentMessage "Invalid trigger format."
    exit 0
  }

  if ($isDown -and ($userPrompt -eq "down::")) {
    Write-HookJson -Permission "deny" -UserMessage "[SYNC] 형식 오류: down::note 형식으로 입력하세요." -AgentMessage "Invalid trigger format."
    exit 0
  }

  $branch = Invoke-Git "git branch --show-current"
  if ([string]::IsNullOrWhiteSpace($branch)) {
    throw "현재 브랜치를 확인할 수 없습니다."
  }

  if ($isMake) {
    $title = $userPrompt.Substring("create::".Length).Trim()
    $slug = Normalize-RepoSlug -Raw $title
    if ($null -eq $slug) {
      Write-HookJson -Permission "deny" -UserMessage "[SYNC] 유효한 저장소 제목이 아닙니다." -AgentMessage "Invalid repo title."
      exit 0
    }

    $full = "$Script:GithubOwner/$slug"
    $already = Test-GhRepoExists -FullName $full

    if ($already) {
      Set-OriginToJunDeveRepo -RepoSlug $slug
      Write-HookJson -Permission "deny" -UserMessage "[SYNC] 원격 저장소를 확인했습니다. origin을 https://github.com/$full 로 맞췄습니다." -AgentMessage "Handled trigger: create:: (existing)"
      exit 0
    }

    Ensure-GhForMakeTrigger

    $originPresent = $null -ne (Get-OriginUrl)
    if (-not $originPresent) {
      Invoke-Cli "gh repo create $full --private --source . --remote origin"
    }
    else {
      Invoke-Cli "gh repo create $full --private"
      Set-OriginToJunDeveRepo -RepoSlug $slug
    }
    Write-SyncState -Owner $Script:GithubOwner -Repo $slug
    Write-HookJson -Permission "deny" -UserMessage "[SYNC] 새 레포 생성 및 연결 완료: https://github.com/$full" -AgentMessage "Handled trigger: create::"
    exit 0
  }

  if ($isUp) {
    $commitMessage = $userPrompt.Substring("up::".Length).Trim()
    if ([string]::IsNullOrWhiteSpace($commitMessage)) {
      Write-HookJson -Permission "deny" -UserMessage "[SYNC] 형식 오류: up::commit message 형식으로 입력하세요." -AgentMessage "Missing commit message."
      exit 0
    }

    $slug = Resolve-TargetRepoSlug
    if ([string]::IsNullOrWhiteSpace($slug)) {
      Write-HookJson -Permission "deny" -UserMessage "[SYNC] 대상 레포를 알 수 없습니다. `create::repo-name`으로 먼저 지정하거나 origin을 JunDeve/* 로 설정하세요." -AgentMessage "No repo slug resolved."
      exit 0
    }

    Ensure-OriginForSlug -RepoSlug $slug -CreateRepoIfMissing $true

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
    }
    else {
      Invoke-Git "git push -u origin $branch" | Out-Null
    }
    Write-HookJson -Permission "deny" -UserMessage "[SYNC] 업로드 완료: https://github.com/$Script:GithubOwner/$slug ($branch) — $commitMessage" -AgentMessage "Handled trigger: up::"
    exit 0
  }

  if ($isDown) {
    $pullMessage = $userPrompt.Substring("down::".Length).Trim()
    if ([string]::IsNullOrWhiteSpace($pullMessage)) {
      Write-HookJson -Permission "deny" -UserMessage "[SYNC] 형식 오류: down::note 형식으로 입력하세요." -AgentMessage "Missing message for download trigger."
      exit 0
    }

    $slug = Resolve-TargetRepoSlug
    if ([string]::IsNullOrWhiteSpace($slug)) {
      Write-HookJson -Permission "deny" -UserMessage "[SYNC] 대상 레포를 알 수 없습니다. `create::repo-name`으로 먼저 지정하거나 origin을 JunDeve/* 로 설정하세요." -AgentMessage "No repo slug resolved."
      exit 0
    }

    Ensure-OriginForSlug -RepoSlug $slug -CreateRepoIfMissing $false

    Invoke-Git "git pull --rebase origin $branch" | Out-Null
    Write-HookJson -Permission "deny" -UserMessage "[SYNC] 내려받기 완료: https://github.com/$Script:GithubOwner/$slug ($branch) — $pullMessage" -AgentMessage "Handled trigger: down::"
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
