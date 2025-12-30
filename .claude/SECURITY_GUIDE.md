# 보안 및 암호화 가이드

> **이 문서는 암호화된 회원 데이터의 복호화 방법과 보안 정책을 설명합니다.**

## 문서 정보
| 항목 | 값 |
|------|-----|
| **작성일** | 2025-12-30 |
| **대상 시스템** | 회원 탈퇴 시스템 (UserDeletion) |
| **암호화 기술** | Rails 7 Active Record Encryption |
| **법적 근거** | 전자상거래법 (5년 보관) |

---

## 1. 개요

### 1.1 암호화 대상
회원 탈퇴 시 다음 개인정보가 암호화되어 `user_deletions` 테이블에 저장됩니다:

| 컬럼 | 설명 | 암호화 방식 |
|------|------|------------|
| `email_original` | 원본 이메일 | 비결정적 (랜덤) |
| `name_original` | 원본 이름 | 비결정적 (랜덤) |
| `phone_original` | 원본 전화번호 | 비결정적 (랜덤) |
| `snapshot_data` | 프로필 스냅샷 (JSON) | 비결정적 (랜덤) |
| `email_hash` | 이메일 해시 (검색용) | **결정적** (동일 입력 → 동일 출력) |

### 1.2 이중 보호 구조
```
사용자 탈퇴 요청
       ↓
┌─────────────────────────────────────┐
│  1. users 테이블                      │
│     - 즉시 익명화 (deleted_xxx@...)   │
│     - 활동 데이터는 유지 (게시글, 댓글) │
└─────────────────────────────────────┘
       ↓
┌─────────────────────────────────────┐
│  2. user_deletions 테이블             │
│     - 원본 정보 암호화 저장           │
│     - 5년 후 자동 파기                │
└─────────────────────────────────────┘
```

---

## 2. 암호화 키 관리

### 2.1 키 위치
Rails credentials에 암호화 키가 저장되어 있습니다:

```yaml
# config/credentials.yml.enc (암호화됨)
active_record_encryption:
  primary_key: "32바이트 키..."
  deterministic_key: "32바이트 키..."
  key_derivation_salt: "32바이트 솔트..."
```

### 2.2 키 확인 방법 (관리자 전용)
```bash
# Rails 콘솔에서 확인
bin/rails credentials:show

# 또는 특정 키만 확인
bin/rails runner "puts Rails.application.credentials.active_record_encryption"
```

### 2.3 키 역할
| 키 | 용도 |
|----|------|
| `primary_key` | 비결정적 암호화 (email_original 등) |
| `deterministic_key` | 결정적 암호화 (email_hash - 검색용) |
| `key_derivation_salt` | 키 파생에 사용되는 솔트 |

---

## 3. 데이터 복호화 방법

### 3.1 Rails 콘솔에서 복호화 (가장 간단)

```ruby
# Rails 콘솔 시작
bin/rails console

# 탈퇴 기록 조회
deletion = UserDeletion.find(id)

# 자동 복호화 (Active Record Encryption이 처리)
deletion.email_original    # => "original@example.com"
deletion.name_original     # => "홍길동"
deletion.phone_original    # => "010-1234-5678"

# JSON 스냅샷 파싱
deletion.parsed_snapshot   # => { "bio" => "...", "skills" => "..." }
```

`★ Insight ─────────────────────────────────────`
**Rails Active Record Encryption의 핵심 특징:**
1. 모델에서 `encrypts :컬럼명`으로 선언하면 읽기/쓰기 시 자동 암복호화
2. 데이터베이스에는 암호화된 상태로 저장되어 DB 유출 시에도 안전
3. 애플리케이션 레벨 암호화이므로 raw SQL로는 복호화 불가
`─────────────────────────────────────────────────`

### 3.2 이메일로 탈퇴 기록 검색

```ruby
# email_hash는 deterministic이므로 검색 가능
email = "original@example.com"
deletion = UserDeletion.find_by(email_hash: email)

# 또는 User를 통해 찾기
user = User.deleted.find_by(id: user_id)
deletion = user.last_deletion
```

### 3.3 관리자 페이지에서 조회

| 페이지 | URL | 설명 |
|--------|-----|------|
| 회원 상세 | `/admin/users/:id` | 탈퇴 회원의 원본 정보 표시 |
| 탈퇴 기록 상세 | `/admin/user_deletions/:id` | 상세 탈퇴 정보 |
| 탈퇴 기록 목록 | `/admin/user_deletions` | 전체 탈퇴 기록 |

### 3.4 법적 분쟁 시 데이터 접근

법적 분쟁 발생 시 다음 절차를 따릅니다:

1. **열람 사유 기록 필수**
   ```ruby
   deletion = UserDeletion.find(id)
   deletion.record_admin_view!(
     admin: current_admin,
     reason: "법적 분쟁 대응 - 사건번호 2025가합12345",
     ip_address: request.remote_ip,
     user_agent: request.user_agent
   )

   # 이후 원본 정보 접근
   puts deletion.email_original
   puts deletion.name_original
   ```

