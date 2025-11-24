# API Design Document

## 문서 정보
- **프로젝트**: Startup Community Platform
- **API 스타일**: RESTful
- **버전**: v1
- **응답 형식**: JSON

---

## 1. API 설계 원칙

### 1.1 RESTful 규칙
- **리소스 기반**: URL은 명사형 (동사 지양)
- **HTTP 메서드**: GET, POST, PATCH, DELETE
- **복수형 사용**: `/users` (not `/user`)
- **중첩 제한**: 최대 2레벨 (`/users/:id/posts`)

### 1.2 네이밍 컨벤션
- **URL**: kebab-case (`/user-profiles`)
- **JSON 키**: snake_case (`user_name`)
- **쿼리 파라미터**: snake_case (`?sort_by=created_at`)

### 1.3 버전 관리
```
# 네임스페이스로 버전 관리
/api/v1/users
/api/v2/users  # 향후 추가
```

---

## 2. 인증 (Authentication)

### 2.1 세션 기반 인증 (기본)
```ruby
# 회원가입
POST /signup
Request:
{
  "user": {
    "email": "user@example.com",
    "password": "password123",
    "name": "John Doe"
  }
}

Response: 201 Created
{
  "status": "success",
  "data": {
    "id": 1,
    "email": "user@example.com",
    "name": "John Doe",
    "created_at": "2025-11-25T12:00:00Z"
  }
}

# 로그인
POST /login
Request:
{
  "email": "user@example.com",
  "password": "password123"
}

Response: 200 OK
{
  "status": "success",
  "data": {
    "user": { ... },
    "session_token": "abc123..."  # Cookie로 전달
  }
}

# 로그아웃
DELETE /logout
Response: 204 No Content
```

### 2.2 JWT 인증 (API 전용 시)
```ruby
# Authorization 헤더
Authorization: Bearer <jwt_token>

# 토큰 갱신
POST /api/v1/auth/refresh
Response:
{
  "access_token": "new_token...",
  "expires_in": 3600
}
```

---

## 3. 에러 핸들링

### 3.1 에러 응답 형식
```json
{
  "status": "error",
  "message": "User-friendly error message",
  "errors": [
    {
      "field": "email",
      "code": "taken",
      "message": "Email has already been taken"
    }
  ],
  "request_id": "req_abc123"
}
```

### 3.2 HTTP 상태 코드
| 코드 | 의미 | 사용 예시 |
|------|------|-----------|
| 200 | OK | 조회 성공 |
| 201 | Created | 생성 성공 |
| 204 | No Content | 삭제 성공 |
| 400 | Bad Request | 잘못된 요청 |
| 401 | Unauthorized | 인증 필요 |
| 403 | Forbidden | 권한 없음 |
| 404 | Not Found | 리소스 없음 |
| 422 | Unprocessable Entity | 유효성 검증 실패 |
| 500 | Internal Server Error | 서버 오류 |

---

## 4. API 엔드포인트

### 4.1 Users

#### 목록 조회
```
GET /api/v1/users

Query Parameters:
- page: 페이지 번호 (default: 1)
- per_page: 페이지당 개수 (default: 20)
- sort_by: 정렬 기준 (name|created_at)
- order: 정렬 순서 (asc|desc)

Response: 200 OK
{
  "status": "success",
  "data": [
    {
      "id": 1,
      "email": "user@example.com",
      "name": "John Doe",
      "role": "user",
      "created_at": "2025-11-25T12:00:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 100,
    "per_page": 20
  }
}
```

#### 상세 조회
```
GET /api/v1/users/:id

Response: 200 OK
{
  "status": "success",
  "data": {
    "id": 1,
    "email": "user@example.com",
    "name": "John Doe",
    "role": "user",
    "created_at": "2025-11-25T12:00:00Z",
    "updated_at": "2025-11-25T12:00:00Z"
  }
}
```

#### 생성
```
POST /api/v1/users

Request:
{
  "user": {
    "email": "newuser@example.com",
    "password": "password123",
    "name": "Jane Doe"
  }
}

Response: 201 Created
{
  "status": "success",
  "data": { ... }
}
```

#### 수정
```
PATCH /api/v1/users/:id

Request:
{
  "user": {
    "name": "Updated Name"
  }
}

Response: 200 OK
{
  "status": "success",
  "data": { ... }
}
```

#### 삭제
```
DELETE /api/v1/users/:id

Response: 204 No Content
```

---

### 4.2 Posts

