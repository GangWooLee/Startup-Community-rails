---
paths: config/*, lib/**, Gemfile, .gitignore
---

# 절대 삭제 금지 파일

| 파일 | 이유 | 영향범위 |
|------|------|--------|
| `lib/faraday_ssl.rb` | Mac에서 SSL 에러 발생 | macOS 개발자 |
| `application.html.erb` 내 애니메이션 CSS | 랜딩 페이지 깨짐 | 프로덕션 |
| `.gitignore` 규칙들 | credentials 노출 위험 | 보안 |
| `config/credentials.yml.enc` | 비밀키 저장소 | 전체 |
