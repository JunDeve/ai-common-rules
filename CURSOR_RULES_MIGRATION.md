# Cursor Rules Migration Summary

AI_COMMON_RULES.md 파일을 Cursor의 최신 .cursor/rules/*.mdc 구조로 전환 완료.

## 생성된 파일 구조
현재 프로젝트의 .cursor/rules/ 디렉토리에 다음 파일들이 생성됨.

1. core-behavior.mdc: AI의 근본적인 사고 및 추론 방식 (Evidence-Based, Critical Thinking 등)
2. communication.mdc: 소통 톤앤매너, 언어 설정, 응답 형식 (Conclusion-First, High-Density 등)
3. workflow.mdc: 승인 우선 프로세스 및 보고 절차 (Approval-First, Reporting 등)
4. coding-standards.mdc: 코드 구현 및 문서화 기술 표준 (Logical Atomicity, Security 등)

## 주요 특징
- Legacy 탈피: .cursorrules 대신 모듈화된 .mdc 형식 사용.
- 범용 컨텍스트: 특정 경로를 배제하고 현재 워크스페이스 루트를 자동 인식하여 동작 (다양한 프로젝트에 즉시 적용 가능).
- 자동 이력 기록: git pull 시 README.md 하단에 동기화 날짜/시간 자동 기록.
- 채팅 트리거: 업로드:메시지 명령어를 통해 add, commit, push 일괄 자동 실행.
- 의미 보존: 기존 지침의 핵심 내용을 역할별로 분리하여 재구성.
