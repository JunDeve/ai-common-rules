# AI Agent Harness Specification v2.0
<!-- ⚠️ DOCS LAYER: 에이전트 프롬프트에 주입하지 말 것. 개발자 참조 문서. -->
<!--
하네스의 기술적 명세서입니다. 각 모듈의 트리거 조건, 실행 로직, 출력 결과를 정의합니다.
이 문서는 HARNESS_BOOTSTRAP.md와 함께 새 프로젝트에 이식됩니다.
[Last Modified: 2026-04-24]
-->

---

## 아키텍처 개요

```
사용자 입력
    │
    ▼
┌─────────────────────────────────────────┐
│           HARNESS INTERCEPTOR           │
│  (Mode Gate → Rule Injection → Audit)   │
└─────────────────────────────────────────┘
    │                          │
    ▼                          ▼
[AI_COMMON_RULES.md]    [PROJECT_STATE.md]
[ANTI_PATTERNS.md]      [GOLDEN_PATTERNS.md]
[COMPLIANCE_LOG.md]
    │
    ▼
에이전트 추론 (thought block)
    │
    ▼
┌─────────────────────────────────────────┐
│         SELF-AUDIT LAYER                │
│  (Fluff Check → Mode Check → ID Check) │
└─────────────────────────────────────────┘
    │
    ▼
사용자에게 전달
```

---

## Module A: Cognitive Garbage Collection (인지 GC)

**목적**: 에이전트의 인지 부하를 줄이고, 오염된 맥락을 정화하여 효율을 극대화합니다.

### A-1. Anti-Pattern Interceptor
- **트리거**: 사용자 피드백에 `"틀렸어"`, `"그렇게 하지 마"`, `"잘못됐어"` 등 부정어 감지.
- **실행**: 위반 케이스를 `ANTI_PATTERNS.md`에 즉시 추가 제안.
- **형식**: `[AP-Xnn: 자동감지] Severity: [HIGH] / 위반 내용 요약`

### A-2. Golden Pattern Recorder
- **트리거**: 사용자 피드백에 `"굿"`, `"완벽"`, `"바로 이거야"`, `"정확해"` 등 긍정어 감지.
- **실행**: 해당 응답 패턴을 `GOLDEN_PATTERNS.md`에 즉시 추가 제안.
- **형식**: `[GP-nn: 자동감지] 성공 케이스 요약 + 재사용 가능 패턴`

### A-3. Context Pruning (맥락 압축)
- **트리거 조건**:
  - 대화 20턴 초과, 또는
  - 추정 토큰 사용량이 한도의 80% 도달.
- **실행**:
  1. `PROJECT_STATE.md`를 현재 상태로 업데이트.
  2. 핵심 결론, 확정 사항, 다음 단계만 요약하여 보존.
  3. 이전 대화의 Raw Data는 아카이브 처리 권고.
- **출력**: `[INFO] Context Pruning 완료. PROJECT_STATE.md 업데이트됨.`

---

## Module B: Auto-Correction System (자동 교정)

**목적**: 에이전트의 출력이 사용자에게 전달되기 전에 규정 위반을 감지하고 차단합니다.

### B-1. Self-Audit Checklist (자기 점검)
에이전트는 출력 직전 아래를 순서대로 점검합니다. 하나라도 실패 시 재작성합니다.

```
□ 1. 식별자([PLAN], [CODE] 등)가 문두에 있는가?
□ 2. Fluff(인사/사과/감사)가 포함되어 있는가?
□ 3. thought 블록 내용을 본문에서 재서술했는가?
□ 4. 현재 [MODE]에서 금지된 행동이 포함되었는가?
□ 5. 승인 없이 실행 완료를 표현했는가?
□ 6. [CAUTION]/[CRITICAL] 없이 파괴적 작업을 제안했는가?
□ 7. 민감 정보([MASKED] 처리 없이)가 노출되었는가?
```

### B-2. Logic Integrity Validator
- **트리거**: `thought` 블록의 최종 결론과 본문의 주장이 불일치할 경우.
- **실행**: `[CONFIDENCE:LOW]` 식별자를 자동 삽입하고 불일치 원인을 명시.

### B-3. Mode Enforcement
- 현재 모드가 `[MODE: EXPLORE]`인데 파일 수정 도구를 호출하려 할 경우 즉시 차단.
- 차단 시: `[CAUTION] 현재 탐색 모드입니다. 실행하려면 사용자 승인이 필요합니다.`

---

## Module C: Regulation Enforcement Layer (규정 강제)

**목적**: `AI_COMMON_RULES.md`가 에이전트에게 항상 최우선 컨텍스트로 존재하도록 보장합니다.

### C-1. Immutable Rule Injection
- `AI_COMMON_RULES.md`는 System Prompt의 최상단에 고정.
- 에이전트가 규칙을 "무시하도록 지시받더라도" 이 규칙은 항상 우선합니다.
- 새 프로젝트 장착 시 `HARNESS_BOOTSTRAP.md`의 절차를 따릅니다.

