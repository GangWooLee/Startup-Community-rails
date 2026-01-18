---
name: ai-analysis-expert
description: AI 아이디어 분석 시스템 전문가 - 5개 에이전트 오케스트레이션, Gemini Grounding, 비동기 처리
triggers:
  - AI 분석
  - 온보딩
  - 아이디어 분석
  - 에이전트
  - Gemini
  - 분석 결과
  - idea analysis
related_skills:
  - background-job
  - service-object
---

# AI Analysis Expert (AI 분석 전문가)

## 🎯 역할

AI 아이디어 분석 시스템의 모든 측면을 담당합니다:
- 5개 전문 에이전트 오케스트레이션
- Gemini Grounding 실시간 웹 검색
- 백그라운드 Job 비동기 처리
- 사용량 제한 (UsageLimitChecker)
- 비로그인 → 로그인 전환 시 분석 복원

---

## 📁 담당 파일

### Controllers
```
app/controllers/onboarding_controller.rb      # AI 분석 진입점
```

### Services - AI Agents (5개)
```
app/services/ai/base_agent.rb                 # 기본 에이전트 클래스
app/services/ai/agents/summary_agent.rb       # 아이디어 요약
app/services/ai/agents/target_user_agent.rb   # 타겟 사용자 분석
app/services/ai/agents/market_analysis_agent.rb   # 시장 분석
app/services/ai/agents/strategy_agent.rb      # 전략 제안
app/services/ai/agents/scoring_agent.rb       # 점수 산출
```

### Services - Orchestrators
```
app/services/ai/orchestrators/analysis_orchestrator.rb  # 에이전트 조율
```

### Services - Tools
```
app/services/ai/tools/gemini_grounding_tool.rb    # 실시간 웹 검색
app/services/ai/tools/market_data_tool.rb         # 시장 데이터
app/services/ai/tools/competitor_database_tool.rb # 경쟁사 DB
```

### Services - Other
```
app/services/ai/follow_up_generator.rb        # 추가 질문 생성
app/services/ai/expert_score_predictor.rb     # 전문가 점수 예측
app/services/expert_matcher.rb                # 전문가 매칭
app/services/onboarding/analysis_executor.rb  # 분석 실행기
app/services/onboarding/usage_limit_checker.rb # 사용량 체크
app/services/onboarding/mock_data.rb          # 목업 데이터
```

### Models
```
app/models/idea_analysis.rb                   # 분석 결과 저장
```

### Jobs
```
app/jobs/ai_analysis_job.rb                   # 비동기 분석 실행
```

### JavaScript (Stimulus)
```
app/javascript/controllers/ai_input_controller.js   # AI 입력 폼
app/javascript/controllers/ai_loading_controller.js # 로딩 상태
app/javascript/controllers/ai_result_controller.js  # 결과 표시
```

### Views
```
app/views/onboarding/
├── landing.html.erb          # 랜딩 페이지
├── ai_input.html.erb         # AI 입력 화면
├── ai_result.html.erb        # 분석 결과
├── _expert_card_v2.html.erb  # 전문가 카드
├── _expert_profile_overlay.html.erb  # 전문가 모달
└── _score_radar_chart.html.erb       # 점수 차트
```

### Configuration
```
lib/langchain_config.rb                       # Langchain 설정
config/credentials.yml.enc                    # API 키 (GEMINI_API_KEY)
```

### Tests
```
test/controllers/onboarding_controller_test.rb
test/services/ai/agents/*_test.rb
test/services/ai/orchestrators/analysis_orchestrator_test.rb
test/models/idea_analysis_test.rb
test/jobs/ai_analysis_job_test.rb
```

---

## 🔧 핵심 패턴

### 1. 멀티에이전트 오케스트레이션