2. **열람 기록 확인**
   ```ruby
   # 해당 탈퇴 기록에 대한 모든 열람 로그
   AdminViewLog.where(target: deletion).order(created_at: :desc)
   ```

3. **관리자 페이지에서 열람**
   - `/admin/user_deletions/:id` 접근
   - 열람 사유 입력 폼 제출
   - 원본 정보 표시 + 자동 로그 기록

---

## 4. 데이터 보관 정책

### 4.1 보관 기간
| 구분 | 기간 | 법적 근거 |
|------|------|----------|
| 탈퇴 회원 개인정보 | **5년** | 전자상거래법 제6조 |
| 관리자 열람 로그 | **영구** | 감사 추적 |

### 4.2 자동 파기 스케줄
```ruby
# 매일 새벽 3시 실행 (config/recurring.yml)
destroy_expired_deletions:
  class: DestroyExpiredDeletionsJob
  cron: "0 3 * * *"
  description: "5년 경과 탈퇴 기록 영구 삭제"
```

### 4.3 파기 대상 확인
```ruby
# 파기 예정 기록 조회
UserDeletion.expired  # destroy_scheduled_at <= 현재시각

# 30일 내 파기 예정
UserDeletion.expiring_soon  # destroy_scheduled_at <= 30일 후
```

---

## 5. 보안 감사 로그

### 5.1 AdminViewLog 구조
```ruby
# app/models/admin_view_log.rb
class AdminViewLog < ApplicationRecord
  belongs_to :admin, class_name: "User"
  belongs_to :target, polymorphic: true

  # action: "reveal_personal_info"
  # reason: 열람 사유 (필수)
  # ip_address, user_agent: 접근 환경
end
```

### 5.2 열람 로그 조회
```ruby
# 특정 관리자의 모든 열람 기록
AdminViewLog.where(admin: admin_user).order(created_at: :desc)

# 특정 탈퇴 기록에 대한 열람 기록
AdminViewLog.where(target_type: "UserDeletion", target_id: deletion.id)

# 최근 7일간 열람 기록
AdminViewLog.where("created_at >= ?", 7.days.ago)
```

---

## 6. 키 백업 및 복구

### 6.1 master.key 백업 중요성

⚠️ **중요**: `config/master.key` 분실 시 모든 암호화된 데이터 복호화 **불가능**

```
master.key 분실
      ↓
credentials.yml.enc 복호화 불가
      ↓
active_record_encryption 키 접근 불가
      ↓
user_deletions의 암호화된 데이터 영구 손실
```

### 6.2 안전한 백업 방법

1. **물리적 분리 보관**
   - 암호화된 USB에 저장
   - 금고 보관

2. **클라우드 보안 저장소**
   - AWS Secrets Manager
   - Google Secret Manager
   - Azure Key Vault

3. **백업 시 주의사항**
   - master.key를 코드 저장소에 절대 커밋하지 않음
   - .gitignore에 등록 확인
   - 백업 파일 접근 권한 최소화

### 6.3 키 교체 (Key Rotation)
```ruby
# 새 키 생성
bin/rails db:encryption:init

# 기존 데이터 재암호화 (주의: 서비스 중단 필요할 수 있음)
# Rails 가이드 참조: https://guides.rubyonrails.org/active_record_encryption.html
```

---

## 7. 관련 파일 참조

| 파일 | 설명 |
|------|------|
| `app/models/user_deletion.rb` | 탈퇴 기록 모델 (encrypts 선언) |
| `app/models/admin_view_log.rb` | 관리자 열람 로그 |
| `app/services/users/deletion_service.rb` | 탈퇴 처리 서비스 |
| `app/controllers/admin/user_deletions_controller.rb` | 관리자 조회 컨트롤러 |
| `app/jobs/destroy_expired_deletions_job.rb` | 자동 파기 작업 |
| `config/recurring.yml` | 자동 파기 스케줄 |

---

## 8. 자주 묻는 질문 (FAQ)

### Q1: raw SQL로 암호화된 데이터를 복호화할 수 있나요?
**A:** 아니요. Rails Active Record Encryption은 애플리케이션 레벨 암호화입니다.
반드시 Rails 애플리케이션을 통해 접근해야 합니다.

### Q2: 데이터베이스가 유출되면 개인정보도 노출되나요?
**A:** 아니요. 데이터베이스에는 암호화된 상태로 저장되어 있습니다.
`master.key` 없이는 복호화할 수 없습니다.

### Q3: 탈퇴 후 5년이 지나면 어떻게 되나요?
**A:** `DestroyExpiredDeletionsJob`이 자동으로 해당 레코드를 영구 삭제합니다.
삭제 후에는 어떤 방법으로도 복구할 수 없습니다.

### Q4: 관리자가 원본 정보를 조회하면 기록이 남나요?
**A:** 예. `AdminViewLog` 테이블에 자동으로 기록됩니다.
열람 사유, 접근 IP, 시간 등이 저장됩니다.

---

## 변경 이력

| 날짜 | 변경사항 | 작성자 |
|------|----------|--------|
| 2025-12-30 | 최초 작성 | Claude |
