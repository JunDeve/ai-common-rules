# PATTERNS — ON-DEMAND
<!-- Sev=M/L 안티패턴. CLAUDE.md에 주입되지 않음. -->
<!-- 부정 피드백 수신 시 Claude가 이 파일을 직접 읽어 항목 추가·Hits 갱신 제안. -->
<!-- Hits >= 3 항목은 CLAUDE.md ANTI-PATTERNS C/H 테이블로 승급 검토. -->

## ANTI-PATTERNS (Sev=M/L)

| ID | Sev | Tier | Anti-Pattern | 교정 방법 | Hits | LastSeen |
|---|---|---|---|---|---|---|
| **C01** | M | ON-DEMAND | Fluff 사용 ("안녕하세요", "죄송합니다") | 바로 본론으로 시작 | 0 | - |
| **C02** | M | ON-DEMAND | thought 내용 본문 재요약 | Delta(변경점)와 최종 결과만 기술 | 0 | - |
| **C03** | L | ON-DEMAND | 필수 식별자 누락 | 조건 해당 시 [PLAN]/[CAUTION]/[CRITICAL]/[CONFIDENCE:LOW] 명시 | 0 | - |
| **C04** | M | ON-DEMAND | 승인 전 "완료했습니다" 표현 | 승인 전 `[PLAN]`만 사용 | 0 | - |
| **T06** | M | ON-DEMAND | 이전 세션 결정 검증 없이 재사용 | `PROJECT_STATE.md` 확인 후 현재 유효성 검증 | 0 | - |
| **S01** | M | ON-DEMAND | 여러 목적의 작업을 1 Turn에 혼재 | 논리 단위로 분리하여 각각 승인 후 진행 | 0 | - |
| **S02** | L | ON-DEMAND | 파일 생성·수정 시 Docstring 누락 | 파일 상단에 역할·용도·수정일 기재 | 0 | - |
| **S03** | M | ON-DEMAND | `[MODE:EXPLORE]`에서 파일 수정 시도 | 모드 전환 승인 먼저 요청 | 0 | - |
| **P03** | H | ON-DEMAND | 페이지 변경 후 이전 스냅샷 ref 재사용 | 페이지 변경 후 `browser_snapshot()` 재호출 → 새 ref 사용 | 0 | - |
| **P04** | M | ON-DEMAND | 작업 후 `browser_close()` 누락 | 모든 브라우저 세션 종료 시 명시적 `browser_close()` 호출 | 0 | - |
| **P05** | M | ON-DEMAND | `--caps=storage` 활성화 시 쿠키·토큰 미마스킹 | 쿠키·토큰 값 출력 시 `[MASKED]` 처리 | 0 | - |
