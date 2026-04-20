# Cursor Rules Migration Summary

`AI_COMMON_RULES.md` 파일을 Cursor의 최신 `.cursor/rules/*.mdc` 구조로 전환했습니다.

## 📂 생성된 파일 구조
현재 프로젝트의 `.cursor/rules/` 디렉토리에 다음 파일들이 생성되었습니다.

1. **core-behavior.mdc**: AI의 근본적인 사고 및 추론 방식 (Evidence-Based, Critical Thinking 등)
2. **communication.mdc**: 소통 톤앤매너, 언어 설정, 응답 형식 (Conclusion-First, High-Density 등)
3. **workflow.mdc**: 승인 우선 프로세스 및 보고 절차 (Approval-First, Reporting 등)
4. **coding-standards.mdc**: 코드 구현 및 문서화 기술 표준 (Logical Atomicity, Security 등)

## 🛠️ 주요 특징
- **Legacy 탈피**: `.cursorrules` 대신 모듈화된 `.mdc` 형식을 사용합니다.
- **자동 컨텍스트**: 각 파일의 `globs` 설정을 통해 필요한 상황에서만 규칙이 활성화됩니다.
- **의미 보존**: 기존 파일의 모든 핵심 지침을 역할별로 충실히 나누어 담았습니다.
