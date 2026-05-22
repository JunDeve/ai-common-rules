# PLAYWRIGHT MCP RULES
<!-- @playwright/mcp 서버로 브라우저를 직접 실행·제어할 때 적용 -->
<!-- 브라우저 자동화·스크래핑·E2E 작업 시 Claude가 이 파일을 직접 읽음 -->

## 인터랙션 모드 (우선순위 순)
1. **Snapshot 모드** (기본·권장): `browser_snapshot` → ref 기반 클릭·입력
   - 접근성 트리 사용. 비전 모델 불필요. 토큰 ~300 vs 스크린샷 ~4000.
   - ref는 스냅샷 1회분만 유효 — 페이지 변경 후 반드시 재스냅샷.
2. **Vision 모드** (opt-in `--caps=vision`): 좌표 기반 조작.
   - 캔버스·SVG 등 접근성 트리 불가 UI에만 사용.

## 표준 워크플로
```
browser_navigate(url)
  → browser_snapshot()          # 상태 파악 필수
  → browser_click/type/fill()   # ref 사용
  → browser_snapshot()          # 변경 확인
  → (반복)
  → browser_close()             # 작업 후 반드시 종료
```

## Capability 활성화 규칙
- 기본 core 툴만 사용. 추가 cap 활성화 전 목적 고지 + 사용자 승인.
- `--caps=network`: 네트워크 감청·모킹 → `[CAUTION]` 필요
- `--caps=storage`: 쿠키·토큰 접근 → `[CAUTION]` + `[MASKED]`
- `--caps=unsafe` (`browser_run_code_unsafe`): **금지** `[CRITICAL]`

## 보안
- `browser_evaluate`에 사용자 입력 직접 삽입 → `[CRITICAL]` (코드 인젝션)
- 외부 URL 탐색 전 목적지·전송 데이터 고지 (SECURITY > Network 규칙 적용)
- 개인정보·자격증명이 스냅샷/스크린샷에 포함될 경우 → `[MASKED]` 처리
- 스크래핑 시: `robots.txt` 확인 고지 필수 / CAPTCHA 우회 → `[CRITICAL]`

## 예시
```
[PLAN] 로그인 자동화 / 도구: Playwright MCP / Blast: 외부URL / Risk: M
1. browser_navigate('https://example.com/login')
2. browser_snapshot() → ref 확인
3. browser_fill(email_ref, '[MASKED]') / browser_fill(pw_ref, '[MASKED]')
4. browser_click(submit_ref)
5. browser_snapshot() → 로그인 성공 여부 확인
6. browser_close()
```

## 안티패턴 (PATTERNS.md P01~P05 참조)
| ID | 안티패턴 | 교정 |
|---|---|---|
| P01 | `browser_run_code_unsafe` 무단 활성화 | `[CRITICAL]` 즉시 차단 |
| P02 | `browser_evaluate`에 사용자 입력 직접 삽입 | 입력값 검증 후 파라미터화 |
| P03 | 페이지 변경 후 이전 ref 재사용 | 재스냅샷 후 새 ref 사용 |
| P04 | 작업 후 `browser_close()` 누락 | 항상 명시적 종료 |
| P05 | storage cap 활성화 시 토큰 미마스킹 | `[MASKED]` 처리 |
