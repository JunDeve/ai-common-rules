# PATTERNS v3.0
<!-- RUNTIME LAYER: .ai/ 폴더에서 관리. 세션 시작 시 AI_COMMON_RULES.md 다음에 읽을 것. [2026-04-24] -->
<!-- 자동 기록: 부정 피드백("틀렸어", "그렇게 하지 마" 등) → Anti-Pattern 추가 제안. -->
<!-- Severity: [C]=Critical [H]=High [M]=Medium [L]=Low -->

## ANTI-PATTERNS (오동작 방지 목록)

| ID | Sev | ❌ Anti-Pattern | ✅ 교정 방법 (Corrective Action) |
|---|---|---|---|
| **C01** | M | Fluff 사용 ("안녕하세요", "죄송합니다") | 식별자([PLAN] 등)로 바로 시작 |
| **C02** | M | thought 내용 본문 재요약 | Delta(변경점)와 최종 결과만 기술 |
| **C03** | L | 식별자 누락 | 응답 유형에 맞는 식별자 문두 명시 |
| **C04** | M | 승인 전 "완료했습니다" 표현 | 승인 전 `[PLAN]`만 사용. 완료는 승인 후 `[MODE:EXECUTE]`에서 보고. |
| **T01** | H | 승인 없이 파일탐색·수정·실행 | `[PLAN]` 제시 → 사용자 승인 → `[MODE:EXECUTE]` 전환 |
| **T02** | H | 오류 발생 시 성공인 척 보고 | 즉시 `[INFO]` 또는 `[QUESTION]`으로 공유 + 대안 제시 |
| **T03** | C | API Key·Token 내용 직접 출력 | `[MASKED]` 처리. 파일명만 언급. |
| **T04** | H | 5개↑ 파일 영향 수정에 무경고 진행 | `[CAUTION] Blast Radius: N개 파일` 경고 후 재승인 |
| **T05** | C | `rm -rf`, `DROP TABLE` 등 위험 명령어 무단 실행 | `[CRITICAL]` 즉시 차단 및 사용자 고지 |
| **T06** | M | 이전 세션 결정 검증 없이 재사용 | `PROJECT_STATE.md` 확인 후 현재 유효성 검증 |
| **S01** | M | 여러 목적의 작업을 1 Turn에 혼재 | 논리 단위로 분리하여 각각 승인 후 진행 |
| **S02** | L | 파일 생성·수정 시 Docstring 누락 | 파일 상단에 역할·용도·수정일 기재 |
| **S03** | M | `[MODE:EXPLORE]`에서 파일 수정 시도 | 모드 전환 승인 먼저 요청 |

---

## ANTI-PATTERN RECORDING FORMAT
에이전트가 오동작하여 사용자로부터 부정 피드백을 받았을 때, 아래 형식으로 `PATTERNS.md` 업데이트를 제안합니다.

```markdown
[INFO] Anti-Pattern 감지됨. PATTERNS.md 추가 제안:
| ID | [Sev] | [위반 내용] | [교정 방법] |
```
