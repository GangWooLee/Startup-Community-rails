# OAuth 소셜 로그인 설정 가이드

Google과 GitHub를 사용한 소셜 로그인을 설정하는 방법입니다.

## 📋 목차

1. [Google OAuth 설정](#google-oauth-설정)
2. [GitHub OAuth 설정](#github-oauth-설정)
3. [환경 변수 설정](#환경-변수-설정)
4. [테스트](#테스트)

---

## 🔑 Google OAuth 설정

### 1. Google Cloud Console 접속

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 프로젝트 선택 또는 새 프로젝트 생성

### 2. OAuth 동의 화면 설정

1. 좌측 메뉴 → **APIs & Services** → **OAuth consent screen**
2. **User Type**: External 선택
3. **앱 정보** 입력:
   - 앱 이름: `스타트업 커뮤니티`
   - 사용자 지원 이메일: 본인 이메일
   - 개발자 연락처 정보: 본인 이메일
4. **Scopes** 설정:
   - `./auth/userinfo.email`
   - `./auth/userinfo.profile`
5. 저장 및 계속

### 3. OAuth 클라이언트 ID 생성

1. 좌측 메뉴 → **Credentials**
2. **+ CREATE CREDENTIALS** → **OAuth client ID**
3. 애플리케이션 유형: **Web application**
4. 이름: `Startup Community Web`
5. **승인된 리디렉션 URI** 추가:
   ```
   http://localhost:3000/auth/google_oauth2/callback
   ```

   프로덕션 배포 시 추가:
   ```
   https://yourdomain.com/auth/google_oauth2/callback
   ```

6. **CREATE** 클릭
7. **Client ID**와 **Client Secret** 복사 (환경 변수에 사용)

---

## 🐙 GitHub OAuth 설정

### 1. GitHub Developer Settings 접속

1. GitHub 로그인 후 우측 상단 프로필 → **Settings**
2. 좌측 하단 **Developer settings**
3. **OAuth Apps** → **New OAuth App**

### 2. OAuth App 등록

1. **Application name**: `Startup Community`
2. **Homepage URL**:
   ```
   http://localhost:3000
   ```
3. **Application description** (선택): `스타트업 커뮤니티 플랫폼`
4. **Authorization callback URL**:
   ```
   http://localhost:3000/auth/github/callback
   ```

   프로덕션 배포 시:
   ```
   https://yourdomain.com/auth/github/callback
   ```

5. **Register application** 클릭
6. **Client ID** 확인
7. **Generate a new client secret** 클릭
8. **Client Secret** 복사 (한 번만 표시됨!)

---

## 🔧 환경 변수 설정

### 1. .env 파일 생성

프로젝트 루트에 `.env` 파일 생성:

```bash
cp .env.example .env
```

### 2. 환경 변수 입력

`.env` 파일에 위에서 복사한 값들을 입력:

```env
# Google OAuth2
GOOGLE_CLIENT_ID=your_google_client_id_here
GOOGLE_CLIENT_SECRET=your_google_client_secret_here

# GitHub OAuth
GITHUB_CLIENT_ID=your_github_client_id_here
GITHUB_CLIENT_SECRET=your_github_client_secret_here
```

**⚠️ 중요**: `.env` 파일은 절대 Git에 커밋하지 마세요! (이미 .gitignore에 추가되어 있음)

### 3. 환경 변수 로드

`.env` 파일을 자동으로 로드하려면 `dotenv-rails` gem을 사용할 수 있습니다.

**Gemfile에 추가**:
```ruby
gem 'dotenv-rails', groups: [:development, :test]
```

**설치**:
```bash
bundle install
```

---

## 🧪 테스트

### 1. 서버 재시작

환경 변수를 변경했으면 서버를 재시작해야 합니다:

```bash
# 기존 서버 종료 (Ctrl + C)
rails server
```

### 2. 로그인 테스트

1. 브라우저에서 `http://localhost:3000/login` 접속
2. **Google로 계속하기** 또는 **GitHub로 계속하기** 버튼 클릭
3. OAuth 제공자(Google/GitHub)의 로그인 페이지로 리디렉션
4. 계정 선택 및 권한 승인
5. 애플리케이션으로 리디렉션되어 자동 로그인

### 3. 확인 사항

로그인 성공 후 확인:

- [ ] 세션이 유지되는지 (페이지 이동 시)
- [ ] 사용자 이메일과 이름이 제대로 표시되는지
- [ ] 로그아웃이 정상 작동하는지
- [ ] 같은 이메일로 다시 로그인 시 같은 계정으로 인식되는지

---

## 🐛 문제 해결

### 에러: "redirect_uri_mismatch"

**원인**: Callback URL이 OAuth 앱 설정과 일치하지 않음

**해결**:
1. Google/GitHub OAuth 설정에서 Redirect URI 확인
2. 정확히 `http://localhost:3000/auth/google_oauth2/callback` 형식인지 확인
3. 포트 번호 확인 (3000이 아니라면 수정)

### 에러: "invalid_client"

**원인**: Client ID 또는 Secret이 잘못됨

**해결**:
1. `.env` 파일의 값 재확인
2. Google/GitHub에서 새로운 Secret 생성
3. 서버 재시작

### OAuth 사용자가 비밀번호 로그인 불가

**정상 동작**: OAuth로 가입한 사용자는 비밀번호가 없습니다.

**해결**: 계속 OAuth로 로그인하면 됩니다. 필요시 비밀번호 설정 기능 추가 가능.

### 이메일 중복 에러

**원인**: 같은 이메일로 이미 일반 로그인 계정이 존재

**해결책 1**: 기존 일반 로그인 계정 사용
**해결책 2**: 다른 이메일로 OAuth 로그인

---

## 🚀 프로덕션 배포

프로덕션 환경에서는:

1. **환경 변수를 서버에 설정**:
   - Heroku: `heroku config:set`
   - Render: Dashboard에서 Environment Variables 추가
   - AWS: Parameter Store 또는 Secrets Manager 사용

2. **OAuth 앱에 프로덕션 URL 추가**:
   - Google: `https://yourdomain.com/auth/google_oauth2/callback`
   - GitHub: `https://yourdomain.com/auth/github/callback`

3. **HTTPS 강제** (Rails production 설정):
   ```ruby
   config.force_ssl = true
   ```

---

## 📚 추가 자료

- [OmniAuth 공식 문서](https://github.com/omniauth/omniauth)
- [Google OAuth 가이드](https://developers.google.com/identity/protocols/oauth2)
- [GitHub OAuth 가이드](https://docs.github.com/en/developers/apps/building-oauth-apps)

---

**작성일**: 2025-12-19
**버전**: 1.0.0