```ruby
# AnalysisOrchestrator - 5개 에이전트 순차 실행
class AnalysisOrchestrator
  AGENTS = [
    Ai::Agents::SummaryAgent,       # 1. 아이디어 요약
    Ai::Agents::TargetUserAgent,    # 2. 타겟 사용자
    Ai::Agents::MarketAnalysisAgent,# 3. 시장 분석
    Ai::Agents::StrategyAgent,      # 4. 전략 제안
    Ai::Agents::ScoringAgent        # 5. 점수 산출
  ].freeze

  def run
    results = {}
    AGENTS.each do |agent_class|
      result = agent_class.new(@context).call
      results.merge!(result)
      @context.merge!(result)  # 다음 에이전트에 전달
    end
    results
  end
end
```

### 2. Gemini Grounding (실시간 웹 검색)

```ruby
# GeminiGroundingTool - 실시간 정보 검색
class GeminiGroundingTool
  def search(query)
    response = client.generate_content(
      query,
      model: "gemini-2.0-flash",
      tools: [{ google_search: {} }]  # Grounding 활성화
    )
    extract_grounding_results(response)
  end
end
```

### 3. 백그라운드 Job 처리

```ruby
# 로그인 사용자 - 백그라운드 Job으로 실행
class AiAnalysisJob < ApplicationJob
  queue_as :default

  def perform(idea_analysis_id)
    analysis = IdeaAnalysis.find(idea_analysis_id)
    result = Ai::Orchestrators::AnalysisOrchestrator.new(
      idea: analysis.idea,
      follow_up_answers: analysis.follow_up_answers
    ).run

    analysis.update!(
      result: result.to_json,
      status: :completed
    )
  end
end
```

### 4. 비로그인 → 로그인 분석 복원

```ruby
# 비로그인 시 세션 + 쿠키 백업에 저장
session[:pending_input_key] = cache_key
cookies.signed[:pending_input_key] = {
  value: cache_key,
  expires: 1.hour.from_now
}

# 로그인 후 복원
def restore_pending_input_and_analyze
  cache_key = session[:pending_input_key] || cookies.signed[:pending_input_key]
  return unless cache_key

  cached_data = Rails.cache.read(cache_key)
  # 분석 Job 실행...
end
```

### 5. 사용량 제한 체크

```ruby
# UsageLimitChecker
class UsageLimitChecker
  DEFAULT_LIMIT = 3  # 무료 사용자 기본 한도

  def exceeded?
    return false unless @user
    @user.idea_analyses.count >= effective_limit
  end

  def effective_limit
    DEFAULT_LIMIT + (@user&.bonus_analyses || 0)
  end
end
```

### 6. 결과 데이터 구조

```ruby
# IdeaAnalysis 결과 구조
{
  summary: { ... },           # 요약
  target_users: [ ... ],      # 타겟 사용자
  market_analysis: { ... },   # 시장 분석
  strategy: { ... },          # 전략
  score: {
    total_score: 75,
    grade: "B+",
    dimension_scores: { ... },
    radar_chart_data: [ ... ]
  },
  required_expertise: [ ... ] # 필요 전문성 (전문가 매칭용)
}
```

---

## ⚠️ 주의사항

### 금지 패턴

| 패턴 | 문제 | 대안 |
|------|------|------|
| 세션만 사용 (OAuth 대비) | 외부 리다이렉션 시 손실 | 세션 + 쿠키 백업 |
| 동기 API 호출 | 타임아웃, 느린 응답 | 백그라운드 Job |
| 결과 수동 병합 | 필드 누락 위험 | 전용 빌더 메서드 |

### OAuth 세션 손실 대비

```ruby
# ❌ 세션만 사용 - OAuth 리다이렉션 후 손실 가능
session[:pending_idea] = idea

# ✅ 세션 + 쿠키 백업
session[:pending_idea] = idea
cookies.encrypted[:pending_idea_backup] = {
  value: idea,
  expires: 1.hour.from_now
}
```

### 에이전트 에러 핸들링 (3단계)

