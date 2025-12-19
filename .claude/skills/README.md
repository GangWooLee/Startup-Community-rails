# Claude Skills for Startup Community Rails

이 디렉토리는 Startup Community Rails 프로젝트를 위한 커스텀 Claude Skills를 포함합니다.

## 📦 Available Skills

### Backend Skills

#### 1. rails-resource
**완전한 Rails 리소스 생성 (모델, 컨트롤러, 뷰, 테스트)**

프로젝트의 기존 패턴을 따라 새로운 리소스를 빠르게 생성합니다.

- **Trigger keywords**: "create model", "add feature", "generate resource", "build system"
- **Includes**: Migration, Model, Controller, Views, Tests, Fixtures
- **Pattern matching**: Tailwind CSS, Enum i18n, Counter caches, Authorization
- **Scripts**: `generate_resource.rb` - Automated resource generation

#### 2. test-gen
**포괄적인 Minitest 테스트 스위트 생성**

빈 테스트 파일을 실용적인 테스트 스위트로 변환합니다.

- **Trigger keywords**: "add tests", "test coverage", "write tests for", "generate tests"
- **Includes**: Model tests, Controller tests, Realistic fixtures
- **Coverage goals**: Core models 90%+, Feature models 85%+
- **Scripts**:
  - `run_tests.sh` - Test runner with coverage analysis
  - `generate_fixtures.rb` - Automatic fixture generation

#### 3. api-endpoint
**JSON API 엔드포인트 생성 (인증 및 버전 관리 포함)**

RESTful JSON API를 빠르게 생성하고 인증을 추가합니다.

- **Trigger keywords**: "create API", "add endpoint", "JSON response", "API for mobile"
- **Includes**: API controller, Authentication, Serialization, Error handling
- **Features**: Token-based auth, Versioning (v1, v2), CORS support
- **Response format**: `{ data: {}, meta: {} }`

#### 4. background-job ✨ **NEW!**
**비동기 작업 처리 (Solid Queue 사용)**

백그라운드 작업을 위한 Job 클래스를 생성합니다.

- **Trigger keywords**: "send email in background", "process async", "create job", "schedule task"
- **Includes**: Job class, Error handling, Retry logic, Queue configuration
- **Use cases**: Email sending, Notifications, Data processing, Scheduled cleanup
- **Features**: Queue priorities, Monitoring dashboard

#### 5. service-object ✨ **NEW!**
**복잡한 비즈니스 로직 분리**

Fat Controller/Model을 Service Object로 리팩토링합니다.

- **Trigger keywords**: "extract logic", "create service", "business logic", "refactor controller"
- **Includes**: Service class, Error collection, Transaction safety
- **Use cases**: User registration, Payment processing, Data import, Multi-model operations
- **Patterns**: Result object, Error handling, Chainable methods

#### 6. query-object ✨ **NEW!**
**복잡한 데이터베이스 쿼리 관리**

복잡하고 재사용 가능한 쿼리를 Query Object로 추출합니다.

- **Trigger keywords**: "complex query", "search", "filter posts", "advanced search", "query builder"
- **Includes**: Query class, Chainable filters, Performance optimization
- **Use cases**: Advanced search, Multi-filter queries, Analytics, Reporting
- **Features**: Eager loading, Counter caches, Batch processing

### DevOps Skills

#### 7. logging-setup ✨ **NEW!**
**프로덕션급 로그 시스템 구축**

구조화된 로깅, 성능 모니터링, 에러 추적을 위한 완전한 로깅 시스템을 자동으로 설정합니다.

- **Trigger keywords**: "setup logging", "add logging", "log management", "monitoring", "track errors"
- **Includes**: Lograge (JSON), Business logger, Performance tracking, Error tracking (Sentry)
- **Use cases**: Production monitoring, Performance analysis, Error debugging, Audit logging
- **Scripts**: `setup_logging.rb` - Full automated setup (9 steps)
- **Features**: Log rotation, Custom loggers, Request/Job tracking, Structured JSON output

### Frontend Skills

#### 8. ui-component
**Tailwind UI 컴포넌트 생성 (프로젝트 디자인 시스템 준수)**

프로젝트의 Tailwind 테마를 사용한 재사용 가능한 UI 컴포넌트를 생성합니다.

- **Trigger keywords**: "create component", "add UI element", "make button/card/form"
- **Components**: Buttons, Cards, Forms, Badges, Modals
- **Includes**: Responsive design, Accessibility, Tailwind patterns
- **Project patterns**: Color variables, Spacing, Typography

#### 9. stimulus-controller
**Stimulus 컨트롤러 생성 (Turbo 통합)**

인터랙티브 UI를 위한 Stimulus 컨트롤러를 빠르게 생성합니다.

- **Trigger keywords**: "add interaction", "make it interactive", "create stimulus controller"
- **Includes**: Controller file, Data attributes, Turbo integration
- **Common patterns**: Modal, Tab, Dropdown, Toggle, Form validation

### Documentation Skills

#### 10. doc-sync
**코드 변경사항으로 문서 자동 동기화**

코드베이스 변경사항을 `.claude/` 문서에 자동으로 반영합니다.

