# 관리자 AI 분석 사용량 관리 컨트롤러
# 사용량 통계, 사용자별 limit 수정, 분석 기록 삭제
class Admin::AiUsagesController < Admin::BaseController
  before_action :set_user, only: [ :show, :update_limit, :update_bonus, :set_remaining, :reset, :destroy_analysis, :destroy_selected ]

  # GET /admin/ai_usages
  # 전체 AI 분석 통계 + 사용자 검색
  def index
    # 날짜 범위 필터 적용된 기본 스코프 생성
    @base_scope = build_date_filtered_scope
    @current_view = params[:view] == "history" ? "history" : "users"

    # 통계 계산 (필터 적용)
    calculate_statistics(@base_scope)

    # 날짜 범위 필터 적용된 분석 집합 (기존 코드 호환)
    analyses_scope = @base_scope

    # 뷰에 따라 다른 데이터 로드
    if @current_view == "history"
      load_history_data(analyses_scope)
    else
      load_users_data(analyses_scope)
    end
  end

  # GET /admin/ai_usages/:id
  # 사용자별 AI 사용량 상세
  def show
    @analyses = @user.idea_analyses.order(created_at: :desc)
    @stats = @user.ai_usage_stats
  end

  # GET /admin/ai_usages/export.csv
  # AI 분석 데이터를 CSV로 내보내기
  def export
    @analyses = IdeaAnalysis.includes(:user).order(created_at: :desc)

    # 날짜 범위 필터링 (안전한 파싱)
    from_date = parse_date_safely(params[:from_date])
    to_date = parse_date_safely(params[:to_date])

    @analyses = @analyses.where("idea_analyses.created_at >= ?", from_date.beginning_of_day) if from_date
    @analyses = @analyses.where("idea_analyses.created_at <= ?", to_date.end_of_day) if to_date

    # 검색 필터
    if params[:q].present?
      keyword = "%#{params[:q]}%"
      @analyses = @analyses.joins(:user).where("users.email LIKE ? OR users.name LIKE ?", keyword, keyword)
    end

    columns = {
      id: "ID",
      user_name: ->(analysis) { analysis.user&.name || "(삭제됨)" },
      user_email: ->(analysis) { analysis.user&.email || "-" },
      idea_title: ->(analysis) { analysis.idea_title.to_s.truncate(50) },
      status: ->(analysis) { status_label(analysis.status) },
      is_real: ->(analysis) { analysis.is_real_analysis ? "실제" : "Mock" },
      created_at: "분석일"
    }

    service = Admin::CsvExportService.new(@analyses, columns: columns, filename_prefix: "ai_analyses")
    send_data service.generate, filename: service.filename, type: "text/csv; charset=utf-8"
  end

  # PATCH /admin/ai_usages/:id/update_limit
  # 사용자 limit 수정
  def update_limit
    new_limit = params[:limit].to_i

    if new_limit <= 0
      # 0 이하면 기본값 사용 (NULL)
      # update_column: 유효성 검증 우회 (다른 필드 검증 실패 방지)
      @user.update_column(:ai_analysis_limit, nil)
      flash[:notice] = "#{@user.name}의 limit이 기본값(#{User::DEFAULT_AI_ANALYSIS_LIMIT}회)으로 설정되었습니다."
    else
      @user.update_column(:ai_analysis_limit, new_limit)
      flash[:notice] = "#{@user.name}의 limit이 #{new_limit}회로 설정되었습니다."
    end

    redirect_to admin_ai_usage_path(@user)
  end

  # PATCH /admin/ai_usages/:id/update_bonus
  # 보너스 크레딧 직접 설정
  def update_bonus
    bonus = params[:bonus].to_i
    # update_column: 유효성 검증 우회 (다른 필드 검증 실패 방지)
    @user.update_column(:ai_bonus_credits, [ bonus, 0 ].max)

    flash[:notice] = "#{@user.name}의 보너스 크레딧이 #{bonus}개로 설정되었습니다."
    redirect_to admin_ai_usage_path(@user)
  end

  # PATCH /admin/ai_usages/:id/set_remaining
  # 잔여횟수를 직접 설정 (보너스 자동 계산)
  def set_remaining
    desired_remaining = params[:remaining].to_i
    bonus = @user.calculate_bonus_for_remaining(desired_remaining)
    # update_column: 유효성 검증 우회 (다른 필드 검증 실패 방지)
    @user.update_column(:ai_bonus_credits, [ bonus, 0 ].max)

    flash[:notice] = "#{@user.name}의 잔여횟수가 #{@user.ai_analyses_remaining}회로 설정되었습니다."
    redirect_to admin_ai_usage_path(@user)
  end

  # DELETE /admin/ai_usages/:id/reset
  # 전체 분석 기록 삭제
  def reset
    count = @user.idea_analyses.count
    @user.idea_analyses.destroy_all

    flash[:notice] = "#{@user.name}의 AI 분석 기록 #{count}개가 삭제되었습니다."
    redirect_to admin_ai_usage_path(@user)
  end

  # DELETE /admin/ai_usages/:user_id/analyses/:id
  # 개별 분석 삭제
  def destroy_analysis
    analysis = @user.idea_analyses.find(params[:analysis_id])
    analysis.destroy

    flash[:notice] = "분석 기록이 삭제되었습니다."
    redirect_to admin_ai_usage_path(@user)
  end

  # DELETE /admin/ai_usages/:id/destroy_selected
  # 선택된 분석들 삭제
  def destroy_selected
    analysis_ids = params[:analysis_ids] || []

    if analysis_ids.empty?
      flash[:alert] = "삭제할 분석을 선택해주세요."
    else
      count = @user.idea_analyses.where(id: analysis_ids).destroy_all.count
      flash[:notice] = "#{count}개의 분석 기록이 삭제되었습니다."
    end

    redirect_to admin_ai_usage_path(@user)
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  # 사용 이력 데이터 로드
  def load_history_data(analyses_scope)
    @analyses = analyses_scope.includes(:user).order(created_at: :desc)

    # 사용자 검색 필터
    if params[:q].present?
      keyword = "%#{params[:q]}%"
      @analyses = @analyses.joins(:user).where(
        "users.email LIKE :q OR users.name LIKE :q", q: keyword
      )
    end

    # 페이지네이션 (30개/페이지)
    @page = (params[:page] || 1).to_i
    @per_page = 30
    @total_count = @analyses.count
    @total_pages = (@total_count.to_f / @per_page).ceil
    @analyses = @analyses.offset((@page - 1) * @per_page).limit(@per_page)
  end

  # 사용자 목록 데이터 로드 (기존 Top Users 로직)
  def load_users_data(analyses_scope)
    if params[:q].present?
      keyword = "%#{params[:q]}%"
      @users = User.where("email LIKE ? OR name LIKE ?", keyword, keyword)
                   .includes(:idea_analyses)
                   .order(created_at: :desc)
                   .limit(50)
    else
      # Top 사용자 (분석 많이 한 순) - 날짜 필터 적용
      @users = User.joins(:idea_analyses)
                   .merge(analyses_scope)
                   .group("users.id")
                   .select("users.*, COUNT(idea_analyses.id) as analyses_count")
                   .order(Arel.sql("COUNT(idea_analyses.id) DESC"))
                   .limit(20)
    end
  end

  # 상태 레이블
  def status_label(status)
    {
      "pending" => "대기",
      "analyzing" => "분석 중",
      "completed" => "완료",
      "failed" => "실패"
    }[status] || status
  end

  # 날짜 범위 필터 적용된 스코프 생성
  def build_date_filtered_scope
    scope = IdeaAnalysis.all
    from_date = parse_date_safely(params[:from_date])
    to_date = parse_date_safely(params[:to_date])

    scope = scope.where("idea_analyses.created_at >= ?", from_date.beginning_of_day) if from_date
    scope = scope.where("idea_analyses.created_at <= ?", to_date.end_of_day) if to_date
    scope
  end

  # 안전한 날짜 파싱 (잘못된 형식 시 nil 반환)
  def parse_date_safely(date_string)
    return nil if date_string.blank?
    Date.parse(date_string)
  rescue ArgumentError
    flash.now[:alert] = "잘못된 날짜 형식입니다: #{date_string}"
    nil
  end

  def calculate_statistics(scope = IdeaAnalysis.all)
    # 필터가 적용되었는지 여부
    @has_date_filter = params[:from_date].present? || params[:to_date].present?

    # 전체 통계 (필터 적용)
    @total_analyses = scope.count
    @today_analyses = scope.where("created_at >= ?", Time.current.beginning_of_day).count
    @this_week_analyses = scope.where("created_at >= ?", 1.week.ago).count

    # 실제 vs Mock 분석 (필터 적용)
    @real_analyses = scope.where(is_real_analysis: true).count
    @mock_analyses = scope.where(is_real_analysis: false).count

    # 상태별 통계 (필터 적용)
    @completed_count = scope.where(status: "completed").count
    @analyzing_count = scope.where(status: "analyzing").count
    @failed_count = scope.where(status: "failed").count

    # 평균 사용량 (필터 적용)
    # Note: scope already has idea_analyses table aliased, so we use subquery
    users_with_analyses = User.where(id: scope.select(:user_id).distinct).count
    @avg_analyses = users_with_analyses > 0 ? (@total_analyses.to_f / users_with_analyses).round(1) : 0

    # 영구 보존 사용 기록 통계 (AiUsageLog)
    calculate_permanent_stats
  end

  # 영구 보존 통계 (AiUsageLog 기반, 삭제된 분석 포함)
  def calculate_permanent_stats
    @permanent_stats = AiUsageLog.usage_stats
    @deleted_analyses_count = AiUsageLog.where(idea_analysis_id: nil).count
    @saved_by_user_count = AiUsageLog.saved_by_user.count
  end
end
