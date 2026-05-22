# ai-common-rules

**Claude Code 전용** 플러그인. 하네스(행동 규칙) + 스킬(작업 도구) + MCP 서버를 한 번의 설치로 제어합니다.
플래닝·태스크 추적은 Claude Code 내장 기능(플랜 모드, TodoWrite)에 위임합니다.

> English documentation: [README.md](README.md)

---

## 전체 구성

| 컴포넌트 | 이름 | 유형 | 역할 |
|---|---|---|---|
| **하네스** | `CLAUDE.md` | 자동 주입 규칙 | 모든 세션에서 Claude의 행동 제어 — MODE 시스템, 응답 식별자, 보안 가드레일, 승인 워크플로우, 토큰 압축, 안티패턴 누적 |
| **스킬** | `/grill-me` | 온디맨드 슬래시 커맨드 | 코드 작성 전 플랜을 결정 트리 기반으로 한 질문씩 스트레스 테스트 |
| **스킬** | `/improve-codebase-architecture` | 온디맨드 슬래시 커맨드 | 얕은 모듈 탐지 → 리팩터 기회 제안 → 협업 설계 |
| **스킬** | `/frontend-design` | 온디맨드 슬래시 커맨드 | 코딩 전 명확한 미적 방향을 확정하고 개성 있는 프로덕션 UI 생성 |
| **MCP** | Playwright | 항시 가동 브라우저 제어 | `browser_*` 툴로 웹 페이지 탐색·조작·검사를 Claude가 직접 수행 |
| **MCP** | Context7 | 항시 가동 문서 조회 | 실시간 공식 문서 fetch → 할루시네이션·deprecated API 방지 |

---

## 구조

```
ai-common-rules/
├── .claude-plugin/
│   └── plugin.json                    ← 플러그인 매니페스트 + 번들 MCP 서버 (Playwright, Context7)
├── CLAUDE.md                          ← 하네스 규칙 (매 세션 자동 주입)
├── PATTERNS.md                        ← M/L 안티패턴 (온디맨드, 부정 피드백 시 로드)
├── PLAYWRIGHT.md                      ← Playwright MCP 규칙 (온디맨드, 브라우저 작업 시 로드)
└── skills/
    ├── grill-me/
    │   └── SKILL.md                   ← /grill-me 슬래시 커맨드
    ├── improve-codebase-architecture/
    │   └── SKILL.md                   ← /improve-codebase-architecture 슬래시 커맨드
    └── frontend-design/
        └── SKILL.md                   ← /frontend-design 슬래시 커맨드
```

---

## 설치

### A — Claude Code CLI

클론 후 Claude Code 내에서 1회 실행:
```
/plugin add <ai-common-rules 경로>
/plugin enable ai-common-rules
```

### B — Claude 데스크탑 앱

1. 이 저장소 클론
2. 폴더 전체를 zip으로 압축 (`.claude-plugin/plugin.json` 포함 필수)
3. Claude 데스크탑 → **Code** 탭 → **Customize** → **개인 플러그인** → **플러그인 생성** → **플러그인 업로드**
4. `.zip` 파일 업로드

압축 명령어 (PowerShell):
```powershell
Compress-Archive -Path "<ai-common-rules 경로>\*" -DestinationPath "ai-common-rules.zip"
```

업로드 완료 후 사이드바 **Personal Plugins** 아래에서 ON/OFF 토글 가능.

---

## 하네스 (CLAUDE.md)

플러그인 활성화 시 매 세션 자동 주입. 별도 호출 불필요.

### 역할

- **MODE 시스템** — 응답 첫 줄에 현재 모드 선언 필수. 모드 범위 밖의 행동은 차단됨.

| Mode | 허용 | 차단 |
|---|---|---|
| `[MODE:EXPLORE]` | 파일 읽기·검색 | 수정·실행 |
| `[MODE:EXECUTE]` | 파일 수정·명령 실행 | 승인 범위 외 모든 행동 |
| `[MODE:REVIEW]` | Delta 보고·보안 스캔 | 새 작업 시작 |

- **응답 식별자** — 중요 행동에는 필수 식별자로 의도 명시, 그 외에는 선택 식별자로 명확성 보완.

**필수 (조건 충족 시 반드시 사용):**

| 식별자 | 사용 조건 |
|---|---|
| `[PLAN]` | 미실행 계획, 사용자 승인 대기 |
| `[CAUTION]` | 파괴적 작업 전 경고 — 재승인 필수 |
| `[CRITICAL]` | 보안 위협 — 즉시 중단 |
| `[CONFIDENCE:LOW]` | 추론 불확실성 높음 |

**선택 (명확성 필요 시 사용):**
`[ANALYSIS]` `[CODE]` `[INFO]` `[QUESTION]` `[REF]`

- **승인 워크플로우** — 실행 전 목적·대상 파일·영향 범위·보안 체크 보고 필수. 명시적 승인 후에만 실행 시작.

- **보안 가드레일** — API Key·secrets 마스킹(`[MASKED]`), 시스템 경로 차단(`[CRITICAL]`), 영향 파일 5개↑ 시 `[CAUTION]` + Git checkpoint 권고.

- **토큰 압축 (Caveman Lite)** — 관사·필러·인사 제거. 단편 문장·약어·인과 화살표 사용. `[CAUTION]`/`[CRITICAL]` 블록에서는 압축 해제.

