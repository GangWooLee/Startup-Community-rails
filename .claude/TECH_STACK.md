# 기술 스택 및 아키텍처 결정

## 문서 정보
- **프로젝트**: Startup Community Platform
- **작성일**: 2025-12-25
- **목적**: 기술 선택 이유와 아키텍처 결정 배경 문서화

---

## 기술 스택 요약

| 영역 | 기술 | 버전 | 선택 이유 |
|------|------|------|----------|
| **Backend** | Ruby on Rails | 8.1.1 | 빠른 개발, 컨벤션 기반 |
| **Language** | Ruby | 3.4.7 | 최신 안정 버전 |
| **Database** | SQLite3 + Solid Suite | - | 단순화, 10만 사용자까지 충분 |
| **Frontend** | Hotwire (Turbo + Stimulus) | - | SPA 같은 UX, JavaScript 최소화 |
| **Styling** | Tailwind CSS | 4.x | 유틸리티 기반, 빠른 스타일링 |
| **AI** | LangchainRB + Gemini | 0.19.5 | Ruby 네이티브, 비용 효율 |
| **Auth** | has_secure_password + OAuth | - | Rails 기본 + 소셜 로그인 |
| **Deployment** | Kamal (Docker) | - | 무료, 간편한 배포 |

---

## 상세 기술 결정

### 1. Database: SQLite3 + Solid Suite

**선택 이유**:
- **Rails 8 최적화**: 초당 수천 건 쓰기, 동시 읽기 가능
- **운영 단순화**: 별도 DB 서버 불필요
- **비용 절감**: 인프라 비용 없음
- **10만 사용자까지 충분**: MVP~초기 성장 단계에 적합

**Solid Suite 구성**:
```yaml
# 각각 독립된 SQLite 파일
primary:   storage/production.sqlite3      # 주 데이터
cache:     storage/production_cache.sqlite3 # 캐시 (256MB)
queue:     storage/production_queue.sqlite3 # 백그라운드 작업
cable:     storage/production_cable.sqlite3 # WebSocket
```

**확장 계획**:
- 10만 사용자 이후 PostgreSQL로 마이그레이션
- `database.yml` 수정만으로 전환 가능

---

### 2. Frontend: Hotwire (Turbo + Stimulus)

**선택 이유**:
- **JavaScript 최소화**: 복잡한 빌드 과정 불필요
- **SPA 같은 UX**: Turbo Drive로 페이지 전환 가속
- **Rails 네이티브**: 별도 프레임워크 학습 불필요
- **실시간 업데이트**: Turbo Streams로 부분 업데이트

**구현 패턴**:
```ruby
# Turbo Stream 예시 (채팅 메시지)
turbo_stream.append "messages", partial: "messages/message"

# Stimulus Controller 예시 (31개 구현)
# - new_message_controller.js (채팅)
# - live_search_controller.js (검색)
# - image_upload_controller.js (이미지)
```

**Import Maps 사용**:
```ruby
# config/importmap.rb
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
```
- Webpack/Esbuild 불필요
- ES Module 기반으로 단순화

---

### 3. Styling: Tailwind CSS

**선택 이유**:
- **유틸리티 기반**: 커스텀 CSS 최소화
- **일관된 디자인**: 디자인 시스템 자동 적용
- **빠른 개발**: 클래스 조합으로 즉시 스타일링
- **Tailwind 4**: 설정 파일 없이 사용 가능

**사용 방식**:
```bash
# 빌드 명령어
bin/rails tailwindcss:build

# CSS 파일
app/assets/tailwind/application.css
```

---

### 4. AI Integration: LangchainRB + Gemini

**선택 이유**:
- **Ruby 네이티브**: Rails와 자연스러운 통합
- **다중 LLM 지원**: OpenAI, Gemini 쉬운 전환
- **비용 효율**: Gemini 무료 티어 활용
- **에이전트 패턴**: 복잡한 AI 로직 구조화

**구현 구조**:
```
app/services/ai/
├── base_agent.rb      # 공통 기능 (에러 핸들링, JSON 파싱)
└── idea_analyzer.rb   # 아이디어 분석 에이전트

lib/
└── langchain_config.rb # LLM 설정 팩토리
```

