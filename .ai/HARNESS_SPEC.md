# AI Agent Harness Specification v4.0
<!-- DOCS LAYER: 에이전트 프롬프트에 주입하지 말 것. 개발자 참조 문서. -->
<!-- [Last Modified: 2026-05-08] -->

---

## 아키텍처 개요

```
사용자 입력
    │
    ▼
┌─────────────────────────────────────────────┐
│             TIERED RULE INJECTOR            │
│  CORE(~600t) → CONTEXT(~400t) → ON-DEMAND  │
└─────────────────────────────────────────────┘
    │                          │
    ▼                          ▼
[AI_COMMON_RULES.md]    [PROJECT_STATE ACTIVE]
[PATTERNS Sev=C/H]      [PATTERNS Sev=M/L *]
                         * ON-DEMAND만
    │
    ▼
에이전트 추론
    │
    ▼
┌─────────────────────────────────────────────┐
│           SELF-AUDIT LAYER                  │
│  ID Check → Fluff → Mode → Blast Radius     │
└─────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────┐
│         AUTO-COMPLIANCE LOGGER              │
│  Regex 검증 → COMPLIANCE_LOG 실시간 기록    │
└─────────────────────────────────────────────┘
    │
    ▼
사용자에게 전달
```

---

## Module A: Anti-Pattern Interceptor

**목적**: 부정 피드백을 즉시 패턴 DB에 반영하여 재발 방지.

### A-1. 트리거
- 사용자 피드백에 "틀렸어", "그렇게 하지 마", "잘못됐어" 등 부정어 감지.

### A-2. 실행
1. 위반 케이스 요약.
2. `PATTERNS.md` 해당 항목 `Hits+1`, `LastSeen` 갱신 제안.
3. Hits >= 3 달성 시 Tier 승급(ON-DEMAND → CONTEXT) 검토 제안.
4. 형식: `[AP-Xnn: 자동감지] Severity: [H] / 위반 요약`

---

## Module B: Tiered Rule Injection

**목적**: 세션별 주입 토큰을 최소화하면서 필요한 규칙만 정확히 로드.

### B-1. Tier 정의

| Tier | 내용 | 주입 시점 | 예상 토큰 |
|---|---|---|---|
| **CORE** | AI_COMMON_RULES 전체 | 항상 | ~600 |
| **CONTEXT** | PATTERNS Sev=C/H + PROJECT_STATE ACTIVE 슬롯 | 항상 | ~400 |
| **ON-DEMAND** | PATTERNS Sev=M/L + ARCHIVE 슬롯 + HARNESS_SPEC 상세 | 키워드 트리거 시 | 0~800 |

### B-2. ON-DEMAND 트리거 키워드 예시
- "보안", "키", "토큰" → DLP 섹션 로드
- "이전 결정", "히스토리" → ARCHIVE 슬롯 로드
- "모듈", "스펙", "명세" → HARNESS_SPEC 로드

### B-3. 효과
- 평균 주입 토큰: 기존 ~3,500 → ~1,000 (약 70% 절감)

---

## Module C: Auto-Correction & Self-Audit

**목적**: 에이전트 출력이 사용자에게 전달되기 전 규정 위반을 자동 감지.

### C-1. Self-Audit Checklist
```
1. 식별자([PLAN], [CODE] 등)가 문두에 있는가?
2. Fluff(인사/사과/감사)가 포함되어 있는가?
3. 현재 [MODE]에서 금지된 행동이 포함되었는가?
4. 승인 없이 실행 완료를 표현했는가?
5. [CAUTION]/[CRITICAL] 없이 파괴적 작업을 제안했는가?
6. 민감 정보([MASKED] 처리 없이)가 노출되었는가?
```

### C-2. Mode Enforcement
- `[MODE:EXPLORE]` 중 파일 수정 도구 호출 시도 → 즉시 차단.
- 차단 시: `[CAUTION] 현재 탐색 모드입니다. 실행하려면 사용자 승인이 필요합니다.`

---

## Module D: Compliance Auto-Logger

**목적**: server.js 미들웨어가 에이전트 응답을 실시간 검증하여 COMPLIANCE_LOG.md에 자동 기록.
Claude의 Extended Thinking이 커버하지 않는 **외부 측정** 레이어.

### D-1. 검증 Regex (server.js에 구현)
```javascript
const auditRules = {
  C01_fluff:      /(안녕|죄송|감사합니다)/,
  C03_id_missing: /^(?!\[(PLAN|CODE|INFO|ANALYSIS|QUESTION|REF|CAUTION|CRITICAL|CONFIDENCE|MODE)\])/,
  T03_key_leak:   /(sk-[a-z0-9]{20,}|ghp_[a-zA-Z0-9]{36}|Bearer\s[A-Za-z0-9\-._~+/]+=*)/i,
  T05_danger_cmd: /(rm\s+-rf|del\s+\/f|DROP\s+TABLE|chmod\s+777|format\s+[A-Z]:)/i,
};
```