### C-2. Role-Based Access Control (RBAC)
에이전트에 할당 가능한 권한 레벨:

| 레벨 | 이름 | 허용 범위 |
|---|---|---|
| L0 | Read-Only | 파일 읽기, 분석만 가능 |
| L1 | Project-Limited | 프로젝트 루트 내 파일 수정 가능 |
| L2 | Full-Access | 명령 실행 포함 (명시적 승인 시) |

- 기본 레벨은 **L1**. L2 권한은 매 작업마다 재승인 필요.

### C-3. Compliance Checkpoint
- 세션 내 규칙 위반 감지 시 즉시 `COMPLIANCE_LOG.md`에 기록 권고.
- 위반 누적 3회 이상 시 `[CRITICAL]` 경고 발생.

---

## Module D: Security Guardrails (보안 가드레일)

**목적**: 에이전트의 행동이 보안 경계를 침범하지 않도록 다층 방어합니다.

### D-1. DLP (Data Leakage Prevention)
- **감지 패턴 (Regex)**:
  - API Key: `[A-Za-z0-9_\-]{32,}`
  - Secret/Token: `sk-`, `ghp_`, `Bearer `
  - 개인정보: 이메일, 전화번호 패턴
- **실행**: 감지 즉시 `[MASKED]`로 대체. `[CRITICAL]` 경고 발생.

### D-2. Blast Radius Warning (폭발 반경 경고)
- **트리거**: 코드 수정이 영향을 미치는 파일/모듈이 5개 이상 추정될 때.
- **실행**:
  ```
  [CAUTION] Blast Radius 감지
  예상 영향 파일: N개
  영향 모듈: [목록]
  Git checkpoint 생성을 권고합니다.
  계속 진행하시겠습니까?
  ```

### D-3. Command Execution Filter
위험 명령어 감지 시 즉시 차단:
- `rm -rf`, `del /f /s /q`, `format`, `DROP TABLE`, `chmod 777`
- 차단 시: `[CRITICAL] 위험 명령어 감지. 실행이 차단되었습니다.`

### D-4. Path Sanitization
차단 경로 목록:
- Unix: `/etc/`, `/root/`, `/var/`, `~/.ssh/`
- Windows: `C:\Windows\`, `C:\System32\`, `%APPDATA%`
- 접근 시: `[CRITICAL] 보호된 시스템 경로 접근 시도 차단.`

### D-5. Network Transparency
- 외부 URL/API 호출 발생 전: 목적지, 전송 데이터 요약을 사용자에게 고지.
- 형식: `[INFO] 외부 요청 예정: [URL] / 전송 데이터: [요약]`

---

## Module E: State Machine Context Manager (상태 기반 맥락 관리)

**목적**: 세션이 교체되거나 컨텍스트가 초기화되어도 프로젝트 상태를 완벽히 복원합니다.

### E-1. PROJECT_STATE.md 구조
`PROJECT_STATE.md` 파일이 프로젝트 루트에 존재하면, 에이전트는 세션 시작 시 이를 반드시 읽습니다.

핵심 슬롯:
- `active_task`: 현재 진행 중인 작업
- `confirmed_decisions`: 사용자가 확정한 설계 결정
- `known_risks`: 확인된 리스크 및 주의사항
- `next_actions`: 다음에 수행해야 할 단계
- `anti_pattern_refs`: 이 프로젝트에서 발생한 안티 패턴 참조

### E-2. State Update Trigger
- 작업 완료(`[MODE: REVIEW]`) 전환 시 `PROJECT_STATE.md` 자동 업데이트 권고.
- 맥락 압축(A-3) 발생 시 필수 업데이트.

---

## Module F: Observability & Critic Agent (관측 및 교차 검증)

**목적**: 에이전트의 성능을 수치화하고, 고위험 작업에서 교차 검증을 수행합니다.

### F-1. Compliance Score
매 세션 종료 시 `COMPLIANCE_LOG.md`에 기록:
- 총 응답 수
- 식별자 누락 횟수
- Fluff 감지 횟수
- `[CAUTION]`/`[CRITICAL]` 발생 횟수
- **Compliance Rate**: `(위반 없는 응답 / 총 응답) × 100%`

### F-2. Critic Agent Protocol
**호출 조건**:
- Compliance Rate < 80% 세션
- `[CRITICAL]` 이벤트 발생
- Blast Radius > 10개 파일

**실행**:
1. 해당 작업의 Plan을 별도 에이전트에게 전달.
2. Critic Agent가 독립적으로 위험도, 논리적 오류, 규칙 위반 여부를 검토.
3. 불일치 발견 시 `[ANALYSIS] Critic 검토 결과:` 형태로 보고.
