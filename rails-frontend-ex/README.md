# Grounded - 창업자 커뮤니티 (Rails 버전)

Next.js 기반의 스타트업 커뮤니티 애플리케이션을 Rails ERB 템플릿으로 변환한 프로젝트입니다.

## 프로젝트 구조

```
rails-app/
├── app/
│   ├── controllers/           # 컨트롤러
│   │   ├── application_controller.rb
│   │   ├── community_controller.rb
│   │   ├── profiles_controller.rb
│   │   ├── freelance_controller.rb
│   │   └── my_page_controller.rb
│   ├── models/               # 모델 (향후 추가)
│   ├── views/                # ERB 뷰 템플릿
│   │   ├── layouts/
│   │   │   └── application.html.erb
│   │   ├── shared/
│   │   │   ├── _bottom_nav.html.erb
│   │   │   └── icons/        # SVG 아이콘 파셜
│   │   ├── community/
│   │   │   ├── index.html.erb
│   │   │   └── new.html.erb
│   │   ├── profiles/
│   │   │   └── show.html.erb
│   │   ├── freelance/
│   │   │   └── index.html.erb
│   │   └── my_page/
│   │       └── show.html.erb
│   └── helpers/              # 헬퍼 메서드 (향후 추가)
├── config/
│   ├── routes.rb            # 라우팅 설정
│   ├── application.rb       # 애플리케이션 설정
│   └── boot.rb
├── public/
│   └── stylesheets/
│       └── application.css  # Tailwind CSS 스타일
├── Gemfile                  # Ruby 의존성
└── README.md
```

## 주요 기능

### 1. 커뮤니티 (Community)
- **메인 페이지** (`/`): 커뮤니티 글 목록 표시
- **새 글 작성** (`/community/new`): 새로운 커뮤니티 글 작성
- **글 상세보기** (`/community/:id`): 개별 글 상세 페이지

### 2. 프로필 (Profile)
- **프로필 보기** (`/profile/:id`): 사용자 프로필 페이지
- 커뮤니티 글과 외주 공고를 탭으로 구분하여 표시
- 간단한 JavaScript로 탭 전환 구현

### 3. 프리랜스 (Freelance)
- **외주 목록** (`/freelance`): 구인/구직 공고 목록
- 구인과 구직을 탭으로 구분
- **공고 상세** (`/freelance/job/:id`, `/freelance/talent/:id`)

### 4. 마이페이지 (My Page)
- **내 정보** (`/my-page`): 사용자 정보 표시
- **프로필 수정** (`/my-page/edit`): 프로필 수정 페이지

## 라우팅

```ruby
# config/routes.rb
Rails.application.routes.draw do
  root "community#index"

  resources :community, only: [:index, :show, :new, :create]
  get 'profile/:id', to: 'profiles#show', as: :profile

  resources :freelance, only: [:index] do
    collection do
      get 'new'
    end
  end
  get 'freelance/job/:id', to: 'freelance#show_job', as: :freelance_job
  get 'freelance/talent/:id', to: 'freelance#show_talent', as: :freelance_talent

  get 'my-page', to: 'my_page#show', as: :my_page
  get 'my-page/edit', to: 'my_page#edit', as: :edit_my_page
  patch 'my-page', to: 'my_page#update'
end
```

## 기술 스택

- **Ruby on Rails 7.0+**: 백엔드 프레임워크
- **ERB**: 템플릿 엔진
- **Tailwind CSS**: 스타일링 (Next.js 프로젝트와 동일한 스타일 유지)
- **Vanilla JavaScript**: 탭 전환 등 간단한 인터랙션

## Next.js에서 Rails로의 주요 변환 사항

### 1. 컴포넌트 → 파셜 (Partials)
```jsx
// Next.js
import { BottomNav } from "@/components/bottom-nav"
<BottomNav />
```

```erb
<%# Rails %>
<%= render "shared/bottom_nav" %>
```

### 2. Link → link_to
```jsx
// Next.js
<Link href="/community/new">새 글 작성</Link>
```

```erb
<%# Rails %>
<%= link_to "새 글 작성", new_community_path %>
```

### 3. useState → JavaScript 또는 서버 사이드
- 간단한 UI 상태(탭 전환 등)는 Vanilla JavaScript로 구현
- 복잡한 상태 관리는 서버 사이드에서 처리

### 4. 아이콘 컴포넌트 → SVG 파셜
```jsx
// Next.js
import { Heart } from "lucide-react"
<Heart className="h-4 w-4" />
```

```erb
<%# Rails %>
<%= render partial: "shared/icons/heart", locals: { css_class: "h-4 w-4" } %>
```

## 설치 및 실행 (예정)

현재 프로젝트는 파일 구조만 생성된 상태입니다. 실제 실행을 위해서는:

1. Ruby 3.0+ 설치
2. Rails 7.0+ 설치
```bash
gem install rails
```

3. 의존성 설치
```bash
cd rails-app
bundle install
```

4. Tailwind CSS 설정
```bash
rails tailwindcss:install
```

5. 데이터베이스 설정
```bash
rails db:create
rails db:migrate
```

6. 서버 실행
```bash
rails server
```

## TODO

- [ ] 데이터베이스 모델 생성 (Post, User, Job, Talent 등)
- [ ] 실제 데이터베이스 연동 (현재는 Mock 데이터 사용)
- [ ] 사용자 인증 시스템 (Devise 등)
- [ ] 이미지 업로드 기능 (Active Storage)
- [ ] 댓글 기능
- [ ] 좋아요/북마크 기능
- [ ] 검색 기능
- [ ] 페이지네이션
- [ ] API 엔드포인트 (필요시)

## 파일 매핑

### Next.js → Rails 변환 매핑

| Next.js 파일 | Rails 파일 |
|-------------|-----------|
| `app/page.tsx` | `app/views/community/index.html.erb` |
| `app/layout.tsx` | `app/views/layouts/application.html.erb` |
| `app/community/new/page.tsx` | `app/views/community/new.html.erb` |
| `app/profile/[id]/page.tsx` | `app/views/profiles/show.html.erb` |
| `app/freelance/page.tsx` | `app/views/freelance/index.html.erb` |
| `app/my-page/page.tsx` | `app/views/my_page/show.html.erb` |
| `components/bottom-nav.tsx` | `app/views/shared/_bottom_nav.html.erb` |

## 라이선스

MIT

## 기여

이 프로젝트는 Next.js 프로젝트를 Rails로 변환한 학습 목적의 프로젝트입니다.
