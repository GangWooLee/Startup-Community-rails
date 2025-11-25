# Startup Community Platform - Claude Context

## 프로젝트 개요
스타트업 커뮤니티 플랫폼 - Rails 기반 웹 애플리케이션

**비전**: "아이디어·사람·외주가 한 공간에서 연결되는 최초의 창업 커뮤니티"

**목적**:
한국 초보 창업자들이 겪는 정보 부족, 외주처 산재, 네트워크 부재 문제를 해결하기 위해
**커뮤니티 기반의 신뢰 데이터**와 **외주 기능**을 결합하여
처음 창업하는 사람들이 시행착오 없이 시작할 수 있도록 돕는 플랫폼

**핵심 가치**:
- 커뮤니티 활동 → 프로필 → 외주 공고가 자연스럽게 연결되는 사용자 흐름
- 신뢰 기반 프로필을 통한 사람과 프로젝트의 매칭
- 파편화된 정보의 통합 (커뮤니티 + 외주 + 네트워킹)

**타겟 사용자**:
- 대학생/초기 창업자
- 사이드프로젝트를 하고 싶은 개발자/디자이너/기획자
- 외주를 맡기고 싶은 소규모 창업자
- 창업 관련 인사이트를 얻고 싶은 일반 사용자

---

## 기술 스택

### Backend
- **Rails**: 8.1.1
- **Ruby**: 3.4.7
- **Database**: SQLite3 (개발), PostgreSQL (프로덕션 권장)
- **Job Queue**: Solid Queue
- **Cache**: Solid Cache
- **WebSocket**: Solid Cable

### Frontend
- **Framework**: Hotwire (Turbo + Stimulus)
- **Asset Pipeline**: Propshaft
- **Import Maps**: importmap-rails
- **Styling**: [CSS 프레임워크 선택 시 추가]

### Infrastructure
- **Web Server**: Puma
- **Deployment**: Kamal (Docker)
- **Image Processing**: ImageMagick (image_processing gem)

### Development & Testing
- **Testing**: Minitest, Capybara, Selenium
- **Linting**: Rubocop Rails Omakase
- **Security**: Brakeman, Bundler Audit
- **Debugging**: Debug gem

---

## 프로젝트 구조

```
app/
├── controllers/     # MVC Controllers
├── models/          # ActiveRecord Models
├── views/           # ERB Templates
├── javascript/      # Stimulus Controllers
├── assets/          # CSS, Images
├── jobs/            # Background Jobs
├── mailers/         # Email Templates
└── helpers/         # View Helpers

config/
├── routes.rb        # 라우팅 정의
├── database.yml     # DB 설정
└── initializers/    # 초기화 코드

db/
├── migrate/         # 마이그레이션
└── seeds.rb         # 초기 데이터

test/
├── controllers/     # Controller 테스트
├── models/          # Model 테스트
├── system/          # E2E 테스트
└── fixtures/        # 테스트 데이터
```

---

## 코딩 규칙 & 컨벤션

### Ruby/Rails 스타일
- **Style Guide**: Rubocop Rails Omakase 준수
- **Naming**: snake_case (변수/메서드), CamelCase (클래스)
- **Indentation**: 2 spaces
- **Line Length**: 120자 이하

### 아키텍처 원칙
- **RESTful Design**: 리소스 기반 라우팅 우선
- **Skinny Controllers, Fat Models**: 비즈니스 로직은 모델에
- **DRY**: 중복 코드 제거, Concern 활용
- **Convention over Configuration**: Rails 규약 준수

### 데이터베이스
- **Migration**: 롤백 가능하게 작성
- **Index**: 외래키, 검색 컬럼에 인덱스 추가
- **Validation**: 모델 레벨 검증 필수

### 테스팅
- **Coverage**: 핵심 기능 80% 이상
- **Test Types**:
  - Unit (모델, 헬퍼)
  - Integration (컨트롤러)
  - System (E2E)
- **Fixtures**: 명확하고 최소한의 데이터

### 보안
- **Strong Parameters**: 컨트롤러에서 파라미터 필터링
- **CSRF Protection**: Rails 기본 보호 활성화
- **SQL Injection**: Raw SQL 지양, ActiveRecord 사용
- **XSS**: ERB 자동 이스케이핑 활용
- **Authentication**: has_secure_password 사용 권장

---

## 개발 워크플로우

### Branch 전략
```
main          # 프로덕션 브랜치
└── develop   # 개발 브랜치
    └── feature/[기능명]  # 기능 브랜치
```

### Commit 메시지
```
[타입] 제목 (50자 이내)

상세 설명 (선택사항)

예시:
[feat] 사용자 회원가입 기능 구현
[fix] 로그인 세션 버그 수정
[refactor] User 모델 리팩토링
[test] User 모델 테스트 추가
[docs] README 업데이트
```

### 개발 순서
1. 요구사항 분석
2. 모델 설계 (ERD)
3. 마이그레이션 작성
4. 모델 + 테스트 작성
5. 컨트롤러 + 라우팅
6. 뷰 구현
7. 통합 테스트
8. 리팩토링

---

## 금지 사항

### 절대 하지 말 것
❌ `User.all` (without pagination)
❌ N+1 쿼리 (includes/joins 사용)
❌ SQL Injection 가능한 raw query
❌ 민감정보 로그 출력
❌ credentials 파일 커밋
❌ 테스트 없는 핵심 기능 배포
❌ production에서 db:reset/drop

### 지양할 것
⚠️ 컨트롤러에 비즈니스 로직
⚠️ 뷰에 복잡한 Ruby 로직
⚠️ God Object (거대한 클래스)
⚠️ Magic Number (상수화 필요)
⚠️ 과도한 Callback (모델)

---

## 참조 문서

- **PRD**: `.claude/PRD.md` - 제품 요구사항 상세
- **Architecture**: `.claude/ARCHITECTURE.md` - 시스템 아키텍처
- **API**: `.claude/API.md` - API 설계 문서
- **Database**: `.claude/DATABASE.md` - ERD 및 스키마
- **Tasks**: `.claude/TASKS.md` - 작업 목록 및 진행상황

---

## Claude 작업 지침

### 코드 생성 시
1. **먼저 읽기**: 관련 파일 Read로 확인
2. **테스트 작성**: TDD 방식 권장
3. **마이그레이션**: 모델 변경 시 자동 생성
4. **라우팅**: RESTful 패턴 우선
5. **검증**: Rubocop, 테스트 실행

### 파일 수정 시
1. 기존 코드 스타일 유지
2. 관련 테스트 함께 수정
3. 변경사항 명확히 설명
4. 잠재적 사이드 이펙트 언급

### 문제 해결 시
1. 에러 로그 전체 확인
2. 관련 파일 컨텍스트 파악
3. Rails 가이드 참조
4. 여러 해결책 제시 (장단점)