- **안티패턴 누적** — 부정 피드백 수신 시 `PATTERNS.md`를 직접 읽어 항목 추가 제안. Hits ≥ 3 항목은 `CLAUDE.md` 항상 적용 티어 승급 검토.

- **Playwright MCP 규칙** — Snapshot 우선 워크플로우, capability 게이팅, 보안 가드레일 적용. 전체 규칙은 `PLAYWRIGHT.md`에 기재 (브라우저 작업 시 온디맨드 로드).

---

## 스킬

슬래시 커맨드 — 호출 전까지 비활성 상태.

### `/grill-me`

**역할:** 실행 전 플랜을 스트레스 테스트. 결정 트리의 모든 가지를 해소해 성급한 `[PLAN]` 제출을 방지.

**언제 사용:** 비자명한 작업을 시작하기 전. 호출 후 계획을 설명하면 Claude가 한 번에 한 질문씩 인터뷰.

```
/grill-me
auth 모듈을 세션 방식에서 JWT로 리팩터할 계획이야
```

실행 흐름:
1. 범위·리스크·대안·엣지케이스를 한 질문씩 확인
2. 각 질문에 권장 답변 제시
3. 코드베이스를 직접 탐색해 스스로 답할 수 있는 질문은 자동 처리
4. 결정 트리가 완전히 해소될 때까지 반복

---

### `/improve-codebase-architecture`

**역할:** 코드베이스의 구조적 개선 기회 탐지. 얕은 모듈을 찾아내고 리팩터를 제안하며 협업 설계를 진행.

**언제 사용:** 코드베이스가 탐색하기 어렵거나, 모듈 간 결합이 강하거나, 테스트 가능성을 높이고 싶을 때.

```
/improve-codebase-architecture
```

실행 흐름:
1. `CONTEXT.md`(도메인 용어 사전)와 `docs/adr/`(아키텍처 결정 기록) 읽기 (존재 시)
2. 인터페이스 레버리지가 낮은 모듈(깊이 개선 후보) 목록 제시
3. 후보 선택 → Claude와 함께 설계 트리 탐색
4. 부수 효과: 미지 용어는 `CONTEXT.md`에 추가, 기각된 후보는 `docs/adr/`에 ADR 제안

최초 실행 시 프로젝트에 자동 생성:
- `CONTEXT.md` — 도메인 용어 사전
- `docs/adr/` — 아키텍처 결정 기록

---

### `/frontend-design`

**역할:** 코딩 전 명확한 미적 방향을 확정하고 개성 있는 프로덕션 UI 생성. AI 기본값(Inter 폰트, 보라 그라디언트, 예측 가능한 레이아웃) 회피.

**언제 사용:** 컴포넌트·페이지·앱을 통계적 평균이 아닌 의도된 디자인으로 만들고 싶을 때.

```
/frontend-design
로그인 페이지 만들어줘, React 기반
```

실행 흐름:
1. 목적·대상·기술 제약 분석
2. 코딩 전 구체적인 미적 방향 확정 (예: brutalist, retro-futuristic, editorial 등)
3. 해당 방향에 맞는 타이포·색상·모션·레이아웃이 적용된 프로덕션 코드 출력 (HTML/CSS/JS, React, Vue 등)
4. 매 생성마다 의도적으로 다른 결과 — 동일한 스타일로 수렴하지 않음

---

## MCP 서버 (항시 가동)

모두 `plugin.json`에 번들되어 플러그인 활성화 시 자동 시작. 별도 설치·API 키 불필요.

### Playwright

**역할:** Claude가 브라우저를 직접 제어 — 페이지 탐색, 요소 클릭, 폼 입력, 스크린샷, 접근성 트리 검사 등.

**동작 방식:** 기본적으로 Snapshot 모드 사용 (접근성 트리 → ref 기반 조작, ~300 토큰). Vision 모드는 접근성 트리를 사용할 수 없는 캔버스·SVG UI에만 사용.

| 툴 카테고리 | 예시 |
|---|---|
| 탐색 | `browser_navigate`, `browser_navigate_back` |
| 조작 | `browser_click`, `browser_fill`, `browser_type`, `browser_select_option` |
| 검사 | `browser_snapshot` (권장), `browser_take_screenshot` |
| 유틸리티 | `browser_wait_for`, `browser_evaluate`, `browser_close` |

표준 워크플로우: `browser_navigate` → `browser_snapshot` → ref로 조작 → `browser_snapshot` → 반복 → `browser_close`

하네스 규칙(Snapshot 우선, capability 게이팅, 보안 가드레일)은 `CLAUDE.md`를 통해 자동 적용.

### Context7

**역할:** Claude가 작업 중인 라이브러리·프레임워크의 최신 공식 문서를 실시간으로 가져옴. 잘못된 props·deprecated API·버전 불일치 방지.

**동작 방식:** React, Next.js, Tailwind 등 알려진 라이브러리 코드 작성 시 Context7이 실시간 레지스트리를 조회해 정확한 API 레퍼런스를 컨텍스트에 주입.

별도 설정 불필요. 플러그인 활성화만 하면 즉시 동작.

---

## 플래닝 및 태스크 추적

별도 상태 파일 없음. Claude Code 내장 기능 사용:

| 역할 | 도구 |
|---|---|
| 계획 수립 | Claude Code 플랜 모드 |
| 태스크 추적 | TodoWrite |
| 플랜 스트레스 테스트 | `/grill-me` |
| 구조 개선 | `/improve-codebase-architecture` |
| UI 생성 | `/frontend-design` |
