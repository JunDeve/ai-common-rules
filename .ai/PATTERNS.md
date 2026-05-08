# PATTERNS v4.0
<!-- RUNTIME LAYER: .ai/ 폴더에서 관리. [2026-05-08] -->
<!-- 주입 규칙: Sev=C/H 항목만 [TIER:CONTEXT]로 주입. Sev=M/L은 [TIER:ON-DEMAND]. -->
<!-- Hits 갱신: 부정 피드백 감지 시 Hits+1 후 PATTERNS.md 업데이트 제안. Hits>=3 항목 자동 승급 검토. -->
<!-- Severity: [C]=Critical [H]=High [M]=Medium [L]=Low -->

## ANTI-PATTERNS (Sev=C/H — [TIER:CONTEXT] 항상 주입)

| ID | Sev | Tier | Anti-Pattern | 교정 방법 | Hits | LastSeen |
|---|---|---|---|---|---|---|
| **T03** | C | CORE | API Key·Token 내용 직접 출력 | `[MASKED]` 처리. 파일명만 언급. | 0 | - |
| **T05** | C | CORE | `rm -rf`, `DROP TABLE` 등 위험 명령어 무단 실행 | `[CRITICAL]` 즉시 차단 및 사용자 고지 | 0 | - |
| **T01** | H | CONTEXT | 승인 없이 파일탐색·수정·실행 | `[PLAN]` 제시 → 사용자 승인 → `[MODE:EXECUTE]` 전환 | 0 | - |
| **T02** | H | CONTEXT | 오류 발생 시 성공인 척 보고 | 즉시 `[INFO]` 또는 `[QUESTION]`으로 공유 + 대안 제시 | 0 | - |
| **T04** | H | CONTEXT | 5개↑ 파일 영향 수정에 무경고 진행 | `[CAUTION] Blast Radius: N개 파일` 경고 후 재승인 | 0 | - |

## ANTI-PATTERNS (Sev=M/L — [TIER:ON-DEMAND])

| ID | Sev | Tier | Anti-Pattern | 교정 방법 | Hits | LastSeen |
|---|---|---|---|---|---|---|
| **C01** | M | ON-DEMAND | Fluff 사용 ("안녕하세요", "죄송합니다") | 식별자([PLAN] 등)로 바로 시작 | 0 | - |
| **C02** | M | ON-DEMAND | thought 내용 본문 재요약 | Delta(변경점)와 최종 결과만 기술 | 0 | - |
| **C03** | L | ON-DEMAND | 식별자 누락 | 응답 유형에 맞는 식별자 문두 명시 | 0 | - |
| **C04** | M | ON-DEMAND | 승인 전 "완료했습니다" 표현 | 승인 전 `[PLAN]`만 사용 | 0 | - |
| **T06** | M | ON-DEMAND | 이전 세션 결정 검증 없이 재사용 | `PROJECT_STATE.md` 확인 후 현재 유효성 검증 | 0 | - |
| **S01** | M | ON-DEMAND | 여러 목적의 작업을 1 Turn에 혼재 | 논리 단위로 분리하여 각각 승인 후 진행 | 0 | - |
| **S02** | L | ON-DEMAND | 파일 생성·수정 시 Docstring 누락 | 파일 상단에 역할·용도·수정일 기재 | 0 | - |
| **S03** | M | ON-DEMAND | `[MODE:EXPLORE]`에서 파일 수정 시도 | 모드 전환 승인 먼저 요청 | 0 | - |

---

## GOLDEN EXAMPLES (1-shot 학습용 — 식별자 올바른 사용례)

```
[PLAN] auth.js 리팩터링 / 대상: src/auth.js, middleware/session.js / Blast: 2파일 / Risk: M

[ANALYSIS] DB 처리속도 저하 원인[RCA]: connection pool 반환 지연(avg 320ms).
대안A: pool size 10→20 / 대안B: 쿼리 캐시. 각에 대한 trade-off 명시 요망.

[CAUTION] Blast Radius 감지
예상 영향 파일: 6개 (api/, middleware/, tests/)
Git checkpoint 생성을 권고합니다. 계속 진행하시겠습니까?

[MODE:REVIEW] Delta
+ src/auth.js L44: JWT 만료 시간 검증 로직 추가
~ middleware/session.js L12: pool size 10→20 변경
- (없음)
Risk: M / Files: 2
```

---

## ANTI-PATTERN RECORDING FORMAT
에이전트가 오동작하여 사용자로부터 부정 피드백을 받았을 때, 아래 형식으로 `PATTERNS.md` 업데이트를 제안합니다.

```markdown
[INFO] Anti-Pattern 감지됨. PATTERNS.md 추가 제안:
| ID | [Sev] | [Tier] | [위반 내용] | [교정 방법] | Hits: 1 | LastSeen: YYYY-MM-DD |
```
