---
paths: config/*, lib/**, Gemfile, .gitignore
---

# 절대 삭제/수정 금지 파일

## 삭제 금지 목록

| 파일 | 이유 | 삭제 시 영향 |
|------|------|------------|
| `lib/faraday_ssl.rb` | Mac SSL 인증서 경로 설정 | macOS에서 모든 API 호출 실패 |
| `application.html.erb` 내 애니메이션 CSS | Tailwind CDN이 커스텀 CSS 미인식 | 랜딩 페이지 애니메이션 깨짐 |
| `.gitignore` 내 credentials 규칙 | 비밀키 보호 | API 키/비밀번호 GitHub 노출 |
| `config/credentials.yml.enc` | 암호화된 비밀 저장소 | 모든 외부 서비스 연동 실패 |
| `config/master.key` | credentials 복호화 키 | credentials 접근 불가 |
| `config/initializers/resend.rb` | Resend API 키 설정 | 이메일 발송 실패 |
| `config/initializers/sentry.rb` | 에러 트래킹 설정 | 프로덕션 에러 모니터링 불가 |

## 수정 시 주의 파일

| 파일 | 주의사항 |
|------|---------|
| `config/routes.rb` | 기존 경로 삭제 시 링크 깨짐 |
| `config/database.yml` | production 설정 변경 금지 |
| `Gemfile` | 버전 고정된 gem 업그레이드 주의 |
| `config/environments/production.rb` | 배포 후 영향 큼 |

## 프로덕션 금지 명령어

```bash
# 절대 금지 (데이터 손실)
rails db:reset
rails db:drop
rails db:schema:load  # 기존 데이터 삭제됨

# 주의 필요
rails db:migrate:down  # 롤백 전 영향 확인
rails db:rollback      # 최근 마이그레이션만
```

## Git 금지 작업

```bash
# main 브랜치 force push 금지
git push --force origin main
git push -f origin main

# 히스토리 변경 금지
git rebase -i  # main에서
git reset --hard  # 공유 브랜치에서
```

## 환경 변수 (프로덕션)

```
필수 환경 변수:
- RAILS_MASTER_KEY
- DATABASE_URL (PostgreSQL)
- REDIS_URL (Solid Cable/Cache)

선택 환경 변수:
- SENTRY_DSN
- GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET
- GITHUB_CLIENT_ID / GITHUB_CLIENT_SECRET
```
