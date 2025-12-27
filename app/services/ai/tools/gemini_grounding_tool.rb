# frozen_string_literal: true

module Ai
  module Tools
    # Gemini Grounding Tool
    # Gemini 2.0의 네이티브 Google Search 기능을 활용한 실시간 웹 검색 도구
    #
    # LangchainRB의 GoogleSearch(SerpApi 기반)와 달리,
    # Gemini API의 내장 grounding 기능을 직접 사용
    #
    # 사용법:
    #   tool = Ai::Tools::GeminiGroundingTool.new
    #   result = tool.search_market_data(query: "한국 이커머스 시장 규모 2024")
    #
    # 참고: https://ai.google.dev/gemini-api/docs/google-search
    #
    class GeminiGroundingTool
      extend Langchain::ToolDefinition
      include Langchain::ToolDefinition::InstanceMethods

      GEMINI_API_BASE = "https://generativelanguage.googleapis.com/v1beta"
      DEFAULT_MODEL = "gemini-2.0-flash"

      # 함수 정의: 시장 데이터 검색
      define_function :search_market_data, description: "실시간 웹 검색으로 시장 규모, 성장률, 트렌드 정보를 조회합니다" do
        property :query, type: "string", description: "검색 쿼리 (예: '한국 이커머스 시장 규모 2024')", required: true
      end

      # 함수 정의: 경쟁사 정보 검색
      define_function :search_competitors, description: "실시간 웹 검색으로 특정 분야의 주요 경쟁사와 시장 점유율을 조회합니다" do
        property :query, type: "string", description: "검색 쿼리 (예: '한국 배달앱 시장 점유율')", required: true
      end

      # 함수 정의: 최신 트렌드 검색
      define_function :search_trends, description: "실시간 웹 검색으로 산업 트렌드와 최신 동향을 조회합니다" do
        property :query, type: "string", description: "검색 쿼리 (예: '2024 핀테크 트렌드')", required: true
      end

      def initialize
        @api_key = Rails.application.credentials.dig(:gemini, :api_key) ||
                   Rails.application.credentials.dig(:google, :gemini_api_key) ||
                   ENV["GOOGLE_GEMINI_API_KEY"] ||
                   ENV["GEMINI_API_KEY"]

        raise "Gemini API key not configured. Run: EDITOR='code --wait' bin/rails credentials:edit" if @api_key.blank?
      end

      # 시장 데이터 검색
      def search_market_data(query:)
        enhanced_query = "#{query} 시장 규모 성장률 통계 2024"
        execute_grounded_search(enhanced_query, context: "시장 데이터")
      end

      # 경쟁사 정보 검색
      def search_competitors(query:)
        enhanced_query = "#{query} 주요 기업 시장 점유율 경쟁사"
        execute_grounded_search(enhanced_query, context: "경쟁사 정보")
      end

      # 최신 트렌드 검색
      def search_trends(query:)
        enhanced_query = "#{query} 트렌드 동향 전망 2024 2025"
        execute_grounded_search(enhanced_query, context: "트렌드")
      end

      private

      def execute_grounded_search(query, context: "검색 결과")
        Rails.logger.info("[GeminiGroundingTool] Searching: #{query}")

        response = call_gemini_with_grounding(query)

        if response[:success]
          content = format_grounded_response(response, context)
          tool_response(content: content)
        else
          Rails.logger.warn("[GeminiGroundingTool] Search failed: #{response[:error]}")
          tool_response(content: "검색 결과를 가져올 수 없습니다: #{response[:error]}")
        end
      rescue StandardError => e
        Rails.logger.error("[GeminiGroundingTool] Error: #{e.message}")
        tool_response(content: "웹 검색 중 오류가 발생했습니다.")
      end

      def call_gemini_with_grounding(query)
        uri = URI("#{GEMINI_API_BASE}/models/#{DEFAULT_MODEL}:generateContent?key=#{@api_key}")

        request_body = {
          contents: [
            {
              parts: [
                { text: build_search_prompt(query) }
              ]
            }
          ],
          tools: [
            { google_search: {} }
          ],
          generationConfig: {
            temperature: 0.3,
            maxOutputTokens: 1024
          }
        }

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = 30
        http.open_timeout = 10

        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/json"
        request.body = request_body.to_json

        response = http.request(request)

        if response.code == "200"
          parsed = JSON.parse(response.body, symbolize_names: true)
          extract_grounded_result(parsed)
        else
          { success: false, error: "API error: #{response.code} - #{response.body}" }
        end
      end

      def build_search_prompt(query)
        <<~PROMPT
          다음 주제에 대해 웹 검색을 통해 최신 정보를 찾아주세요:

          #{query}

          요청사항:
          - 가능한 최신 데이터 (2024년 이후) 우선
          - 구체적인 수치와 통계 포함
          - 신뢰할 수 있는 출처 (정부 기관, 리서치 기관, 언론사) 우선
          - 한국 시장 기준으로 답변
          - 간결하고 핵심적인 정보만 제공

          답변 형식:
          - 주요 정보를 bullet point로 정리
          - 출처가 있다면 명시
        PROMPT
      end

      def extract_grounded_result(parsed_response)
        candidates = parsed_response.dig(:candidates)
        return { success: false, error: "No candidates in response" } if candidates.blank?

        first_candidate = candidates.first
        content = first_candidate.dig(:content, :parts, 0, :text)
        grounding_metadata = first_candidate[:groundingMetadata]

        if content.present?
          {
            success: true,
            content: content,
            grounding_metadata: grounding_metadata,
            search_queries: grounding_metadata&.dig(:webSearchQueries),
            sources: extract_sources(grounding_metadata)
          }
        else
          { success: false, error: "Empty content in response" }
        end
      end

      def extract_sources(grounding_metadata)
        return [] if grounding_metadata.blank?

        chunks = grounding_metadata[:groundingChunks] || []
        chunks.filter_map do |chunk|
          web = chunk[:web]
          next unless web

          {
            title: web[:title],
            uri: web[:uri]
          }
        end
      end

      def format_grounded_response(response, context)
        result = "[#{context} - 실시간 검색 결과]\n\n"
        result += response[:content]

        if response[:sources].present?
          result += "\n\n[출처]\n"
          response[:sources].first(3).each do |source|
            result += "- #{source[:title]}\n"
          end
        end

        if response[:search_queries].present?
          result += "\n[검색 쿼리: #{response[:search_queries].first}]"
        end

        result
      end
    end
  end
end
