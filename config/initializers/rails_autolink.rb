# frozen_string_literal: true

# rails_autolink 헬퍼를 모든 컨텍스트에서 사용 가능하게 함
#
# 문제: rails_autolink gem의 auto_link 메서드가 Railtie를 통해 조건부로 로드됨
#       Model에서 broadcast_* 호출 시 ActionView 컨텍스트가 완전히 로드되지 않아
#       auto_link 메서드를 찾을 수 없음
#
# 해결: 앱 시작 시 명시적으로 헬퍼를 로드하여 어디서든 사용 가능하게 함
#
# 참고: 이 문제는 linkify_urls 헬퍼가 auto_link를 사용하기 때문에 발생
#       - app/helpers/application_helper.rb:312
#       - app/models/message.rb:111 (broadcast_message에서 호출)
#
require "rails_autolink/helpers"
