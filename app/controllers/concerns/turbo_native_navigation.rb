# frozen_string_literal: true

# Turbo Native 앱을 위한 네비게이션 헬퍼
#
# Hotwire Native 앱에서 폼 제출 후 적절한 네비게이션 동작을 제공합니다.
# - recede_or_redirect_to: 이전 화면으로 돌아가기 (폼 제출 성공 후)
# - refresh_or_redirect_to: 현재 화면 새로고침 (데이터 업데이트 후)
# - resume_or_redirect_to: 동일 URL 유지하며 페이지 새로고침
#
# 사용법:
#   class PostsController < ApplicationController
#     include TurboNativeNavigation
#
#     def create
#       @post = current_user.posts.create!(post_params)
#       recede_or_redirect_to @post, notice: "게시글이 등록되었습니다."
#     end
#
#     def update
#       @post.update!(post_params)
#       refresh_or_redirect_to @post
#     end
#   end
#
# 참고:
# - https://native.hotwired.dev/overview/navigation
# - turbo_action: "advance" -> push 네비게이션 (기본)
# - turbo_action: "replace" -> 현재 화면 교체
#
module TurboNativeNavigation
  extend ActiveSupport::Concern

  included do
    # UserAgentHelper의 hotwire_native_app? 헬퍼 사용
    helper_method :hotwire_native_app? if respond_to?(:helper_method)
  end

  private

  # 폼 제출 성공 후: 이전 화면으로 돌아가기 + 새로고침
  #
  # 네이티브 앱: 이전 화면으로 돌아가면서 리프레시
  # 웹 브라우저: 일반 redirect
  #
  # @param url_or_options [String, Hash] 리다이렉트 대상
  # @param options [Hash] 추가 옵션 (notice, alert 등)
  def recede_or_redirect_to(url_or_options, **options)
    if hotwire_native_app?
      # Turbo Native: advance로 새 페이지 푸시 (네이티브에서 recede 처리)
      redirect_to url_or_options, allow_other_host: false, **options
    else
      redirect_to url_or_options, **options
    end
  end

  # 데이터 업데이트 후: 현재 화면 새로고침
  #
  # 네이티브 앱: 현재 화면을 새로운 컨텐츠로 교체
  # 웹 브라우저: 일반 redirect
  #
  # @param url_or_options [String, Hash] 리다이렉트 대상
  # @param options [Hash] 추가 옵션
  def refresh_or_redirect_to(url_or_options, **options)
    if hotwire_native_app?
      # Turbo Native: replace로 현재 화면 교체
      redirect_to url_or_options, turbo_action: "replace", allow_other_host: false, **options
    else
      redirect_to url_or_options, **options
    end
  end

  # 동일 URL 유지하며 페이지 새로고침
  #
  # 네이티브 앱: 현재 URL 다시 로드
  # 웹 브라우저: 일반 redirect
  #
  # @param url_or_options [String, Hash] 리다이렉트 대상
  # @param options [Hash] 추가 옵션
  def resume_or_redirect_to(url_or_options, **options)
    if hotwire_native_app?
      # Turbo Native: advance로 새 페이지 (네이티브에서 resume 처리)
      redirect_to url_or_options, allow_other_host: false, **options
    else
      redirect_to url_or_options, **options
    end
  end
end