**API 키 관리**:
```bash
# Rails Credentials 사용
EDITOR="code --wait" bin/rails credentials:edit

# credentials.yml.enc 내용
gemini:
  api_key: YOUR_API_KEY
```

---

### 5. Authentication: has_secure_password + OAuth

**선택 이유**:
- **Rails 기본**: Devise 대비 단순함
- **학습 용이**: 인증 로직 이해하기 쉬움
- **OAuth 확장**: Google, GitHub 소셜 로그인 추가

**구현 방식**:
```ruby
# User 모델
has_secure_password validations: false

# OAuth 연동
has_many :oauth_identities, dependent: :destroy
```

**비밀번호 정책**:
- 최소 8자
- 영문 + 숫자 조합 필수
- 동일 문자 연속 4개 이상 금지

---

### 6. Real-time: Action Cable + Solid Cable

**선택 이유**:
- **Rails 기본**: 별도 서비스 불필요
- **Solid Cable**: SQLite 기반 pub/sub
- **Turbo 통합**: Turbo Streams와 연동

**사용 사례**:
- 채팅 메시지 실시간 전송
- 알림 실시간 업데이트
- 좋아요/댓글 실시간 반영

---

### 7. Background Jobs: Solid Queue

**선택 이유**:
- **SQLite 기반**: Redis 불필요
- **Rails 8 기본**: 설정 최소화
- **신뢰성**: 데이터베이스 트랜잭션 기반

**설정**:
```yaml
# config/solid_queue.yml
production:
  dispatchers:
    - polling_interval: 0.1
  workers:
    - queues: "*"
      threads: 3
      processes: 1
```

**현재 상태**: 설정됨, 실제 Job 미사용 (향후 활용 예정)

---

### 8. File Storage: Active Storage

**선택 이유**:
- **Rails 기본**: 별도 라이브러리 불필요
- **다양한 백엔드**: 로컬, S3, GCS 지원
- **이미지 처리**: image_processing gem 통합

**현재 설정**:
```ruby
# 사용자 아바타
has_one_attached :avatar  # 최대 2MB

# 게시글 이미지
has_many_attached :images  # 최대 5개, 각 5MB
```

---

### 9. Security

**Rate Limiting**:
```ruby
# config/initializers/rack_attack.rb
Rack::Attack.throttle("logins/ip", limit: 5, period: 60.seconds)
```

**CSP (Content Security Policy)**:
- `config/initializers/content_security_policy.rb` 설정

**파일 검증**:
```ruby
# Active Storage 파일 타입 제한
validates :avatar, content_type: ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
```

---

### 10. Deployment: Kamal

**선택 이유**:
- **무료**: 호스팅 비용만 필요
- **Docker 기반**: 일관된 환경
- **간편한 배포**: 한 줄 명령어
- **Thruster**: HTTP/2 + 정적 파일 캐싱

**명령어**:
```bash
kamal deploy  # 배포
kamal rollback  # 롤백
```

---

## 향후 확장 계획

### Phase 1: MVP 완성 (현재)
- SQLite + Solid Suite
- 기본 기능 완성
- 10,000 사용자 목표

### Phase 2: 성장 (10만 사용자)
- PostgreSQL 마이그레이션
- Redis 캐시 도입
- CDN 적용 (CloudFlare)

### Phase 3: 스케일 (100만+ 사용자)
- 수평 확장 (다중 서버)
- Kubernetes 전환 검토
- 마이크로서비스 분리 검토

---

## 기술 결정 원칙

1. **단순함 우선**: 복잡한 솔루션보다 Rails 기본 기능 활용
2. **점진적 확장**: MVP에서 시작, 필요 시 스케일업
3. **Rails 규약 준수**: Convention over Configuration
4. **비용 효율**: 무료/저비용 솔루션 우선
5. **개발 속도**: 빠른 프로토타이핑, 빠른 반복

---

## 참고 자료

- [Rails Guides](https://guides.rubyonrails.org)
- [Hotwire](https://hotwired.dev)
- [Tailwind CSS](https://tailwindcss.com)
- [LangchainRB](https://github.com/patterns-ai-core/langchainrb)
- [Kamal](https://kamal-deploy.org)
