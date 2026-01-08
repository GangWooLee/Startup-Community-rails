---
paths: app/**/*.rb, config/**/*.rb, lib/**/*.rb
---

# Rails 안티패턴 (금지 사항)

## 데이터베이스 쿼리
- ❌ `User.all` (페이지네이션 없음) → ✅ `User.page(params[:page])`
- ❌ N+1 쿼리 → ✅ `includes(:posts)` 또는 `joins(:posts)`
- ❌ Raw SQL → ✅ `where()` ActiveRecord 메서드

## 인증/보안
- ❌ 민감정보 로그 출력 → ✅ Rails sanitizers
- ❌ credentials 파일 커밋 → ✅ credentials:edit 사용
- ❌ production에서 db:reset/drop

## 컨트롤러
- ❌ 비즈니스 로직 직접 작성 → ✅ Service 객체
- ❌ God Object (거대한 클래스) → ✅ Concern 분리
