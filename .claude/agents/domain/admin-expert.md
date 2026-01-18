---
name: admin-expert
description: 관리자 기능 전문가 - 대시보드, 사용자 관리, 콘텐츠 관리, 열람 로그
triggers:
  - 관리자
  - admin
  - 대시보드
  - dashboard
  - 회원 관리
  - 탈퇴 회원
related_skills:
  - code-review
---

# Admin Expert (관리자 전문가)

## 🎯 역할

관리자 기능의 모든 측면을 담당합니다:
- 관리자 대시보드
- 사용자 관리 (활성/탈퇴 회원)
- 콘텐츠 관리 (게시글, 댓글)
- 탈퇴 회원 정보 열람 및 로깅
- 통계 및 분석

---

## 📁 담당 파일

### Controllers
```
app/controllers/admin/dashboard_controller.rb     # 대시보드
app/controllers/admin/users_controller.rb         # 사용자 관리
app/controllers/admin/posts_controller.rb         # 게시글 관리
app/controllers/admin/user_deletions_controller.rb # 탈퇴 회원 관리
```

### Models
```
app/models/admin_view_log.rb                      # 열람 로그
app/models/user_deletion.rb                       # 탈퇴 정보
```

### Views
```
app/views/admin/
├── dashboard/
│   └── index.html.erb        # 대시보드 메인
├── users/
│   ├── index.html.erb        # 사용자 목록
│   └── show.html.erb         # 사용자 상세
├── posts/
│   └── index.html.erb        # 게시글 목록
└── user_deletions/
    ├── index.html.erb        # 탈퇴 회원 목록
    └── show.html.erb         # 탈퇴 정보 (복호화)
```

### JavaScript (Stimulus)
```
app/javascript/controllers/admin/
├── bulk_select_controller.js    # 일괄 선택
├── dropdown_controller.js       # 드롭다운 메뉴
└── slide_panel_controller.js    # 슬라이드 패널
```

### Tests
```
test/controllers/admin/*_test.rb
```

---

## 🔧 핵심 패턴

### 1. 관리자 권한 체크

```ruby
# AdminController (Base)
class Admin::BaseController < ApplicationController
  before_action :require_admin

  private

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "접근 권한이 없습니다"
    end
  end
end
```

### 2. 탈퇴 회원 정보 복호화

```ruby
# UserDeletionsController#show
def show
  @deletion = UserDeletion.find(params[:id])

  # 열람 사유 필수
  unless params[:view_reason].present?
    redirect_to admin_user_deletions_path, alert: "열람 사유를 입력해주세요"
    return
  end

  # 복호화 (AES-256)
  @original_data = @deletion.decrypt_original_data

  # 열람 로그 기록
  AdminViewLog.create!(
    admin: current_user,
    user_deletion: @deletion,
    reason: params[:view_reason],
    ip_address: request.remote_ip
  )
end
```

### 3. 열람 로그 기록

```ruby
# AdminViewLog 모델
class AdminViewLog < ApplicationRecord
  belongs_to :admin, class_name: "User"
  belongs_to :user_deletion

  validates :reason, presence: true
  validates :ip_address, presence: true
end
```

### 4. 일괄 작업

```javascript
// bulk_select_controller.js
selectAll() {
  this.checkboxTargets.forEach(checkbox => {
    checkbox.checked = this.selectAllTarget.checked
  })
  this.updateCount()
}

bulkAction(action) {
  const ids = this.selectedIds()
  if (ids.length === 0) {
    alert("항목을 선택해주세요")
    return
  }

  fetch(`/admin/${action}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken
    },
    body: JSON.stringify({ ids })
  })
}
```

### 5. 열람 로그 시스템 (AdminViewLog) 상세

**목적**: 민감한 개인정보 열람에 대한 감사 추적 (Audit Trail)

```ruby
# app/models/admin_view_log.rb
class AdminViewLog < ApplicationRecord
  belongs_to :admin, class_name: "User"
  belongs_to :user_deletion

  validates :reason, presence: true, length: { minimum: 10 }
  validates :ip_address, presence: true
  validates :viewed_at, presence: true

  before_validation :set_viewed_at

  # 열람 목적 카테고리
  REASON_CATEGORIES = [
    "법적 분쟁 대응",
    "회원 본인 요청",
    "수사기관 요청",
    "내부 감사",
    "시스템 오류 확인"
  ].freeze

  scope :recent, -> { order(viewed_at: :desc) }
  scope :by_admin, ->(admin_id) { where(admin_id: admin_id) }
  scope :by_deletion, ->(deletion_id) { where(user_deletion_id: deletion_id) }

  private

  def set_viewed_at
    self.viewed_at ||= Time.current
  end
end

