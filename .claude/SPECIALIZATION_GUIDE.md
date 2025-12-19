# 분야별 Claude 최적화 가이드

프로젝트 개발의 각 분야에서 Subagent와 Skills를 효과적으로 활용하는 방법

## 🎨 Frontend 분야

### 1. UI/UX Design

**Subagent 활용** (탐색/분석):
```
질문: "우리 프로젝트의 UI 컴포넌트 일관성을 분석해줘"
→ Explore Subagent가 모든 view 파일을 탐색하고 패턴 분석
→ 일관성 없는 스타일, 중복 코드 식별
```

**Skill 활용** (생성/적용):
- 새로운 Skill 제안: **ui-component**
  ```yaml
  name: ui-component
  description: Generate consistent Tailwind UI components following project design system
  ```
  - 버튼, 카드, 폼 등 재사용 가능한 컴포넌트 생성
  - 프로젝트의 Tailwind 테마 자동 적용
  - 접근성(a11y) 기본 설정 포함

**추천 조합**:
```
1. Explore Subagent로 기존 디자인 패턴 분석
2. ui-component Skill로 일관된 컴포넌트 생성
3. 반복 사용
```

### 2. 프론트엔드 로직 (Stimulus)

**Subagent 활용**:
```
질문: "이 페이지에 필요한 인터랙션은 무엇인가?"
→ Plan Subagent가 요구사항 분석 및 Stimulus 컨트롤러 설계
```

**Skill 활용**:
- 새로운 Skill 제안: **stimulus-controller**
  ```yaml
  name: stimulus-controller
  description: Generate Stimulus controllers with Turbo integration
  ```
  - 표준 Stimulus 패턴 적용
  - Turbo Frame/Stream 통합
  - 이벤트 핸들링 보일러플레이트

**실제 사용 예시**:
```
You: "Add a like button with optimistic UI"
Claude: [stimulus-controller skill activates]
→ Stimulus controller 생성
→ Turbo Stream 응답 설정
→ CSS 애니메이션 추가
```

---

## ⚙️ Backend 분야

### 1. Database 설계

**Subagent 활용** (복잡한 설계):
```
질문: "알림 시스템을 위한 DB 설계를 해줘"
→ Plan Subagent가 요구사항 분석
→ ERD 설계, 인덱스 전략, 마이그레이션 순서 제안
```

**Skill 활용** (실행):
- **기존 rails-resource Skill** 활용
  - 설계된 모델을 실제 코드로 생성
  - 인덱스, 외래키 자동 추가
  - 검증 규칙 적용

**추천 조합**:
```
1. Plan Subagent로 DB 설계
2. rails-resource Skill로 모델/마이그레이션 생성
3. test-gen Skill로 테스트 추가
4. doc-sync Skill로 DATABASE.md 업데이트
```

### 2. API 개발

**Subagent 활용**:
```
질문: "RESTful API를 설계해줘 for mobile app"
→ Plan Subagent가 엔드포인트 설계, 인증 전략, 응답 형식 제안
```

**Skill 활용**:
- 새로운 Skill 제안: **api-endpoint**
  ```yaml
  name: api-endpoint
  description: Generate JSON API endpoints with authentication and versioning
  ```
  - API 컨트롤러 생성 (JSON 응답)
  - Token 인증 적용
  - API 문서 자동 생성
  - Versioning 지원 (v1, v2)

### 3. 로깅 & 모니터링

**Subagent 활용**:
```
질문: "프로덕션 로그 구조를 설계해줘"
→ General-purpose Subagent가 로깅 전략 리서치 및 제안
```

**Skill 활용**:
- 새로운 Skill 제안: **logging-setup**
  ```yaml
  name: logging-setup
  description: Add structured logging with performance tracking
  ```
  - Lograge 설정
  - Custom 로그 포맷
  - 성능 메트릭 추가
  - 에러 추적 통합

### 4. 서버 관리 & 배포

**Subagent 활용**:
```
질문: "Kamal로 배포 설정을 최적화해줘"
→ General-purpose Subagent가 현재 설정 분석 및 개선 제안
```

**Skill 활용**:
- 새로운 Skill 제안: **deploy-config**
  ```yaml
  name: deploy-config
  description: Configure deployment with Kamal, Docker, and CI/CD
  ```
  - Dockerfile 최적화
  - Kamal 설정 생성
  - GitHub Actions 워크플로우
  - 환경변수 관리

---

## 🔄 실전 워크플로우 예시

### 시나리오 1: 새로운 기능 추가 (Full Stack)

**요청**: "실시간 알림 시스템을 추가해줘"

**최적 접근 방식**:

```
Step 1: 계획 수립 (Subagent)
You: "알림 시스템의 전체 아키텍처를 설계해줘"
→ Plan Subagent 실행
→ DB 설계, API 설계, 프론트엔드 전략 제안

Step 2: Backend 구현 (Skills)
You: "Notification 모델을 생성해줘 [설계 기반]"
→ rails-resource Skill 자동 활성화
→ 모델, 마이그레이션, 컨트롤러 생성

Step 3: Frontend 구현 (Skills)
You: "알림 드롭다운 컴포넌트를 만들어줘"
→ ui-component Skill 활성화 (생성 필요)
→ Tailwind 기반 컴포넌트 + Stimulus 컨트롤러

Step 4: 테스트 & 문서화 (Skills)
You: "알림 시스템 테스트를 추가해줘"
→ test-gen Skill 자동 활성화
→ 모델/컨트롤러 테스트 생성

You: "문서를 업데이트해줘"
→ doc-sync Skill 자동 활성화
→ DATABASE.md, API.md 자동 업데이트
```

