# Startup Community - Custom Agents

> **목적**: 프로젝트 도메인에 특화된 AI 에이전트를 통해 개발 속도 향상, 오류 감소, 코드 일관성 유지
> **생성일**: 2026-01-18
> **에이전트 수**: 11개 (도메인 7 + 품질 4)

---

## 에이전트 목록

### 도메인 에이전트 (Domain Experts)

| 에이전트 | 설명 | 트리거 키워드 |
|---------|------|--------------|
| [chat-expert](domain/chat-expert.md) | 채팅/메시지 시스템 전문가 | 채팅, 메시지, chat, message, 실시간 |
| [community-expert](domain/community-expert.md) | 커뮤니티(게시글/댓글) 전문가 | 게시글, 댓글, 좋아요, post, comment |
| [ai-analysis-expert](domain/ai-analysis-expert.md) | AI 분석/온보딩 전문가 | AI 분석, 온보딩, 에이전트 |
| [auth-expert](domain/auth-expert.md) | 인증/OAuth 전문가 | 로그인, 인증, OAuth, 세션 |
| [search-expert](domain/search-expert.md) | 검색 시스템 전문가 | 검색, search, 필터 |
| [admin-expert](domain/admin-expert.md) | 관리자 기능 전문가 | 관리자, admin, 대시보드 |
| [ui-ux-expert](domain/ui-ux-expert.md) | UI/UX 전문가 | UI, UX, 디자인, Stimulus |

### 품질 에이전트 (Quality Experts)

| 에이전트 | 설명 | 트리거 키워드 |
|---------|------|--------------|
| [security-expert](quality/security-expert.md) | 보안 취약점 분석 | 보안, security, OWASP, 취약점 |
| [code-review-expert](quality/code-review-expert.md) | 코드 품질 검수 | 코드 리뷰, 품질, review |
| [data-integrity-expert](quality/data-integrity-expert.md) | 데이터 정합성 검증 | Race Condition, 데이터 정합성, 동시성 |
| [performance-expert](quality/performance-expert.md) | 성능 최적화 | 성능, N+1, 느림, 최적화 |

---

## 사용 방법

### 1. 자동 활성화 (권장)
에이전트는 트리거 키워드가 포함된 요청 시 자동으로 컨텍스트가 로드됩니다.

```
사용자: "채팅 메시지 중복 방지 로직을 확인해줘"
→ chat-expert.md 컨텍스트 자동 활성화
```

### 2. 명시적 호출
특정 에이전트를 명시적으로 호출할 수도 있습니다.

```
사용자: "@chat-expert 실시간 메시지 전송 기능 개선해줘"
```

---

## 에이전트 구조

각 에이전트 파일은 다음 구조를 따릅니다:

```markdown
---
name: [agent-name]
description: [한줄 설명]
triggers: [트리거 키워드 목록]
related_skills: [연계 스킬 목록]
---

# [Agent Name]

## 🎯 역할
[에이전트의 주요 역할 설명]

## 📁 담당 파일
### Controllers / Models / Services / Views / Tests
[파일 경로 목록]

## 🔧 핵심 패턴
[도메인 특화 코딩 패턴]

## ⚠️ 주의사항
[도메인별 함정 및 금지 패턴]

## ✅ 체크리스트
[작업 완료 전 확인 항목]
```

---

## 기존 스킬과의 관계

에이전트는 기존 스킬과 **보완 관계**입니다:

| 구분 | Skills | Agents |
|------|--------|--------|
| **역할** | 특정 작업 자동화 | 도메인 지식 제공 |
| **범위** | 범용 (모든 Rails 프로젝트) | 프로젝트 특화 |
| **호출** | `/skill-name` 또는 키워드 | 트리거 키워드 |
| **예시** | `test-gen`: 테스트 생성 | `chat-expert`: 채팅 도메인 지식 |

### 연계 예시

```
요청: "채팅 메시지에 대한 테스트 추가해줘"

1. chat-expert → 채팅 시스템 구조, 중복 방지 패턴, 관련 파일 정보 제공
2. test-gen → 테스트 코드 자동 생성

결과: 도메인 지식 기반의 정확한 테스트 생성
```

---

## 폴더 구조

```
.claude/agents/
├── README.md                      # 이 파일
│
├── domain/                        # 도메인별 에이전트
│   ├── chat-expert.md             # 채팅 전문가
│   ├── community-expert.md        # 커뮤니티 전문가
│   ├── ai-analysis-expert.md      # AI 분석 전문가
│   ├── auth-expert.md             # 인증 전문가
│   ├── search-expert.md           # 검색 전문가
│   ├── admin-expert.md            # 관리자 전문가
│   └── ui-ux-expert.md            # UI/UX 전문가
│
└── quality/                       # 품질 에이전트
    ├── security-expert.md         # 보안 전문가
    ├── code-review-expert.md      # 코드 리뷰 전문가
    ├── data-integrity-expert.md   # 데이터 안정성 전문가
    └── performance-expert.md      # 성능 최적화 전문가
```

---

## 에이전트 추가/수정 가이드

### 새 에이전트 추가 시
1. 적절한 폴더에 `[name]-expert.md` 파일 생성
2. 표준 템플릿 구조 준수
3. 이 README.md의 목록에 추가
4. CLAUDE.md에 에이전트 섹션 업데이트

### 에이전트 수정 시
1. 담당 파일 목록 최신화
2. 핵심 패턴/주의사항 업데이트
3. 연계 스킬 확인

---

## 참조 문서

- [CLAUDE.md](../CLAUDE.md) - 프로젝트 메인 컨텍스트
- [skills/README.md](../skills/README.md) - 스킬 가이드
- [standards/](../standards/) - 코딩 표준
- [rules/](../rules/) - Claude Code 규칙
