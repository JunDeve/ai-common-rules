# Git Hook 설치 및 환경 설정 스크립트 (수정본)

$HookSourceDir = "$PSScriptRoot\..\.githooks"
$GitHookDir = "$PSScriptRoot\..\.git\hooks"

if (!(Test-Path $HookSourceDir)) { New-Item -ItemType Directory -Path $HookSourceDir -Force }

# 1. post-commit (커밋 후 자동 Push)
# PowerShell에서 변수 확장을 방지하기 위해 단일 인용부호('')를 사용한 Heredoc 적용
$PostCommitContent = @'
#!/bin/sh
echo "[INFO] Commited successfully. Attempting to push to remote..."
REMOTE_URL=$(git remote get-url origin 2>/dev/null)

if [ -z "$REMOTE_URL" ]; then
    echo "[WARNING] Remote 'origin' is not set. Skipping auto-push."
    echo "          To set it: git remote add origin <your-repo-url>"
else
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
    git push origin "$BRANCH"
    if [ $? -eq 0 ]; then
        echo "[SUCCESS] Pushed to GitHub automatically."
    else
        echo "[ERROR] Push failed. Please check your network or remote permissions."
    fi
fi
'@

Set-Content -Path "$HookSourceDir\post-commit" -Value $PostCommitContent -Encoding Utf8

# 2. post-merge (Pull 후 자동 날짜 기록)
$PostMergeContent = @'
#!/bin/sh
LOG_FILE="SYNC_LOG.md"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

if [ ! -f "$LOG_FILE" ]; then
    echo "# Project Sync History" > "$LOG_FILE"
    echo "| Date | Action | Status |" >> "$LOG_FILE"
    echo "| :--- | :--- | :--- |" >> "$LOG_FILE"
fi

echo "| $DATE | Download (Pull) | SUCCESS |" >> "$LOG_FILE"
echo "[INFO] Sync date recorded in $LOG_FILE"
'@

Set-Content -Path "$HookSourceDir\post-merge" -Value $PostMergeContent -Encoding Utf8

# .git/hooks 폴더로 복사 및 실행 권한 부여 (Git Bash용)
Write-Host "Installing hooks to .git/hooks..." -ForegroundColor Cyan
Copy-Item -Path "$HookSourceDir\post-commit" -Destination "$GitHookDir\post-commit" -Force
Copy-Item -Path "$HookSourceDir\post-merge" -Destination "$GitHookDir\post-merge" -Force

Write-Host "Hooks installed successfully!" -ForegroundColor Green