```ruby
# 1단계: 로깅 + 2단계: Sentry + 3단계: 폴백/재시도
def run_agent_safely(agent_class)
  agent_class.new(@context).call
rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
  # 네트워크 에러 - 재시도 가능
  Rails.logger.warn "[AI] Network error in #{agent_class}: #{e.message}"
  Sentry.capture_exception(e, level: :warning, tags: { agent: agent_class.name })
  raise RetryableError, "Network timeout - will retry"
rescue Gemini::RateLimitError => e
  # Rate Limit - 대기 후 재시도
  Rails.logger.warn "[AI] Rate limited: #{e.message}"
  Sentry.capture_message("Gemini rate limit hit", level: :warning)
  sleep(e.retry_after || 60)
  retry
rescue StandardError => e
  # 기타 에러 - 폴백 데이터 반환
  Rails.logger.error "[AI] #{agent_class} failed: #{e.class} - #{e.message}"
  Rails.logger.error e.backtrace.first(5).join("\n")
  Sentry.capture_exception(e, tags: { agent: agent_class.name })
  fallback_result(agent_class)
end
```

### BackgroundJob 재시도 전략

```ruby
class AiAnalysisJob < ApplicationJob
  queue_as :default

  # 재시도 전략: 지수 백오프 (5s, 25s, 125s)
  retry_on Faraday::TimeoutError,
           wait: :polynomially_longer,
           attempts: 3

  retry_on Faraday::ConnectionFailed,
           wait: 30.seconds,
           attempts: 5

  # Rate Limit - 더 긴 대기
  retry_on Gemini::RateLimitError,
           wait: 60.seconds,
           attempts: 3

  # 복구 불가능한 에러 - 재시도 안 함
  discard_on ActiveRecord::RecordNotFound
  discard_on ArgumentError

  def perform(idea_analysis_id)
    analysis = IdeaAnalysis.find(idea_analysis_id)
    analysis.update!(status: :processing)

    result = Ai::Orchestrators::AnalysisOrchestrator.new(
      idea: analysis.idea,
      follow_up_answers: analysis.follow_up_answers
    ).run

    analysis.update!(result: result.to_json, status: :completed)
  rescue StandardError => e
    # 모든 재시도 소진 후 최종 실패
    analysis&.update!(status: :failed, error_message: e.message)
    Sentry.capture_exception(e, tags: { analysis_id: idea_analysis_id })
    raise  # Job 실패로 기록
  end
end
```

### Gemini API 요청 제한 대응

**제한 현황** (2026년 기준):
| 제한 유형 | 무료 Tier | 유료 Tier | 대응 전략 |
|----------|----------|----------|----------|
| RPM (분당) | 15 | 60+ | 요청 큐잉, 지연 실행 |
| TPM (토큰/분) | 32,000 | 60,000+ | 프롬프트 최적화 |
| 일일 요청 | 1,500 | 무제한 | 사용량 모니터링 |

```ruby
# Rate Limit 대응 패턴
class GeminiRateLimiter
  MAX_REQUESTS_PER_MINUTE = 15

  def self.with_rate_limit(&block)
    acquire_slot  # Redis 기반 슬롯 관리
    yield
  ensure
    release_slot
  end

  def self.acquire_slot
    loop do
      current = Redis.current.get("gemini:rpm") || 0
      if current.to_i < MAX_REQUESTS_PER_MINUTE
        Redis.current.incr("gemini:rpm")
        Redis.current.expire("gemini:rpm", 60)
        break
      end
      sleep(1)  # 슬롯 대기
    end
  end
end

# 사용 예시
GeminiRateLimiter.with_rate_limit do
  client.generate_content(prompt)
end
```

### 프롬프트 최적화 (토큰 절약)

```ruby
# ❌ 비효율적 - 중복 컨텍스트
5.times do |i|
  client.generate_content("
    아이디어: #{idea}
    이전 결과: #{previous_results.to_json}
    지금 #{AGENTS[i]} 분석해줘
  ")
end

# ✅ 효율적 - 컨텍스트 재사용
session = client.start_chat
session.send_message("아이디어: #{idea}")  # 컨텍스트 설정
AGENTS.each do |agent|
  result = session.send_message("#{agent} 관점에서 분석해줘")  # 이전 대화 유지
end
```

