# frozen_string_literal: true

# 사용자 로그인/로그아웃 기록을 저장하는 테이블
# 관리자가 사용자의 접속 기록을 추적하고 관리할 수 있음
class CreateUserSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :user_sessions do |t|
      t.references :user, null: false, foreign_key: true

      # 세션 식별
      t.string :session_token, null: false  # 고유 세션 식별자 (UUID)

      # 로그인 정보
      t.string :login_method, null: false   # email, google, github
      t.datetime :logged_in_at, null: false
      t.datetime :logged_out_at             # NULL = 활성 세션
      t.string :logout_reason               # user_initiated, session_expired, forced, admin_action

      # 클라이언트 정보
      t.string :ip_address
      t.string :user_agent
      t.string :device_type                 # mobile, tablet, desktop

      # 세션 상태
      t.boolean :remember_me, default: false
      t.datetime :last_activity_at

      t.timestamps
    end

    add_index :user_sessions, :session_token, unique: true
    add_index :user_sessions, [ :user_id, :logged_in_at ]
    add_index :user_sessions, :logged_in_at
    add_index :user_sessions, :logged_out_at  # 활성 세션 조회 최적화
  end
end