#### 목록 조회
```
GET /api/v1/posts

Query Parameters:
- status: 상태 필터 (draft|published|archived)
- user_id: 작성자 필터
- page, per_page, sort_by, order

Response: 200 OK
{
  "status": "success",
  "data": [
    {
      "id": 1,
      "title": "Post Title",
      "content": "Post content...",
      "status": "published",
      "views_count": 42,
      "user": {
        "id": 1,
        "name": "John Doe"
      },
      "created_at": "2025-11-25T12:00:00Z"
    }
  ],
  "meta": { ... }
}
```

#### 사용자별 게시글 조회
```
GET /api/v1/users/:user_id/posts

Response: 200 OK (위와 동일)
```

#### 생성
```
POST /api/v1/posts

Request:
{
  "post": {
    "title": "New Post",
    "content": "Content here...",
    "status": "draft"
  }
}

Response: 201 Created
```

#### 조회수 증가
```
POST /api/v1/posts/:id/views

Response: 200 OK
{
  "status": "success",
  "data": {
    "views_count": 43
  }
}
```

---

### 4.3 [추가 리소스]

[프로젝트에 맞게 추가]

---

## 5. 페이지네이션

### 5.1 요청
```
GET /api/v1/posts?page=2&per_page=20
```

### 5.2 응답 메타데이터
```json
{
  "data": [ ... ],
  "meta": {
    "current_page": 2,
    "total_pages": 10,
    "total_count": 200,
    "per_page": 20,
    "next_page": 3,
    "prev_page": 1
  },
  "links": {
    "first": "/api/v1/posts?page=1",
    "last": "/api/v1/posts?page=10",
    "next": "/api/v1/posts?page=3",
    "prev": "/api/v1/posts?page=1"
  }
}
```

---

## 6. 필터링 & 정렬

### 6.1 필터링
```
# 단일 조건
GET /api/v1/posts?status=published

# 다중 조건
GET /api/v1/posts?status=published&user_id=1

# 범위 검색
GET /api/v1/posts?created_after=2025-01-01&created_before=2025-12-31
```

### 6.2 정렬
```
# 단일 정렬
GET /api/v1/posts?sort_by=created_at&order=desc

# 다중 정렬 (선택)
GET /api/v1/posts?sort=created_at:desc,title:asc
```

### 6.3 검색
```
GET /api/v1/posts?q=keyword

# 특정 필드 검색
GET /api/v1/posts?title_cont=keyword
```

---

## 7. Rate Limiting

### 7.1 제한 정책
```
- 인증된 사용자: 1000 requests/hour
- 미인증 사용자: 60 requests/hour
```

### 7.2 응답 헤더
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640000000
```

### 7.3 초과 시
```
HTTP 429 Too Many Requests
{
  "status": "error",
  "message": "Rate limit exceeded",
  "retry_after": 3600
}
```

---

## 8. 보안

### 8.1 CORS
```ruby
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'example.com', 'localhost:3000'
    resource '/api/*',
      headers: :any,
      methods: [:get, :post, :patch, :delete, :options]
  end
end
```

### 8.2 CSRF 보호
```ruby
# API는 CSRF 토큰 비활성화
class Api::V1::BaseController < ActionController::API
  skip_before_action :verify_authenticity_token
end
```

### 8.3 Strong Parameters
```ruby
def post_params
  params.require(:post).permit(:title, :content, :status)
end
```

---

## 9. 캐싱

### 9.1 HTTP 캐싱
```ruby
# Controller
def show
  @post = Post.find(params[:id])

  if stale?(@post)
    render json: @post
  end
end

# Response Headers
ETag: "abc123"
Last-Modified: Wed, 25 Nov 2025 12:00:00 GMT
Cache-Control: max-age=3600
```

---

## 10. API 문서화

### 10.1 Swagger/OpenAPI (선택)
```ruby
# Gemfile
gem 'rswag'

# 자동 문서 생성
GET /api-docs
```

### 10.2 Postman Collection
- 엔드포인트별 예시 요청
- 환경 변수 설정
- 테스트 케이스 포함

---

## 11. 테스트

### 11.1 Controller Test
```ruby
# test/controllers/api/v1/users_controller_test.rb
class Api::V1::UsersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get api_v1_users_url, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "success", json["status"]
  end
end
```

---

## 참고자료

- Rails API Guides: https://guides.rubyonrails.org/api_app.html
- REST API Best Practices: https://restfulapi.net
- HTTP Status Codes: https://httpstatuses.com