- **Trigger keywords**: "update docs", "sync documentation", "docs out of date"
- **Updates**: DATABASE.md, API.md, TASKS.md, ARCHITECTURE.md
- **Auto-detection**: 파일 변경 → 문서 매핑 자동 감지
- **Scripts**:
  - `sync_database_docs.rb` - DATABASE.md 자동 생성
  - `sync_api_docs.sh` - API.md 자동 생성

## 🎯 Usage

### In Claude Code CLI
스킬은 자동으로 감지되고 적절한 키워드에 반응합니다:

```
You: Create a Notification model with user references and content
Claude: [rails-resource skill activates automatically]

You: Add tests for the User model
Claude: [test-gen skill activates automatically]

You: Update the database documentation
Claude: [doc-sync skill activates automatically]
```

### Manual Skill Execution
스크립트를 직접 실행할 수도 있습니다:

```bash
# Generate a new resource
ruby .claude/skills/rails-resource/scripts/generate_resource.rb Article title:string content:text

# Run tests with coverage
bash .claude/skills/test-gen/scripts/run_tests.sh all

# Sync documentation
ruby .claude/skills/doc-sync/scripts/sync_database_docs.rb
bash .claude/skills/doc-sync/scripts/sync_api_docs.sh

# Setup logging system
ruby .claude/skills/logging-setup/scripts/setup_logging.rb
```

## 📁 Structure

Each skill follows the official Anthropic skills structure:

```
skill-name/
├── SKILL.md              # Main skill definition (<500 lines)
├── reference/            # Detailed reference documentation
│   └── *.md
├── examples/             # Code examples and patterns
│   └── *.md
└── scripts/              # Executable automation scripts
    └── *.{rb,sh}
```

## 🔧 Development

### Best Practices
이 스킬들은 [Anthropic Skills Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)를 따릅니다:

- ✅ **Progressive disclosure**: Main files are concise, details in separate files
- ✅ **Workflow checklists**: Task tracking for complex operations
- ✅ **Concise instructions**: Assumes Claude knows Rails basics
- ✅ **Project-specific**: Tailored to this codebase's patterns
- ✅ **Executable scripts**: Automation where possible

### Updating Skills
스킬을 수정할 때:

1. SKILL.md는 200줄 미만으로 유지
2. 상세 내용은 reference/examples 디렉토리로 분리
3. 실행 가능한 스크립트 제공 (가능한 경우)
4. 명확한 트리거 키워드 포함
5. 프로젝트 패턴과 일관성 유지

## 📚 References

- [Official Anthropic Skills Repo](https://github.com/anthropics/skills)
- [Agent Skills Documentation](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)
- [Best Practices Guide](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

## 📊 Statistics

| Skill | Type | SKILL.md Lines | Additional Files | Scripts |
|-------|------|----------------|------------------|---------|
| rails-resource | Backend | 192 | 4 reference docs | 1 generator |
| test-gen | Backend | 189 | 3 example docs | 2 utilities |
| api-endpoint | Backend | ~200 | - | - |
| background-job | Backend | ~220 | - | - |
| service-object | Backend | ~280 | - | - |
| query-object | Backend | ~260 | - | - |
| logging-setup | DevOps | ~260 | - | 1 automation |
| ui-component | Frontend | ~200 | 5 reference docs + 2 examples | - |
| stimulus-controller | Frontend | ~180 | 2 examples | - |
| doc-sync | Documentation | 226 | - | 2 sync scripts |
| **Total** | **10 skills** | **~2,207** | **16 docs** | **6 scripts** |

## 🎯 Skill Coverage

### Backend (60%)
- ✅ Resource generation (rails-resource)
- ✅ Testing (test-gen)
- ✅ API development (api-endpoint)
- ✅ Background jobs (background-job)
- ✅ Business logic (service-object)
- ✅ Complex queries (query-object)

### DevOps (10%) 🆕
- ✅ Logging system (logging-setup) **NEW!**
- ⏳ Deployment automation (future)
- ⏳ Performance monitoring (future)

### Frontend (20%)
- ✅ UI components (ui-component)
- ✅ Interactivity (stimulus-controller)

### Documentation (10%)
- ✅ Doc synchronization (doc-sync)

---

**Last Updated**: 2025-12-19
**Project**: Startup Community Rails
**Claude Skills Version**: 4.0.0
**Total Skills**: 10 (6 Backend + 1 DevOps + 2 Frontend + 1 Documentation)

## 🚀 Recent Updates

### v4.0.0 - DevOps Category Launch 🆕
**New Skill**:
- **logging-setup**: Production-grade logging system
  - Structured JSON logging with Lograge
  - Custom business event loggers
  - Performance tracking (requests, jobs)
  - Error tracking with Sentry integration
  - Automated setup script (9 steps)
  - Log rotation and management

**Impact**:
- Full observability in production environments
- Easy debugging with structured logs
- Performance monitoring out of the box
- Audit trail for business events

### v3.0.0 - Backend Efficiency Skills
**Skills Added**:
- **background-job**: Async task processing with Solid Queue
- **service-object**: Extract complex business logic
- **query-object**: Manage complex database queries

**Impact**:
- Clean, maintainable code architecture
- Better separation of concerns
- Improved performance and scalability
- Easier testing and debugging