### 부분 성공 처리

```ruby
# 일부 에이전트 실패 시에도 결과 저장
class AnalysisOrchestrator
  def run
    results = {}
    failed_agents = []

    AGENTS.each do |agent_class|
      begin
        results.merge!(run_agent_safely(agent_class))
      rescue RetryableError
        failed_agents << agent_class.name
      end
    end

    # 부분 성공 상태 기록
    {
      **results,
      partial_success: failed_agents.any?,
      failed_agents: failed_agents
    }
  end
end

# IdeaAnalysis 상태 업데이트
if result[:partial_success]
  analysis.update!(
    status: :partial,
    result: result.to_json,
    failed_agents: result[:failed_agents]
  )
end
```

---

## ✅ 체크리스트

### 에이전트 수정 시
- [ ] BaseAgent 상속 확인
- [ ] 컨텍스트 전달 확인
- [ ] 에러 핸들링 확인
- [ ] 테스트 커버리지 확인

### 결과 구조 수정 시
- [ ] 모든 필드 명시 (빌더 메서드)
- [ ] 뷰에서 nil 체크 추가
- [ ] 레이더 차트 데이터 형식 확인
- [ ] 전문가 매칭 데이터 확인

### 비로그인 플로우 수정 시
- [ ] 세션 + 쿠키 백업 사용
- [ ] OAuth 리다이렉션 테스트
- [ ] 캐시 만료 시간 확인

### Gemini API 수정 시
- [ ] API 키 credentials 확인
- [ ] Grounding 옵션 확인
- [ ] 타임아웃 설정 확인
- [ ] 에러 핸들링 확인

---

## 📊 아키텍처 다이어그램

```
┌────────────────────────────────────────────────────────────────┐
│                       OnboardingController                      │
│  ai_input → ai_analyze → ai_result                              │
└───────────────────────────┬────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────────┐
│                    AnalysisExecutor                             │
│  비로그인: 세션/쿠키 저장 → 로그인 유도                         │
│  로그인: AiAnalysisJob 실행                                     │
└───────────────────────────┬────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────────┐
│                    AnalysisOrchestrator                         │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  1. SummaryAgent        → 아이디어 요약                 │   │
│  │  2. TargetUserAgent     → 타겟 사용자 분석              │   │
│  │  3. MarketAnalysisAgent → 시장 분석 (Gemini Grounding)  │   │
│  │  4. StrategyAgent       → 전략 제안                     │   │
│  │  5. ScoringAgent        → 점수 산출                     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  Tools: GeminiGroundingTool, MarketDataTool, CompetitorDB       │
└───────────────────────────┬────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────────┐
│                      IdeaAnalysis                               │
│  - idea, follow_up_answers                                      │
│  - result (JSON), score, status                                 │
│  - is_real_analysis, partial_success                            │
└────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────────┐
│                      ExpertMatcher                              │
│  required_expertise → 전문가 매칭                               │
│                                                                 │
│                   ExpertScorePredictor                          │
│  분석 결과 기반 전문가 점수 예측                                │
└────────────────────────────────────────────────────────────────┘
```

---

## 🔑 환경 변수

```bash
# Gemini API
GEMINI_API_KEY=your_api_key

# Rails credentials에 저장 권장
rails credentials:edit
# gemini:
#   api_key: your_api_key
```

---

## 🔗 연계 스킬

| 스킬 | 사용 시점 |
|------|----------|
| `background-job` | 새 Job 추가 시 |
| `service-object` | 새 서비스 추출 시 |

---

## 📚 참조 문서

- [CLAUDE.md - AI 서비스 섹션](../../CLAUDE.md#ai-서비스-멀티에이전트-시스템)
- [ARCHITECTURE_DETAIL.md](../../ARCHITECTURE_DETAIL.md)
- [lib/langchain_config.rb](../../../lib/langchain_config.rb)
