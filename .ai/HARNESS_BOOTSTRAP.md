# Harness Bootstrap Guide v3.0
<!-- ⚠️ DOCS LAYER: 에이전트 프롬프트에 주입하지 말 것. 개발자 참조 문서. -->

---

## Step 1: Runtime Layer 주입 (필수)
에이전트의 세션 시작 시 `.ai/` 폴더 내의 아래 3개 파일만 프롬프트에 주입합니다.
- **`.ai/AI_COMMON_RULES.md`**: 핵심 행동 헌법
- **`.ai/PATTERNS.md`**: 하지 말 것 vs 해야 할 것 대조 DB
- **`.ai/PROJECT_STATE.md`**: 현재 세션 상태 스냅샷

## Step 2: Docs Layer 보관 (참조)
`.ai/` 폴더 내에 보관하며, 에이전트에게는 주입하지 않습니다.
- **`.ai/HARNESS_SPEC.md`**: 하네스 기술 상세 명세
- **`.ai/HARNESS_BOOTSTRAP.md`**: 설치 및 페르소나 가이드
- **`.ai/COMPLIANCE_LOG.md`**: 준수율 기록 로그

---

## Step 3: Adaptive Persona Switcher
에이전트 첫 세션 시작 시 루트를 탐색하여 아래를 자동 선언하게 합니다:
```
[INFO] [MODE:EXPLORE] Adaptive Persona 적용됨
- 프로젝트 유형: [Next.js / Python / Unity 등]
- 보안 등급: [L1 / L2]
- 소통 밀도: High-Density
```

## Step 4: 도구별 주입 방법
- **Claude / Cursor**: `AI_COMMON_RULES` + `PATTERNS` + `PROJECT_STATE` 내용 합쳐서 주입.
- **LangChain**: `system_message`에 위 3개 파일 로드.

## Step 5: 운영 체크리스트
- [ ] 첫 응답이 `[MODE:EXPLORE]`와 식별자로 시작하는가?
- [ ] 인사말(Fluff)이 제거되었는가?
- [ ] 수정 전 `[PLAN]` 승인 절차를 지키는가?
