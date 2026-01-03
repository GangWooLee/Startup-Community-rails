# 관리자 AI 분석 사용량 관리 컨트롤러
# 사용량 통계, 사용자별 limit 수정, 분석 기록 삭제
class Admin::AiUsagesController < Admin::BaseController
  before_action :set_user, only: [:show, :update_limit, :update_bonus, :set_remaining, :reset, :destroy_analysis, :destroy_selected]

  # GET /admin/ai_usages
  # 전체 AI 분석 통계 + 사용자 검색
  def index
    # 통계 계산
    calculate_statistics

    # 사용자 검색
    if params[:q].present?
      keyword = "%#{params[:q]}%"
      @users = User.where("email LIKE ? OR name LIKE ?", keyword, keyword)
                   .includes(:idea_analyses)
                   .order(created_at: :desc)
                   .limit(50)
    else
      # Top 사용자 (분석 많이 한 순)
      @users = User.joins(:idea_analyses)
                   .group("users.id")
                   .select("users.*, COUNT(idea_analyses.id) as analyses_count")
                   .order(Arel.sql("COUNT(idea_analyses.id) DESC"))
                   .limit(20)
    end
  end

  # GET /admin/ai_usages/:id
  # 사용자별 AI 사용량 상세
  def show
    @analyses = @user.idea_analyses.order(created_at: :desc)
    @stats = @user.ai_usage_stats
  end

  # PATCH /admin/ai_usages/:id/update_limit
  # 사용자 limit 수정
  def update_limit
    new_limit = params[:limit].to_i

    if new_limit <= 0
      # 0 이하면 기본값 사용 (NULL)
      @user.update!(ai_analysis_limit: nil)
      flash[:notice] = "#{@user.name}의 limit이 기본값(#{User::DEFAULT_AI_ANALYSIS_LIMIT}회)으로 설정되었습니다."
    else
      @user.update!(ai_analysis_limit: new_limit)
      flash[:notice] = "#{@user.name}의 limit이 #{new_limit}회로 설정되었습니다."
    end

    redirect_to admin_ai_usage_path(@user)
  end

  # PATCH /admin/ai_usages/:id/update_bonus
  # 보너스 크레딧 직접 설정
  def update_bonus
    bonus = params[:bonus].to_i
    @user.update!(ai_bonus_credits: [bonus, 0].max)

    flash[:notice] = "#{@user.name}의 보너스 크레딧이 #{bonus}개로 설정되었습니다."
    redirect_to admin_ai_usage_path(@user)
  end

  # PATCH /admin/ai_usages/:id/set_remaining
  # 잔여횟수를 직접 설정 (보너스 자동 계산)
  def set_remaining
    desired_remaining = params[:remaining].to_i
    bonus = @user.calculate_bonus_for_remaining(desired_remaining)
    @user.update!(ai_bonus_credits: [bonus, 0].max)

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

  def calculate_statistics
    # 전체 통계
    @total_analyses = IdeaAnalysis.count
    @today_analyses = IdeaAnalysis.where("created_at >= ?", Time.current.beginning_of_day).count
    @this_week_analyses = IdeaAnalysis.where("created_at >= ?", 1.week.ago).count

    # 실제 vs Mock 분석
    @real_analyses = IdeaAnalysis.where(is_real_analysis: true).count
    @mock_analyses = IdeaAnalysis.where(is_real_analysis: false).count

    # 상태별 통계
    @completed_count = IdeaAnalysis.where(status: "completed").count
    @analyzing_count = IdeaAnalysis.where(status: "analyzing").count
    @failed_count = IdeaAnalysis.where(status: "failed").count

    # 평균 사용량
    users_with_analyses = User.joins(:idea_analyses).distinct.count
    @avg_analyses = users_with_analyses > 0 ? (@total_analyses.to_f / users_with_analyses).round(1) : 0
  end
end