### 시나리오 2: 성능 최적화 (Backend Focus)

**요청**: "N+1 쿼리를 찾아서 최적화해줘"

**최적 접근 방식**:

```
Step 1: 분석 (Subagent)
You: "N+1 쿼리 문제가 있는 곳을 찾아줘"
→ Explore Subagent 실행
→ 모든 컨트롤러 분석
→ includes() 누락 위치 리포트

Step 2: 수정 (직접 실행 - Skill 불필요)
Claude가 발견한 위치를 직접 수정
→ includes(:user, :comments) 추가
→ counter_cache 설정

Step 3: 검증 (Subagent)
You: "최적화 결과를 검증해줘"
→ General-purpose Subagent가 벤치마크 코드 작성
→ 성능 비교
```

### 시나리오 3: UI 리팩토링 (Frontend Focus)

**요청**: "모든 폼을 일관된 스타일로 통일해줘"

**최적 접근 방식**:

```
Step 1: 패턴 분석 (Subagent)
You: "프로젝트의 모든 폼을 분석해줘"
→ Explore Subagent 실행
→ 폼 패턴 추출, 불일치 식별

Step 2: 표준 패턴 정의 (Plan Subagent)
You: "표준 폼 컴포넌트를 설계해줘"
→ 디자인 시스템 기반 제안

Step 3: Skill 생성 (일회성)
새로운 form-builder Skill 생성
→ 표준 패턴을 코드로 정의

Step 4: 적용 (Skill 반복 사용)
각 폼마다 form-builder Skill 실행
→ 일관된 스타일 자동 적용
```

---

## 📋 분야별 추천 Skill 로드맵

### 우선순위 1: 즉시 생성 추천

| Skill | 분야 | 이유 |
|-------|------|------|
| **ui-component** | Frontend | 반복적인 UI 생성 작업 많음 |
| **api-endpoint** | Backend | API 확장 가능성 높음 |
| **stimulus-controller** | Frontend | Hotwire 프로젝트의 핵심 |

### 우선순위 2: 필요 시 생성

| Skill | 분야 | 언제 필요? |
|-------|------|-----------|
| **deploy-config** | DevOps | 배포 설정 시 |
| **logging-setup** | Backend | 프로덕션 준비 시 |
| **performance-audit** | Full Stack | 성능 이슈 발생 시 |

### 우선순위 3: 특수 목적

| Skill | 분야 | 언제 필요? |
|-------|------|-----------|
| **i18n-generator** | Full Stack | 다국어 지원 시 |
| **migration-helper** | Backend | 복잡한 DB 변경 시 |
| **seo-optimizer** | Frontend | SEO 개선 필요 시 |

---

## 🎯 의사결정 플로우차트

```
질문: 이 작업에 Subagent를 쓸까, Skill을 쓸까?

┌─────────────────────────────────┐
│  이 작업을 이전에 해본 적 있나? │
└────────┬────────────────┬────────┘
        NO                YES
         │                 │
         ▼                 ▼
    ┌─────────┐      ┌──────────┐
    │Subagent │      │  Skill   │
    │(탐색/계획)│      │ (실행)   │
    └─────────┘      └──────────┘
         │                 │
         │                 ▼
         │         반복 작업인가?
         │          │           │
         │         YES          NO
         │          │           │
         │          ▼           ▼
         │    Skill 생성    직접 실행
         │       추천
         │          │
         └──────────┴───→ 작업 완료
```

**예시**:
- "N+1 쿼리 찾기" → **Subagent** (탐색)
- "Post 모델 만들기" → **Skill** (rails-resource, 반복 작업)
- "DB 마이그레이션 롤백 전략" → **Subagent** (복잡한 계획)
- "테스트 생성" → **Skill** (test-gen, 패턴 정해짐)

---

## 💡 실전 팁

### 1. Subagent는 "왜?"와 "어떻게?"에 강함
```
Good: "왜 이 쿼리가 느린가?"
Good: "어떻게 캐싱을 구현할까?"
Good: "프로젝트 구조를 어떻게 개선할까?"
```

### 2. Skill은 "만들어줘"에 강함
```
Good: "User 모델 만들어줘" → rails-resource
Good: "테스트 추가해줘" → test-gen
Good: "문서 업데이트해줘" → doc-sync
```

### 3. 조합 사용이 최선
```
1단계(Subagent): "알림 시스템 설계해줘" → 설계 완료
2단계(Skill): "설계대로 구현해줘" → rails-resource 실행
3단계(Skill): "테스트 추가" → test-gen 실행
4단계(Skill): "문서 동기화" → doc-sync 실행
```

### 4. Skill 생성 기준
다음 3가지 조건을 모두 만족하면 Skill 생성:
- ✅ 월 3회 이상 반복되는 작업
- ✅ 명확한 패턴이 존재
- ✅ 프로젝트 특화 규칙 있음

---

## 🚀 다음 단계

### 즉시 실행 가능
1. **ui-component Skill 생성** - 가장 필요도 높음
2. **기존 Skill 활용** - rails-resource, test-gen, doc-sync

### 프로젝트 성장에 따라
1. API 개발 시작 → **api-endpoint Skill** 생성
2. 배포 준비 → **deploy-config Skill** 생성
3. 성능 이슈 발생 → **performance-audit Skill** 생성

### 팀 협업 시
1. Skill을 팀 전체가 공유
2. `.claude/skills/` 디렉토리를 Git으로 관리
3. 각 분야 전문가가 해당 Skill 개선

---

**결론**:
- **Subagent** = 두뇌 (생각, 탐색, 계획)
- **Skill** = 손 (실행, 반복, 자동화)
- **최고의 결과** = 둘을 조합해서 사용!