### D-2. 로그 자동 기록
- 위반 감지 시 `COMPLIANCE_LOG.md`에 즉시 append.
- 세션 종료 시 Compliance Rate 자동 계산 후 기록.

---

## Module E: Security Guardrails

### E-1. DLP (Data Leakage Prevention)
- Regex 감지 패턴: API Key `[A-Za-z0-9_\-]{32,}`, `sk-`, `ghp_`, `Bearer `
- 감지 즉시 `[MASKED]`로 대체. `[CRITICAL]` 경고.

### E-2. Blast Radius Warning
- 영향 파일 5개↑ 추정 시:
```
[CAUTION] Blast Radius 감지
예상 영향 파일: N개 / 영향 모듈: [목록]
Git checkpoint 생성을 권고합니다.
```

### E-3. Command Execution Filter
차단 명령어: `rm -rf`, `del /f /s /q`, `format`, `DROP TABLE`, `chmod 777`

### E-4. Path Sanitization
차단 경로:
- Unix: `/etc/`, `/root/`, `/var/`, `~/.ssh/`
- Windows: `C:\Windows\`, `C:\System32\`, `%APPDATA%`

### E-5. Server Path Traversal 방지 (server.js)
```javascript
const ALLOWED_FILES = /^[A-Z_]+\.md$/;
if (!ALLOWED_FILES.test(fileName)) {
  res.writeHead(403);
  return res.end('[CRITICAL] 허용되지 않은 파일명.');
}
const filePath = path.resolve(AI_DIR, fileName);
if (!filePath.startsWith(path.resolve(AI_DIR))) {
  res.writeHead(403);
  return res.end('[CRITICAL] Path traversal 차단.');
}
```

---

## Module F: State Machine Context Manager

### F-1. PROJECT_STATE 구조
- **ACTIVE**: 항상 TIER:CONTEXT로 주입. Active Task, 최근 7일 결정, Known Risks, Next Actions.
- **ARCHIVE**: TIER:ON-DEMAND. 7일 초과 항목 자동 이동 제안.

### F-2. State Update Trigger
- `[MODE:REVIEW]` 전환 시 ACTIVE 슬롯 업데이트 필수.
- 7일 초과 ACTIVE 항목 → ARCHIVE 이동 제안.

---

## Module G: Critic Agent (UI 내장)

**목적**: 동일 모델의 셀프 검토 한계를 극복. 고위험 Plan을 독립 Claude 인스턴스가 교차 검증.
Anthropic API (claude-sonnet-4-20250514)를 UI에서 직접 호출.

### G-1. 호출 조건
- Compliance Rate < 80% 세션
- `[CRITICAL]` 이벤트 발생
- Blast Radius > 10개 파일
- 사용자가 "검증" 버튼 수동 클릭

### G-2. 입력 / 출력
```
입력: 작성된 [PLAN] 전문 + 관련 파일 목록
출력: Risk: H/M/L / Logical gaps: [...] / Rule violations: [...] / Suggest: [...]
```

### G-3. UI 연동 (index.html Critic 패널)
- "Plan 검증" 버튼 → API 호출 → 결과를 Integrations 탭에 표시.
- 결과 형식: `[ANALYSIS] Critic 검토 결과: ...`

---

## Module H: RBAC (Role-Based Access Control)

| 레벨 | 이름 | 허용 범위 |
|---|---|---|
| L0 | Read-Only | 파일 읽기, 분석만 가능 |
| L1 | Project-Limited | 프로젝트 루트 내 파일 수정 가능 (기본값) |
| L2 | Full-Access | 명령 실행 포함 (매 작업 재승인 필수) |

---

## Module I: Observability (Compliance Score)

매 세션 종료 시 `COMPLIANCE_LOG.md`에 자동 기록 (Module D Auto-Logger):
- 총 응답 수 / 위반 없는 응답 수
- **Compliance Rate** = (위반 없는 응답 / 총 응답) × 100%
- `[CRITICAL]` 이벤트 횟수
- 신규 Anti-Pattern 추가 여부

**임계값**:
| 조건 | 대응 |
|---|---|
| Rate < 80% | Critic Agent 호출 권고 |
| Rate < 60% | `[CRITICAL]` + 즉시 세션 점검 |
| `[CRITICAL]` 1회 이상 | 강제 리뷰 |
| 동일 패턴 위반 3회 | PATTERNS.md 자동 추가 권고 |
