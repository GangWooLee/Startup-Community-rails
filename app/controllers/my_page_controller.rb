class MyPageController < ApplicationController
  before_action :require_login
  before_action :hide_floating_button

  def show
    @user = current_user
    @is_own_profile = true  # 마이페이지는 항상 본인
    @viewer = current_user  # 프라이버시 블러 처리용 (본인은 항상 전체 공개)

    # 커뮤니티 글 (free, question, promotion)
    @posts = @user.posts.published
                  .includes(images_attachments: :blob)
                  .where(category: [ :free, :question, :promotion ])
                  .recent.limit(PROFILE_POSTS_LIMIT)

    # 외주 글 (hiring, seeking)
    @outsourcing_posts = @user.posts.published
                              .includes(images_attachments: :blob)
                              .where(category: [ :hiring, :seeking ])
                              .recent.limit(PROFILE_POSTS_LIMIT)
  end

  def edit
    @user = current_user
  end

  def idea_analyses
    @user = current_user
    # AiUsageLog 기반으로 변경 - 삭제된 분석도 기록 표시
    @usage_logs = @user.ai_usage_logs
                       .includes(:idea_analysis)
                       .order(created_at: :desc)
  end

  def update
    @user = current_user

    if @user.update(profile_params)
      redirect_to my_page_path, notice: "프로필이 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    permitted = params.require(:user).permit(
      :name, :role_title, :bio, :avatar, :cover_image,
      :affiliation, :skills, :custom_status,
      :status_message, :looking_for, :location,  # Persona Canvas
      :toolbox, :currently_learning,             # Phase 9: 도구 & 성장
      :linkedin_url, :github_url, :portfolio_url, :open_chat_url,
      :detailed_bio,                             # ActionText rich text
      :is_anonymous, :nickname, :avatar_type,    # 익명 설정
      :privacy_about, :privacy_posts, :privacy_activity, :privacy_experience,  # 섹션별 공개 설정
      availability_statuses: []
    )

    # Experience Timeline (JSON 배열) 특별 처리
    if params[:user][:experiences].present?
      experiences = params[:user][:experiences].map do |exp|
        {
          type: exp[:type],
          title: exp[:title],
          organization: exp[:organization],
          period: exp[:period],
          description: exp[:description],
          is_current: exp[:is_current] == "true",
          sort_order: exp[:sort_order].to_i
        }.compact_blank
      end.reject { |exp| exp[:title].blank? } # 제목 없는 항목 제거

      permitted[:experiences] = experiences
    end

    permitted
  end
end
