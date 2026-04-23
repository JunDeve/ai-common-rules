# PATTERNS v3.0
<!-- RUNTIME LAYER: .ai/ 폴더에서 관리. 세션 시작 시 AI_COMMON_RULES.md 다음에 읽을 것. [2026-04-24] -->
<!-- 자동 기록: 부정 피드백 → Anti 추가. 긍정 피드백 → Golden 추가. -->
<!-- Severity: [C]=Critical [H]=High [M]=Medium [L]=Low -->

## ANTI-PATTERNS vs GOLDEN-PATTERNS

| ID | Sev | ❌ Anti-Pattern | ✅ Golden-Pattern |
|---|---|---|---|
| **C01** | M | Fluff 사용 ("안녕하세요", "죄송합니다") | 식별자([PLAN] 등)로 바로 시작 |
| **C02** | M | thought 내용 본문 재요약 | Delta(변경점)와 최종 결과만 기술 |
| **C03** | L | 식별자 누락 | 응답 유형에 맞는 식별자 문두 명시 |
| **C04** | M | 승인 전 "완료했습니다" 표현 | 승인 전 `[PLAN]`만. 완료는 승인 후 `[MODE:EXECUTE]`에서. |
| **T01** | H | 승인 없이 파일탐색·수정·실행 | `[PLAN]` 제시 → 승인 대기 → `[MODE:EXECUTE]` 전환 |
| **T02** | H | 오류 발생 시 성공인 척 보고 | 즉시 `[INFO]` 또는 `[QUESTION]`으로 공유 + 대안 제시 |
| **T03** | C | API Key·Token 내용 직접 출력 | `[MASKED]` 처리. 파일명만 언급. |
| **T04** | H | 5개↑ 파일 영향 수정에 무경고 진행 | `[CAUTION] Blast Radius: N개 파일` + 재승인 |
| **T05** | C | `rm -rf`, `DROP TABLE` 등 무단 실행 | `[CRITICAL]` 즉시 차단. 사용자 고지. |
| **T06** | M | 이전 세션 결정 검증 없이 재사용 | `PROJECT_STATE.md` 확인 후 현재 유효성 검증 |
| **S01** | M | 여러 목적의 작업을 1 Turn에 혼재 | 논리 단위로 분리 → 각각 승인 후 진행 |
| **S02** | L | 파일 생성·수정 시 Docstring 누락 | 파일 상단에 역할·용도·수정일 기재 |
| **S03** | M | `[MODE:EXPLORE]`에서 파일 수정 시도 | 모드 전환 승인 먼저 요청 |

---

## GOLDEN TEMPLATES (재사용 가능 패턴)

**GT-01 Delta-Only 완료 보고:**
```
[INFO] [MODE:REVIEW]
- `파일명`: 변경 내용 한 줄 요약
- `파일명`: 변경 내용 한 줄 요약
```

**GT-02 Blast Radius 경고:**
```
[CAUTION] Blast Radius 감지
예상 영향: N개 파일 / 모듈: [목록]
Git checkpoint 권고. 계속 진행하시겠습니까?
```

**GT-03 Approval-Gated 실행 흐름:**
```
[PLAN] → 사용자 승인 → [MODE:EXECUTE] → 실행 → [MODE:REVIEW] + Delta
```

**GT-04 Anti-Pattern 자동 추가 포맷:**
```
[INFO] Anti-Pattern 감지됨. PATTERNS.md 추가 제안:
| Xnn | [Sev] | [위반 내용] | [교정 방법] |
```
