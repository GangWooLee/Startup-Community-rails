# UI 테스트 빠른 시작 가이드

Ruby 버전 문제로 인해 빠르게 UI를 테스트하기 위한 간편한 방법입니다.

## ⚠️ 현재 상황

- **현재 Ruby 버전**: 2.6.10
- **필요 Ruby 버전**: 3.1 이상 (Rails 8.1 요구사항)
- **문제**: Rails 서버를 시작할 수 없음 (Ruby 버전 불일치)

## 🚀 해결 방법

⚠️ **중요**: 레이아웃 파일에 Tailwind CDN이 이미 적용되어 있지만, Rails 서버를 시작하려면 Ruby 버전 업그레이드가 **필수**입니다.

### Ruby 버전 업그레이드 (필수)

✅ **레이아웃 파일은 이미 Tailwind CDN으로 설정되어 있습니다.**

이제 Ruby 버전을 업그레이드해야 서버를 시작할 수 있습니다.

#### rbenv 사용 (권장)

```bash
# rbenv 설치 (Homebrew)
brew install rbenv ruby-build

# Ruby 3.3 설치
rbenv install 3.3.0

# 프로젝트에 Ruby 버전 설정
cd /Users/igangu/Startup-Community-rails
rbenv local 3.3.0

# 새 터미널에서 Ruby 버전 확인
ruby -v

# Bundler 설치 및 Gem 설치
gem install bundler
bundle install

# Tailwind CSS 설치
rails tailwindcss:install

# 서버 시작
./bin/dev
```

#### asdf 사용

```bash
# asdf 설치
brew install asdf

# Ruby 플러그인 추가
asdf plugin add ruby

# Ruby 3.3 설치
asdf install ruby 3.3.0

# 프로젝트에 Ruby 버전 설정
cd /Users/igangu/Startup-Community-rails
asdf local ruby 3.3.0

# 나머지는 위와 동일
gem install bundler
bundle install
rails tailwindcss:install
./bin/dev
```

---

## 📱 현재 구현된 페이지

### 1. 커뮤니티 홈 (/)
- 게시글 카드 리스트
- 작성자 프로필 링크
- 좋아요, 댓글, 공유, 북마크 버튼
- 플로팅 액션 버튼
- 하단 내비게이션

### 2. 프로필 페이지 (/profiles/:id)
- 프로필 정보
- 연락처 정보
- 스킬 태그
- 탭 UI (커뮤니티 글 / 외주 공고)
- JavaScript 탭 전환 기능

### 3. 외주 마켓플레이스 (/job_posts)
- 구인/구직 탭
- 공고 카드 리스트
- JavaScript 탭 전환 기능

### 4. 마이페이지 (/my_page)
- 프로필 카드
- 내가 쓴 글
- 스크랩한 글

---

## 🎯 테스트 체크리스트

UI 테스트 시 확인할 항목:

- [ ] 페이지가 정상적으로 로드되는가?
- [ ] Tailwind CSS 스타일이 적용되는가?
- [ ] 하단 내비게이션이 보이는가?
- [ ] 하단 내비게이션 클릭 시 페이지 전환이 되는가?
- [ ] 모바일 뷰에서 레이아웃이 정상인가? (개발자 도구로 확인)
- [ ] 아이콘들이 정상적으로 표시되는가?
- [ ] 프로필 페이지의 탭 전환이 작동하는가?
- [ ] 외주 페이지의 탭 전환이 작동하는가?

---

## ⚡ 빠른 시작

1. **Ruby 버전 관리자 설치** (rbenv 또는 asdf)
2. **Ruby 3.3.0 설치**
3. **Gem 설치**: `bundle install`
4. **데이터베이스 설정**: `rails db:create db:migrate`
5. **서버 시작**: `rails server`
6. **브라우저에서 확인**: http://localhost:3000

---

## 🔧 문제 해결

### Q: 페이지가 로드되지 않아요
A: 터미널에서 에러 메시지를 확인하세요. 대부분 라우팅이나 컨트롤러 문제입니다.

### Q: 스타일이 적용되지 않아요
A: CDN 방식을 사용했는지 확인하세요. 인터넷 연결도 확인하세요.

### Q: 아이콘이 보이지 않아요
A: `app/views/shared/icons/` 폴더에 아이콘 파일들이 있는지 확인하세요.

### Q: 탭 전환이 안 돼요
A: 브라우저 콘솔에서 JavaScript 에러를 확인하세요.

---

## 📞 다음 단계

UI 테스트 후:

1. **Ruby 버전 업그레이드**: rbenv 또는 asdf 사용
2. **정식 Tailwind 설치**: `rails tailwindcss:install`
3. **백엔드 구현**: `.claude/TASKS.md` 참조
4. **데이터베이스 연동**: `.claude/DATABASE.md` 참조

즐거운 개발 되세요! 🚀
