# ai-common-rules

**Claude Code 전용** 플러그인. 하네스(행동 규칙) + 스킬(작업 도구)을 한 곳에서 제어합니다.
플래닝·태스크 추적은 Claude Code 내장 기능(플랜 모드, TodoWrite)에 위임합니다.

> English documentation: [README.md](README.md)

---

## 구조

```
ai-common-rules/
├── .claude-plugin/
│   └── plugin.json                    ← 플러그인 매니페스트 (데스크탑 앱 업로드 시 필수)
├── CLAUDE.md                          ← 플러그인 활성화 시 하네스 규칙 자동 주입
├── .ai/                               ← 하네스 소스 (편집 대상)
│   ├── AI_COMMON_RULES.md             ← 행동 규칙, 식별자, 모드, 보안, 토큰 압축
│   └── PATTERNS.md                    ← 안티패턴 DB (부정 피드백 발생 시 누적)
└── skills/
    ├── grill-me/
    │   └── SKILL.md                   ← /grill-me 슬래시 커맨드
    └── improve-codebase-architecture/
        └── SKILL.md                   ← /improve-codebase-architecture 슬래시 커맨드
```

---

## 설치

### A — Claude Code CLI

클론 후 Claude Code 내에서 1회 실행:
```
/plugin add <ai-common-rules 경로>
```

활성화:
```
/plugin enable ai-common-rules
```

### B — Claude 데스크탑 앱 (Customize → 플러그인 업로드)

1. 이 저장소 클론
2. 폴더 전체를 zip으로 압축 (`.claude-plugin/plugin.json` 포함 필수)
3. Claude 데스크탑 → **Code** 탭 → **Customize** → **개인 플러그인 +** → **플러그인 업로드**
4. `.zip` 파일 업로드

압축 명령어 (PowerShell):
```powershell
Compress-Archive -Path "<ai-common-rules 경로>\*" -DestinationPath "ai-common-rules.zip"
```

업로드 완료 후 사이드바 **개인 플러그인** 아래에 표시됨 → 거기서 ON/OFF 토글 가능.

---

## 제어

### 하네스 + 스킬 전체

| 명령 | 효과 |
|---|---|
| `/plugin enable ai-common-rules` | 하네스 규칙 주입 ON + 스킬 사용 가능 |
| `/plugin disable ai-common-rules` | 전체 OFF |

### 스킬 (호출 시에만 동작)

| 명령 | 용도 |
|---|---|
| `/grill-me` | `[PLAN]` 제출 전 설계 검증. 결정 트리를 질문 하나씩 스트레스 테스트. |
| `/improve-codebase-architecture` | 코드베이스 구조 분석. 얕은 모듈 탐지 → 깊이 있는 구조 제안 → 협업 설계. |

스킬은 슬래시 커맨드로만 동작 → 호출 전까지 비활성 상태.

---

## 하네스 규칙 (AI_COMMON_RULES.md)

플러그인 활성화 시 매 세션 자동 주입되는 행동 헌법.

### MODE 시스템
| Mode | 허용 | 차단 |
|---|---|---|
| `[MODE:EXPLORE]` | 파일 읽기·검색 | 수정·실행 |
| `[MODE:EXECUTE]` | 파일 수정·명령 실행 | 승인 범위 외 |
| `[MODE:REVIEW]` | Delta 보고·보안 스캔 | 새 작업 시작 |

응답 첫 줄에 현재 모드 명시 필수.

### 식별자 (응답 첫 줄 필수)
| 식별자 | 사용 조건 |
|---|---|
| `[PLAN]` | 미실행 계획, 승인 대기 |
| `[ANALYSIS]` | 근거·분석·trade-off |
| `[CODE]` | 구현·수정·패치 |
| `[INFO]` | 상태·일반정보 |
| `[QUESTION]` | 사용자 결정 요청 |
| `[CAUTION]` | 파괴적 작업 전 경고, 재승인 필수 |
| `[CRITICAL]` | 보안 위협·즉시 중단 |

### 보안 가드레일
- API Key, secrets 내용 출력 금지 → `[MASKED]`
- 시스템 경로 접근 차단 → `[CRITICAL]`
- 영향 파일 5개↑ → `[CAUTION]` + Git checkpoint 권고
- 삭제·덮어쓰기 전 `[CAUTION]` + 재승인 필수

### 토큰 압축 — Caveman Lite
[Caveman](https://github.com/JuliusBrussee/caveman) (by Julius Brussee)의 압축 원칙을 참조하여
식별자·Delta Report·코드 블록과 충돌하지 않도록 경량화한 규칙.

- 관사(a/an/the), 필러(just, really, basically), 인사(sure, certainly) 제거
- 단편 문장, 약어(DB, auth, config, fn), 인과 화살표(X → Y) 사용
- `[CAUTION]`·`[CRITICAL]` 블록에서는 압축 해제, 명확성 우선

### 안티패턴 누적 (PATTERNS.md)
부정 피드백("틀렸어", "그렇게 하지 마") 수신 시 PATTERNS.md에 항목 추가 제안.
Hits ≥ 3 항목은 Tier 승급 검토.

---

## 플래닝 및 태스크 추적

별도 상태 파일 없음. Claude Code 내장 기능 사용:

| 역할 | 도구 |
|---|---|
| 계획 수립 | Claude Code 플랜 모드 |
| 태스크 추적 | TodoWrite |
| 설계 검증 | `/grill-me` |
| 구조 개선 | `/improve-codebase-architecture` |

`/improve-codebase-architecture` 최초 실행 시 프로젝트에 자동 생성:
- `CONTEXT.md` — 도메인 용어 사전
- `docs/adr/` — 아키텍처 결정 기록