# 마이그레이션 참조
# create_table :admin_view_logs do |t|
#   t.references :admin, foreign_key: { to_table: :users }
#   t.references :user_deletion, foreign_key: true
#   t.string :reason, null: false
#   t.string :ip_address, null: false
#   t.datetime :viewed_at, null: false
#   t.jsonb :viewed_fields, default: []  # 열람한 필드 기록
#   t.timestamps
# end
```

### 6. UserDeletion 복호화 절차 (Rails Console)

**⚠️ 주의**: 복호화는 법적 요청 또는 정당한 사유가 있을 때만 수행

```bash
# 1. Rails Console 접속 (프로덕션)
$ RAILS_ENV=production rails console

# 2. 탈퇴 회원 조회
> deletion = UserDeletion.find(123)
> deletion.deleted_at
=> 2025-06-15 10:30:00 UTC

# 3. 복호화된 원본 정보 확인 (자동 복호화)
# Rails Active Record Encryption이 자동으로 복호화
> deletion.original_email
=> "user@example.com"

> deletion.original_nickname
=> "홍길동"

> deletion.original_phone
=> "010-1234-5678"

# 4. 열람 로그 생성 (필수!)
> AdminViewLog.create!(
    admin: User.find_by(email: "admin@example.com"),
    user_deletion: deletion,
    reason: "회원 본인의 정보 확인 요청 (고객센터 티켓 #12345)",
    ip_address: "192.168.1.100"
  )

# 5. 열람 이력 확인
> deletion.admin_view_logs.order(created_at: :desc).limit(5)
```

**프로그래밍적 접근 (컨트롤러)**:
```ruby
# app/controllers/admin/user_deletions_controller.rb
def show
  @deletion = UserDeletion.find(params[:id])

  # 열람 사유 필수 검증
  unless params[:view_reason].present? && params[:view_reason].length >= 10
    redirect_to admin_user_deletions_path,
                alert: "열람 사유를 10자 이상 입력해주세요"
    return
  end

  # 열람 로그 자동 생성
  AdminViewLog.create!(
    admin: current_user,
    user_deletion: @deletion,
    reason: params[:view_reason],
    ip_address: request.remote_ip,
    viewed_fields: %w[original_email original_nickname original_phone]
  )

  # 복호화된 데이터는 뷰에서 자동으로 접근 가능
  # @deletion.original_email 등
end
```

### 7. 5년 보관 정책 법적 근거

| 법률 | 보관 항목 | 보관 기간 | 근거 조항 |
|------|----------|----------|----------|
| 전자상거래법 | 계약/청약철회 기록 | 5년 | 제6조 |
| 전자상거래법 | 대금결제/재화공급 기록 | 5년 | 제6조 |
| 통신비밀보호법 | 통신사실확인자료 | 3개월~12개월 | 제15조의2 |
| 개인정보보호법 | 개인정보 처리 기록 | 3년 | 제21조 |
| 국세기본법 | 거래 관련 증빙 | 5년 | 제26조의2 |

**자동 파기 스케줄링**:
```ruby
# app/jobs/destroy_expired_deletions_job.rb
class DestroyExpiredDeletionsJob < ApplicationJob
  queue_as :low_priority

  def perform
    expired_deletions = UserDeletion.where("deleted_at < ?", 5.years.ago)

    expired_deletions.find_each do |deletion|
      Rails.logger.info "[Deletion] Destroying expired record: #{deletion.id}"

      # 관련 로그도 함께 삭제 (법적 보관 기간 경과)
      deletion.admin_view_logs.destroy_all
      deletion.destroy!
    end

    Rails.logger.info "[Deletion] Destroyed #{expired_deletions.count} expired records"
  end
end

# config/schedule.rb (whenever gem)
every 1.day, at: '3:00 am' do
  runner "DestroyExpiredDeletionsJob.perform_later"
end
```

---

## ⚠️ 주의사항

### 필수 보안 조치

| 항목 | 설명 |
|------|------|
| 권한 체크 | 모든 액션에서 `require_admin` |
| 열람 로그 | 민감 정보 조회 시 필수 기록 |
| IP 기록 | 접근 추적을 위해 필수 |
| 복호화 제한 | 열람 사유 필수 입력 |

### 탈퇴 회원 정보 5년 보관

```ruby
# 자동 파기 Job
class DestroyExpiredDeletionsJob < ApplicationJob
  def perform
    UserDeletion
      .where("created_at < ?", 5.years.ago)
      .find_each(&:destroy!)
  end
end
```

---

## ✅ 체크리스트

### 관리자 기능 수정 시
- [ ] 권한 체크 (`require_admin`) 확인
- [ ] 민감 정보 열람 로그 기록
- [ ] IP 주소 기록 확인
- [ ] 복호화 키 관리 확인

### 통계 기능 수정 시
- [ ] N+1 쿼리 방지
- [ ] 캐싱 적용 여부 확인
- [ ] 시간대 처리 (UTC vs KST)

---

## 📚 참조 문서

- [SECURITY_GUIDE.md](../../SECURITY_GUIDE.md) - 복호화 절차
- [CLAUDE.md - 회원 탈퇴 시스템](../../CLAUDE.md#회원-탈퇴-시스템)
