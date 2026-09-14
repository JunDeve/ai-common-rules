# ai-common-rules

**Claude Code 전용.** 이 저장소는 **플러그인이자 그 자체로 마켓플레이스**입니다 — 한 번의 설치로 하네스(행동 규칙), 스킬, MCP 서버 2종, 그리고 의존성으로 묶인 업스트림 플러그인까지 전부 따라옵니다.

```bash
claude plugin marketplace add JunDeve/ai-common-rules
```
```bash
claude plugin install ai-common-rules@ai-common-rules-marketplace
```

전체 절차: [설치](#설치)

플래닝·태스크 추적은 Claude Code 내장 기능(플랜 모드, TodoWrite)에 위임합니다.

> English documentation: [README.md](README.md)

---

## 전체 구성

| 컴포넌트 | 이름 | 유형 | 역할 |
|---|---|---|---|
| **하네스** | `CLAUDE.md` | 자동 주입 규칙 | 모든 세션에서 Claude의 행동 제어 — 응답 식별자, 보안 가드레일, 승인 워크플로우, 토큰 압축, 안티패턴 누적 |
| **스킬** | `/grill-me` | 온디맨드 슬래시 커맨드 | 코드 작성 전 플랜을 결정 트리 기반으로 한 질문씩 스트레스 테스트 |
| **스킬** | `/improve-codebase-architecture` | 온디맨드 슬래시 커맨드 | 얕은 모듈 탐지 → 리팩터 기회 제안 → 협업 설계 |
| **스킬** | `/frontend-design` | 온디맨드 슬래시 커맨드 | 코딩 전 명확한 미적 방향을 확정하고 개성 있는 프로덕션 UI 생성 |
| **스킬** | `/next-move` | 온디맨드 슬래시 커맨드 | 방치된 프로젝트의 중단 지점을 저장소 증거로 복원 → 다음 한 수 3개 제시 |
| **MCP** | Playwright | 항시 가동 브라우저 제어 | `browser_*` 툴로 웹 페이지 탐색·조작·검사를 Claude가 직접 수행 |
| **MCP** | Context7 | 항시 가동 문서 조회 | 실시간 공식 문서 fetch → 할루시네이션·deprecated API 방지 |
| **의존성** | `superpowers` | 자동 설치 플러그인 | `brainstorm → spec → plan → TDD` 실행 방법론, 체계적 디버깅, git 브랜치 워크플로 |
| **의존성** | `superpowers-developing-for-claude-code` | 자동 설치 플러그인 | 플러그인·스킬·MCP 서버 제작용 스킬 + 공식 문서 동봉 |

---

## 명령어 한눈에

**새 PC 설치** — 클론 후 스크립트 1개. 그게 전부.

```bash
git clone https://github.com/JunDeve/ai-common-rules && cd ai-common-rules
```
```bash
powershell -ExecutionPolicy Bypass -File install.ps1
```

macOS·Linux·Git Bash에서는 `./install.sh`. 끝나면 Claude Code 재시작.
상세 절차와 수동 설치: [설치](#설치)

**이 플러그인의 슬래시 커맨드**

| 커맨드 | 역할 |
|---|---|
| `/next-move` | 방치된 프로젝트의 중단 지점 복원 → 다음 한 수 3개 제시 |
| `/grill-me` | 결정 트리의 모든 가지가 해소될 때까지 계획을 한 질문씩 추궁 |
| `/improve-codebase-architecture` | 얕은 모듈 탐지 → 깊게 만드는 리팩터 제안 |
| `/frontend-design` | 의도된 미적 방향을 확정하고 UI 구현 |

**의존성이 제공하는 스킬** — 대부분 직접 타이핑하지 않고 상황에 맞춰 Claude가
자동 호출합니다. 이름을 알아둘 만한 것들:

| 스킬 | 언제 개입하나 |
|---|---|
| `brainstorming` | 창작 작업 전 — 아이디어를 승인된 설계로 |
| `writing-plans` | 승인된 설계를 구현 계획으로 |
| `test-driven-development` | 구현 코드를 쓰기 전 |
| `systematic-debugging` | 버그·예상 밖 동작 발생 시, 수정안 제시 전 |
| `requesting-code-review` | 머지 전 |
| `verification-before-completion` | "완료" 주장 전 — 증거를 요구 |
| `developing-claude-code-plugins` | 플러그인 작업 시 (이 저장소 포함) |

**설치 관리**

| 작업 | 명령 |
|---|---|
| 설치 현황 확인 | `claude plugin list` |
| 지금 바로 갱신 | `claude plugin marketplace update ai-common-rules-marketplace` |
| 제거 | `claude plugin uninstall ai-common-rules@ai-common-rules-marketplace` |
| 저장소 자체 검증 | `python scripts/validate.py` |

`autoUpdate`가 켜져 있으면 백그라운드 갱신은 알아서 돌아갑니다 — 설치 스크립트가
켜줍니다. [방치해도 최신 상태 유지하기](#방치해도-최신-상태-유지하기) 참조.

---

## 구조

```
ai-common-rules/
├── .claude-plugin/
│   ├── marketplace.json               ← 마켓플레이스 카탈로그 (이 repo + 업스트림 플러그인)
│   └── plugin.json                    ← 플러그인 매니페스트 + 의존성 + MCP 서버 (Playwright, Context7)
├── install.ps1                        ← 원커맨드 설치 스크립트 (Windows PowerShell)
├── install.sh                         ← 원커맨드 설치 스크립트 (macOS / Linux / Git Bash)
├── scripts/
│   └── validate.py                    ← 구조 검증. CI와 로컬 양쪽에서 실행
├── .github/workflows/
│   └── validate.yml                   ← 모든 push·PR에서 검증 실행
├── CLAUDE.md                          ← 하네스 규칙 (매 세션 자동 주입)
├── PATTERNS.md                        ← M/L 안티패턴 (온디맨드, 부정 피드백 시 로드)
├── PLAYWRIGHT.md                      ← Playwright MCP 규칙 (온디맨드, 브라우저 작업 시 로드)
└── skills/
    ├── grill-me/
    │   └── SKILL.md                   ← /grill-me 슬래시 커맨드
    ├── improve-codebase-architecture/
    │   └── SKILL.md                   ← /improve-codebase-architecture 슬래시 커맨드
    ├── frontend-design/
    │   └── SKILL.md                   ← /frontend-design 슬래시 커맨드
    └── next-move/
        └── SKILL.md                   ← /next-move 슬래시 커맨드
```

---

## 설치

### 사전 조건

| 요구사항 | 이유 | 확인 명령 |
|---|---|---|
| Claude Code CLI | 아래 모든 명령의 실행 주체 | `claude --version` |
| Node.js + `npx` | Playwright·Context7 MCP 서버가 `npx`로 기동 | `npx --version` |
| GitHub HTTPS 접근 | 마켓플레이스를 `git`으로 clone·갱신 | `git ls-remote https://github.com/JunDeve/ai-common-rules` |

Claude Code v2.1.116 이상에서 검증됨.

### 한 번에 설치 (권장)

저장소를 클론하고 쉘에 맞는 설치 스크립트를 실행하세요. 마켓플레이스 등록 →
의존성 포함 플러그인 설치 → 결과 목록 출력까지 한 번에 처리합니다. 여러 번
실행해도 안전합니다.

```bash
git clone https://github.com/JunDeve/ai-common-rules && cd ai-common-rules
```

**Windows** — `install.ps1` 우클릭 → *PowerShell로 실행*, 또는:

```bash
powershell -ExecutionPolicy Bypass -File install.ps1
```

**macOS / Linux / Git Bash**

```bash
./install.sh
```

두 스크립트 모두 시작 전에 `claude`가 PATH에 있는지 확인하고, `npx`가 없으면
MCP 서버가 기동되지 않는다는 경고만 띄우고 진행하며, 이미 등록된 마켓플레이스는
오류가 아니라 성공으로 처리합니다.

### 터미널 없이 클릭만

Claude 데스크탑 앱에서: **Code** 탭 → **Customize** → **개인 플러그인** →
`JunDeve/ai-common-rules`를 마켓플레이스로 추가 → `ai-common-rules` 설치.
의존성은 CLI와 동일하게 자동 해석됩니다.

> `settings.json`에 적어두는 것만으로는 **안 됩니다.** `extraKnownMarketplaces`로
> 마켓플레이스는 등록되지만, 소스가 외부 저장소인 플러그인은 여전히 설치 과정이
> 필요합니다 — 설정은 활성화만 할 뿐 내려받지 않습니다.

### 새 PC에 설치 (단계별)

**1. 이 저장소를 마켓플레이스로 등록**

```bash
claude plugin marketplace add JunDeve/ai-common-rules
```

정상 출력 마지막 줄: `✔ Successfully added marketplace: ai-common-rules-marketplace`

**2. 플러그인 설치**

```bash
claude plugin install ai-common-rules@ai-common-rules-marketplace
```

`superpowers`와 `superpowers-developing-for-claude-code`는 `plugin.json`에 `dependencies`로 선언돼 있어 **같은 단계에서 자동으로 설치·활성화**됩니다. 따로 설치하지 마세요.

**3. 검증**

```bash
claude plugin list
```

3개 전부 `✔ enabled`, 전부 `@ai-common-rules-marketplace` 소속이어야 정상:

```
❯ ai-common-rules@ai-common-rules-marketplace                        enabled
❯ superpowers@ai-common-rules-marketplace                            enabled
❯ superpowers-developing-for-claude-code@ai-common-rules-marketplace enabled
```

**4. Claude Code 재시작** (또는 `/reload-plugins`) — 하네스와 MCP 서버가 로드됩니다.

### 구버전이 설치된 PC 마이그레이션

**반드시 제거 후 설치.** 같은 이름의 플러그인이 서로 다른 마켓플레이스에서 2개 설치되면 둘 다 로드되어 스킬이 중복 주입됩니다.

```bash
claude plugin uninstall ai-common-rules@local-desktop-app-uploads
```
```bash
claude plugin uninstall superpowers@superpowers-marketplace
```
```bash
claude plugin marketplace remove superpowers-marketplace
```
```bash
claude plugin marketplace remove local-desktop-app-uploads
```

이후 위 *새 PC에 설치* 절차를 그대로 진행.

> **Windows PowerShell 5.1 주의:** `&&`는 문 구분 기호로 동작하지 않습니다 — `'&&' 토큰은 이 버전에서 올바른 문 구분 기호가 아닙니다.` 한 줄에 하나씩 실행하거나 `;` / `if ($?) { ... }`로 연결하세요.

### 방치해도 최신 상태 유지하기

업스트림을 복사하지 않고 링크로 가져오는 방식은 **그 링크가 실제로 움직일 때만**
값어치가 있습니다. 그런데 **서드파티 마켓플레이스는 자동 갱신이 꺼진 채 설치됩니다** —
누군가 수동으로 update를 치기 전까지 아무것도 올라가지 않고, 방치된 프로젝트에는
바로 그 수동 조작이 영영 없습니다.

설치 스크립트가 이 설정을 켭니다. 수동으로 구성했다면 `~/.claude/settings.json`의
마켓플레이스 항목에 `autoUpdate`를 추가하세요:

```json
{
  "extraKnownMarketplaces": {
    "ai-common-rules-marketplace": {
      "source": { "source": "github", "repo": "JunDeve/ai-common-rules" },
      "autoUpdate": true
    }
  }
}
```

이 설정이 있으면 Claude Code가 세션 시작 직후 백그라운드에서 마켓플레이스를 갱신하고
설치된 플러그인을 최신 버전으로 올립니다 — 이 플러그인과 업스트림 의존성 2종 전부,
명령 한 줄 없이.

> **git submodule은 왜 안 쓰나?** submodule은 **특정 커밋에 고정**하는 장치입니다.
> 올리려면 `git submodule update --remote` → 커밋 → 푸시를 사람이 직접, 매번 해야
> 하고 clone에도 `--recursive`가 필요합니다. "방치해도 최신"과 정반대죠. 마켓플레이스
> `source` 링크는 SHA를 고정하지 않아 업스트림의 릴리스가 그대로 흘러들어옵니다.

### 필요할 때 즉시 갱신

백그라운드 갱신을 기다리지 않고 바로 당기려면:

```bash
claude plugin marketplace update ai-common-rules-marketplace
```
```bash
claude plugin update ai-common-rules@ai-common-rules-marketplace
```

릴리스마다 `.claude-plugin/plugin.json`의 `version`을 올릴 것 — 캐시된 버전과 같으면 Claude Code가 갱신을 건너뜁니다.

기본 브랜치 대신 특정 태그에 고정하려면:

```bash
claude plugin marketplace add JunDeve/ai-common-rules@v2.2.0
```

### 제거

```bash
claude plugin uninstall ai-common-rules@ai-common-rules-marketplace
```
```bash
claude plugin prune
```

`prune`은 더 이상 필요 없어진 의존성 2종을 정리합니다. 카탈로그까지 지우려면 `claude plugin marketplace remove ai-common-rules-marketplace`.

### 로컬 개발용

설치 없이 작업 사본을 바로 로드:

```bash
claude --plugin-dir <ai-common-rules 경로>
```

### Claude 데스크탑 앱 (수동 업로드)

GitHub 접근이 불가할 때만. 폴더를 zip으로 압축(`.claude-plugin/plugin.json` 포함 필수) → **Code** 탭 → **Customize** → **개인 플러그인** → **플러그인 업로드**.

> 수동 업로드본은 **자동 갱신되지 않고 `dependencies`도 해석하지 않습니다** — Superpowers를 따로 설치해야 합니다. 마켓플레이스 방식을 권장합니다.

---

## 흡수한 업스트림 플러그인

마켓플레이스가 업스트림 저장소를 **링크만** 합니다 — 코드 복사본도, submodule도 없음. 각자의 릴리스 라인에서 독립적으로 갱신됩니다.

| 플러그인 | 업스트림 | 역할 |
|---|---|---|
| `superpowers` | [obra/superpowers](https://github.com/obra/superpowers) | `brainstorm → spec → plan → TDD` 실행 방법론, 체계적 디버깅, git 브랜치 워크플로 |
| `superpowers-developing-for-claude-code` | [obra/superpowers-developing-for-claude-code](https://github.com/obra/superpowers-developing-for-claude-code) | 플러그인·스킬·MCP 서버 제작용 스킬 + 공식 문서 동봉 |

입맛대로 고치고 싶어지면 → fork 후 `.claude-plugin/marketplace.json`의 `source` URL 한 줄만 교체. 구조 변경 불필요.

---

## 하네스 (CLAUDE.md)

플러그인 활성화 시 매 세션 자동 주입. 별도 호출 불필요.

### 역할

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

- **토큰 압축 (Caveman Lite)** — 관사·필러·인사 제거. 단편 문장·약어·인과 화살표 사용. `[CAUTION]`/`[CRITICAL]` 블록에서는 압축 해제. 이름·발상은 [`JuliusBrussee/caveman`](https://github.com/JuliusBrussee/caveman)에서 인용 — 차이점은 [아래](#caveman--토큰-압축-인용이지-복제가-아니다) 참조.

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

### `/next-move`

**역할:** 저장소의 증거로 프로젝트가 어디서 멈췄는지 복원하고, 다음 한 수 후보 3개를 제시한 뒤 선택된 것을 `writing-plans`로 넘김.

**언제 사용:** 오랜만에 프로젝트를 다시 열 때, 넘겨받은 낯선 저장소를 파악할 때, "여기서 뭘 해야 하지?"에 대한 솔직한 답이 "기억 안 남"일 때.

```
/next-move
```

실행 흐름:

1. **정적 수집** — 커밋 리듬, 브랜치 divergence, stash, 미커밋 작업, 날짜가 매겨진 `TODO`/`FIXME`, 마커파일 기반 스택 탐지, README 주장과 실제의 대조, CI 존재 여부. 읽기 전용, 부작용 없음.
2. **타임라인** — 증거가 말해주는 것만 한 문단으로 서술. 모든 주장은 수집값으로 역추적 가능하며, 의도는 추측하지 않음.
3. **실행 게이트** — 빌드·테스트는 `[CAUTION]` 승인 후에만 실행. 의존성 설치는 작업 트리를 변경하므로 테스트 실행과 분리해 고지. 거부해도 스캔은 중단되지 않고, 검증 수준이 낮아진 사실이 기록됨.
4. **후보** — 3개, 각각 근거가 된 증거를 명시하고 임팩트·비용·리스크를 H/M/L로 표기. **작업을 폐기하는 것도 정당한 후보.** 하나를 고르면 `PROJECT_STATE.md`를 쓰고 `writing-plans`를 호출.

실행 명령은 스킬에 하드코딩하지 않고 탐지된 마커파일에서 읽어냅니다 — 새 생태계 지원에 추가 비용이 없습니다. 일치하는 마커파일이 없으면 추측하지 않고 질문합니다.

산출물과 stale 판정 기준은 [`PROJECT_STATE.md`](#project_statemd) 참조.

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

플래닝·태스크 추적은 Claude Code 내장 기능에 그대로 위임합니다. 이 플러그인이
쓰는 유일한 파일은 `PROJECT_STATE.md`이고, 이것은 `/next-move`의 **산출물**이지
작업 중 계속 갱신되는 로그가 아닙니다.

| 역할 | 도구 |
|---|---|
| 계획 수립 | Claude Code 플랜 모드 |
| 태스크 추적 | TodoWrite |
| 방치된 프로젝트 복귀 | `/next-move` |
| 플랜 스트레스 테스트 | `/grill-me` |
| 구조 개선 | `/improve-codebase-architecture` |
| UI 생성 | `/frontend-design` |

### `PROJECT_STATE.md`

`/next-move`가 스캔을 마칠 때 대상 프로젝트 루트에 생성됩니다. 어디서 멈췄는지,
그 판단의 근거가 된 증거, 제시된 후보와 선택된 후보를 기록합니다.

나중 세션이 이 문서를 신뢰해도 되는지는 두 필드가 결정합니다:

- `Verified:` — 실제로 검증된 범위. 실행 게이트를 거부했다면 "빌드·테스트 미실행"이
  문서에 박히므로, 돌린 적 없는 테스트를 통과한 것으로 오인할 수 없습니다.
- `Invalidation` — 스캔 시점의 커밋. 현재 HEAD와 다르면 그 문서는 stale이고
  `/next-move`를 다시 돌려야 합니다.

이것이 `PATTERNS.md` T06을 실제로 동작하게 만드는 지점입니다 — T06은 이전 세션
결정의 현재 유효성 검증을 요구하고, HEAD 대조가 바로 그 검증입니다.

---

## Superpowers가 경쟁자가 아니라 의존성인 이유

`ai-common-rules`는 행동 제어(승인 워크플로우, 응답 식별자, 보안 가드레일)를 담당하고, 실행 방법론은 의도적으로 정의하지 않습니다. Superpowers가 그 역할을 맡고, 둘은 **승인 경계에서 만납니다** — `/grill-me`는 실행 *전* 계획 검증, Superpowers는 승인 *직후*부터 승인된 `[PLAN]`을 spec·작업 분해·TDD 구현으로 이어받음. 겹치는 지점이 0이라 단순 추천이 아니라 번들로 묶었습니다.

### Caveman — 토큰 압축, 인용이지 복제가 아니다

`CLAUDE.md`의 `TOKEN COMPRESSION (Caveman Lite)` 규칙은 이름과 핵심 발상 — 코드·명령어·경로·에러 메시지는 그대로 두고 주변 산문만 압축 — 을 [`JuliusBrussee/caveman`](https://github.com/JuliusBrussee/caveman)(출력 토큰 약 65%, 입력 토큰 약 33% 절감으로 측정됨)에서 가져왔습니다. 차이점: caveman은 어떤 클라이언트에도 붙는 프록시로 입출력 양방향을 압축하지만, 이 저장소의 버전은 Claude Code 전용 **출력 규율**로 모델 앞단이 아니라 응답 식별자·Delta Report 포맷과 직접 결합돼 있습니다.

### Claude Mem — 의도적 제외

Claude Mem은 세션 간 지속 메모리(SQLite + 벡터 스토어, 툴 사용 기록 자동 요약)를 추가합니다. Claude Code의 내장 auto-memory 시스템을 이미 쓰고 있다면 건너뛰세요 — 둘 다 켜면 컨텍스트가 중복 주입되고 프로젝트 상태의 단일 진실 소스가 사라집니다.

---

## 개발

이 저장소는 markdown과 JSON만 배포하므로 컴파일 대상도, 테스트 스위트도 없습니다.
대신 깨지는 것은 구조이고, `scripts/validate.py`가 정확히 그것을 검사합니다:

```bash
python scripts/validate.py
```

| 검사 | 잡아내는 것 |
|---|---|
| 매니페스트 파싱 + 마켓플레이스가 이 플러그인을 포함 | 설치 시점에 터지는 잘못된 `plugin.json`·`marketplace.json` |
| 모든 `dependencies` 항목이 마켓플레이스 안에서 해석됨 | 존재하지 않는 대상을 가리키는 의존성 — 여기가 아니라 **사용자 PC에서** 실패함 |
| 각 `SKILL.md`의 frontmatter 파싱 + `name`이 디렉터리명과 일치 | `/<name>`으로 호출이 조용히 안 되는 스킬 |
| 상대 경로 `.md` 링크 해석 | 작성된 적 없는 파일을 가리키는 문서 |
| 두 README의 섹션 개수 동일 | 한쪽에만 추가하고 다른 쪽을 잊은 섹션 |

`.github/workflows/validate.yml`이 `master` push와 모든 PR에서 이를 실행하고,
Claude Code가 이 저장소를 마켓플레이스로 clone할 때와 동일한 방식으로 매니페스트를
다시 읽는 단계를 추가로 수행합니다.

모든 검사 항목은 해당 실수가 실제로 `master`에 한 번씩 들어간 적이 있어서 생겼습니다.
