# frozen_string_literal: true

require "test_helper"

class Payments::EligibilityValidatorTest < ActiveSupport::TestCase
  fixtures :users, :posts

  setup do
    @user = users(:one)
    @other_user = users(:two)
    @post = posts(:one)
  end

  # ===== No Context Tests =====

  test "no post or offer returns failure" do
    result = Payments::EligibilityValidator.new(user: @user).call

    assert result.failure?
    assert_includes result.errors, "결제 대상을 찾을 수 없습니다."
    assert_equal :root_path, result.redirect_path.first
  end

  # ===== Post Payment Tests =====

  test "non-outsourcing post returns failure" do
    # Post가 outsourcing이 아닌 경우 테스트
    @post.define_singleton_method(:outsourcing?) { false }

    result = Payments::EligibilityValidator.new(user: @user, post: @post).call

    assert result.failure?
    assert_includes result.errors, "외주 글만 결제할 수 있습니다."
    assert_equal :post_path, result.redirect_path.first
  end

  test "non-payable post returns failure" do
    @post.define_singleton_method(:outsourcing?) { true }
    @post.define_singleton_method(:payable?) { false }

    result = Payments::EligibilityValidator.new(user: @user, post: @post).call

    assert result.failure?
    assert_includes result.errors, "가격이 설정되지 않은 글입니다."
  end

  test "own post returns failure" do
    @post.define_singleton_method(:outsourcing?) { true }
    @post.define_singleton_method(:payable?) { true }
    @post.define_singleton_method(:owned_by?) { |_user| true }

    result = Payments::EligibilityValidator.new(user: @user, post: @post).call

    assert result.failure?
    assert_includes result.errors, "본인의 글은 결제할 수 없습니다."
  end

  test "already paid post returns failure" do
    @post.define_singleton_method(:outsourcing?) { true }
    @post.define_singleton_method(:payable?) { true }
    @post.define_singleton_method(:owned_by?) { |_user| false }
    @post.define_singleton_method(:paid_by?) { |_user| true }

    result = Payments::EligibilityValidator.new(user: @user, post: @post).call

    assert result.failure?
    assert_includes result.errors, "이미 결제한 글입니다."
  end

  test "valid post payment returns success" do
    @post.define_singleton_method(:outsourcing?) { true }
    @post.define_singleton_method(:payable?) { true }
    @post.define_singleton_method(:owned_by?) { |_user| false }
    @post.define_singleton_method(:paid_by?) { |_user| false }

    result = Payments::EligibilityValidator.new(user: @user, post: @post).call

    assert result.success?
    assert_empty result.errors
    assert_nil result.redirect_path
  end
end
