# Compliance Log
<!-- ⚠️ DOCS LAYER: 에이전트 프롬프트에 주입하지 말 것. 개발자 참조 문서. -->
<!--
하네스 Observability 모듈(Module F)이 기록하는 에이전트 준수율 로그입니다.
세션 종료 시 또는 [MODE: REVIEW] 전환 시 업데이트를 권고합니다.
Compliance Rate < 80% 또는 [CRITICAL] 이벤트 발생 시 Critic Agent 호출.
[Last Modified: 2026-04-24]
-->

## Compliance Rate 계산식
```
Compliance Rate = (위반 없는 응답 수 / 총 응답 수) × 100%
```

## 경고 임계값
| 조건 | 대응 |
|---|---|
| Rate < 80% | Critic Agent 호출 권고 |
| Rate < 60% | `[CRITICAL]` 경고 + 즉시 세션 점검 |
| `[CRITICAL]` 이벤트 1회 이상 | 해당 세션 강제 리뷰 |
| 동일 패턴 위반 3회 이상 | `ANTI_PATTERNS.md` 자동 추가 권고 |

---

## 로그 형식

각 세션을 아래 포맷으로 기록합니다:

```markdown
### [YYYY-MM-DD] Session: [세션 주제]
- **총 응답 수**: N
- **위반 없는 응답**: N
- **Compliance Rate**: N%
- **위반 내역**:
  - [AP-Xnn] Turn N: [위반 내용 한 줄 요약]
- **[CRITICAL] 이벤트**: [있음/없음] → [내용]
- **Critic Agent 호출**: [Y/N] → [호출 이유 및 결과]
- **신규 Anti-Pattern 추가**: [AP-Xnn 목록 또는 없음]
- **신규 Golden Pattern 추가**: [GP-nn 목록 또는 없음]
- **비고**: [특이사항]
```

---

## 세션 로그

<!-- 아래에 세션별 로그를 역순(최신 순)으로 추가합니다. -->

### [2026-04-24] Session: AI Agent Harness v2.0 구축
- **총 응답 수**: N/A (초기화 세션)
- **위반 없는 응답**: N/A
- **Compliance Rate**: N/A
- **위반 내역**: 없음
- **[CRITICAL] 이벤트**: 없음
- **Critic Agent 호출**: N
- **신규 Anti-Pattern 추가**: AP-C01~C04, AP-T01~T06, AP-S01~S03 (초기화)
- **신규 Golden Pattern 추가**: GP-C01~C02, GP-T01~T02, GP-S01~S02 (초기화)
- **비고**: 하네스 v2.0 전체 구조 구축 완료. 6개 모듈 신규 정의.
