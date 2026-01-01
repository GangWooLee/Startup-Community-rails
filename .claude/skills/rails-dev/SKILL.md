---
description: Rails 개발을 위한 통합 스킬 라우터. 13개 전문 스킬(테스팅, 보안, API, 인프라, 문서화 등)을 자동으로 선택하여 적용합니다. 복잡한 Rails 작업 시 적합한 전문가 스킬로 라우팅합니다.
trigger_keywords:
  - rails expert
  - rails architect
  - rails security
  - rails api
  - rails testing
  - rails graphql
  - rails devops
  - rails business logic
  - rails background jobs
  - rails project management
  - 레일즈 전문가
  - 레일즈 보안
globs:
  - "app/**/*.rb"
  - "config/**/*.rb"
  - "db/**/*.rb"
alwaysApply: false
---

# Rails Development Skills Router

> 출처: [alec-c4/claude-skills-rails-dev](https://github.com/alec-c4/claude-skills-rails-dev)
> 13개 전문 Rails 스킬을 포함한 모듈식 스킬 컬렉션

## 개요

이 스킬은 요청 유형에 따라 적합한 Rails 전문가 스킬로 라우팅합니다.
복잡한 작업의 경우 여러 스킬을 조합하여 단계별로 구현합니다.

---

## 스킬 카탈로그 (13개)

### Development (4개)

#### rails-testing
**Rails 테스팅 전문가**
- Minitest/RSpec 테스트 작성
- 컨트롤러, 모델, 시스템 테스트
- TDD 워크플로우
- 90%+ 커버리지 목표

#### rails-viewcomponents
**ViewComponent 전문가**
- 재사용 가능한 뷰 컴포넌트
- 컴포넌트 프리뷰 및 테스트
- Stimulus 통합

#### rails-business-logic
**비즈니스 로직 전문가**
- Service Object 패턴
- Form Object 패턴
- PORO (Plain Old Ruby Object)
- 복잡한 비즈니스 규칙 추출

#### ruby-on-rails-development
**일반 Rails 개발**
- Rails 컨벤션 및 모범 사례
- MVC 아키텍처
- ActiveRecord 패턴

### APIs & Frontend (3개)

#### rails-api
**RESTful API 전문가**
- JSON API 설계
- 버전 관리 (v1, v2)
- 인증 및 권한 부여
- API 문서화

#### rails-graphql
**GraphQL API 전문가**
- GraphQL 스키마 설계
- Query/Mutation 구현
- N+1 방지 (DataLoader)
- 구독 처리

#### rails-inertia
**Inertia.js 전문가**
- Rails + React/Vue 통합
- SSR 설정
- 페이지 컴포넌트

### Infrastructure (3개)

#### rails-background-jobs
**백그라운드 작업 전문가**
- Solid Queue 설정
- Job 클래스 설계
- 재시도 로직
- 스케줄링

#### rails-devops
**DevOps 전문가**
- Kamal 배포
- Docker 설정
- CI/CD 파이프라인
- 환경 변수 관리

#### rails-security
**보안 전문가**
```
🔒 Pundit 정책 설계
🔒 Lockbox 암호화
🔒 Blind Index 검색
🔒 인증 시스템
🔒 보안 설정
🔒 취약점 수정
```

**주요 영역**:
- 인가 (Pundit policies)
- 데이터 암호화 (Lockbox)
- 보안 검색 (Blind Index)
- OWASP Top 10 방지

### Analysis & Coordination (2개)

#### rails-analyst
**비즈니스 분석 전문가**
- JTBD (Jobs To Be Done)
- 유스케이스 분석
- 추정 및 리스크 분석
- 요구사항 정의

#### rails-project-manager
**프로젝트 관리자**
- 작업 분해 및 조율
- 여러 스킬 협업 조율
- 구현 단계 계획
- 진행 상황 추적

### Documentation (1개)

#### rails-technical-writer
**기술 문서화 전문가**
- API 문서
- 아키텍처 문서
- 온보딩 가이드
- CHANGELOG 관리

---

## 자동 라우팅 규칙

| 키워드 | 활성화 스킬 |
|--------|-------------|
| "write tests", "TDD" | rails-testing |
| "service object", "extract logic" | rails-business-logic |
| "API endpoint", "JSON" | rails-api |
| "security", "Pundit", "encrypt" | rails-security |
| "background job", "async" | rails-background-jobs |
| "deploy", "Docker", "Kamal" | rails-devops |
| "GraphQL", "query", "mutation" | rails-graphql |
| "component", "ViewComponent" | rails-viewcomponents |
| "plan", "coordinate", "manage" | rails-project-manager |

---

## 핵심 원칙 (모든 스킬 공통)

### 1. Test-First Development
```ruby
# ✅ 항상 테스트 먼저
test "creates user with valid params" do
  assert_difference -> { User.count }, 1 do
    post users_path, params: { user: valid_params }
  end
end
```

### 2. Rails Conventions
```ruby
# ✅ Convention over Configuration
class User < ApplicationRecord
  has_many :posts
  validates :email, presence: true, uniqueness: true
end
```

### 3. Security by Design
```ruby
# ✅ Strong Parameters
def user_params
  params.require(:user).permit(:name, :email)
end
```

### 4. Incremental Progress
```
작은 커밋 → 테스트 통과 확인 → 다음 단계
```

---

## 프로젝트 적용 (Rails 8.1.1)

### 호환성
- Rails 7.0 ~ 8.1 지원
- Ruby 3.2+ 지원
- Hotwire (Turbo + Stimulus) 완벽 지원

### 기존 스킬과의 관계

| 이 프로젝트 스킬 | rails-dev 대응 스킬 | 관계 |
|------------------|---------------------|------|
| rails-resource | ruby-on-rails-development | 보완 |
| test-gen | rails-testing | 보완 |
| api-endpoint | rails-api | 보완 |
| service-object | rails-business-logic | 보완 |
| background-job | rails-background-jobs | 보완 |
| security-audit | rails-security | 보완 |

### 사용 시나리오

**복잡한 기능 구현 시**:
```
1. rails-analyst → 요구사항 분석
2. rails-project-manager → 작업 분해
3. rails-testing → TDD 시작
4. rails-business-logic → Service Object
5. rails-security → 보안 검토
```

---

## 설치 방법 (선택사항)

전체 스킬 컬렉션 설치:

```bash
# ~/.claude/skills에 설치
git clone https://github.com/alec-c4/claude-skills-rails-dev.git ~/.claude/skills/rails-dev-full
```

> **참고**: 이 프로젝트에는 이미 유사 기능의 커스텀 스킬이 있습니다.
> rails-dev 스킬은 추가 참조 및 보완 용도로 사용합니다.

---

## 스킬 선택 가이드

### 프로젝트 스킬 우선 사용
| 작업 | 우선 스킬 | 보조 스킬 |
|------|----------|----------|
| 리소스 생성 | rails-resource | ruby-on-rails-development |
| 테스트 작성 | test-gen | rails-testing |
| API 구축 | api-endpoint | rails-api |
| 보안 감사 | security-audit | rails-security |
| 서비스 추출 | service-object | rails-business-logic |

### rails-dev 스킬 직접 사용
| 작업 | 스킬 |
|------|------|
| GraphQL API | rails-graphql |
| ViewComponent | rails-viewcomponents |
| Inertia.js | rails-inertia |
| DevOps/배포 | rails-devops |
| 프로젝트 관리 | rails-project-manager |
| 비즈니스 분석 | rails-analyst |

---

**Version**: 1.0.0
**Source**: [alec-c4/claude-skills-rails-dev](https://github.com/alec-c4/claude-skills-rails-dev)
**Last Updated**: 2026-01-01
