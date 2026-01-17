---
paths: test/system/**/*.rb, test/integration/**/*.rb
---

# CI 트러블슈팅 가이드

> **목적**: 반복되는 CI 실패 패턴과 해결책을 문서화하여 동일한 실수 방지
> **최종 업데이트**: 2026-01-17

---

## 1. Stale Element Reference Error (20% of failures)

### 증상
```
Selenium::WebDriver::Error::StaleElementReferenceError:
stale element reference: stale element not found in the current active document
```

### 원인
Turbo Stream이 DOM을 업데이트하면 기존 Ruby 변수가 참조하던 요소가 교체됨.

### 잘못된 패턴
```ruby
# ❌ 금지: 반복문 외부에서 캐시된 요소 참조
input = find("[data-comment-form-target='input']")
3.times do
  page.execute_script(
    "arguments[0].dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter' }))",
    input  # ← Turbo Stream 후 stale 참조!
  )
end
```

### 올바른 패턴
```ruby
# ✅ 권장: 반복문 내부에서 JavaScript로 매번 새로 찾기
3.times do
  page.execute_script(<<~JS)
    const input = document.querySelector("[data-comment-form-target='input']");
    if (input) {
      input.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));
    }
  JS
end
```

### 예방 규칙
- **반복 제출 테스트**: 항상 JavaScript querySelector 사용
- **Turbo Stream 응답 후**: 요소 다시 찾기 (`find()` 재호출)
- **폼 제출 후**: DOM 참조 갱신

---

## 2. ESC 키 모달 닫기 (10% of failures)

### 증상
```
Expected at least one element matching selector "dialog", found 0.
```

### 원인
`send_keys(:escape)`가 포커스된 요소에만 전달됨. 모달이 포커스를 받지 않으면 이벤트 미전달.

### 잘못된 패턴
```ruby
# ❌ 금지: send_keys 단독 사용
page.send_keys(:escape)
```

### 올바른 패턴
```ruby
# ✅ 권장: document 레벨 이벤트 발생
page.execute_script(<<~JS)
  document.dispatchEvent(new KeyboardEvent('keydown', {
    key: 'Escape',
    keyCode: 27,
    bubbles: true
  }));
JS

# ✅ 대안: 닫기 버튼 직접 클릭
find("[data-action='modal#close']").click
```

### 예방 규칙
- **ESC 키 테스트**: `document.dispatchEvent` 사용
- **모달 테스트**: 닫기 버튼 클릭 방식 선호

---

## 3. Stimulus Controller 타이밍 (25% of failures)

### 증상
```
Element not found: "[data-controller='xxx']"
Unable to find element with the provided selector
```

### 원인
Stimulus 컨트롤러가 연결되기 전에 테스트가 요소를 찾으려고 시도.

### 잘못된 패턴
```ruby
# ❌ 금지: 컨트롤러 연결 대기 없이 바로 조작
visit some_path
find("[data-some-target='button']").click
```

### 올바른 패턴
```ruby
# ✅ 권장: 컨트롤러 연결 대기 후 조작
visit some_path
assert_selector "[data-controller='some']", wait: 5  # 컨트롤러 연결 대기
find("[data-some-target='button']").click

# ✅ 대안: 특정 상태 대기
assert_selector "[data-some-target='button']:not([disabled])", wait: 5
```

### 예방 규칙
- **페이지 방문 후**: `assert_selector "[data-controller='xxx']", wait: 5`
- **동적 요소**: `wait:` 옵션 항상 사용
- **타임아웃**: 기본 5초, 필요시 10초

---

## 4. Dropdown/Combobox 경쟁 조건 (15% of failures)

### 증상
```
Capybara::ElementNotFound: Unable to find option "..."
Element is not currently visible and may not be manipulated
```

### 원인
드롭다운 옵션이 렌더링되기 전에 선택 시도.

### 잘못된 패턴
```ruby
# ❌ 금지: 클릭 직후 바로 선택
find("[data-combobox-target='input']").click
select "옵션", from: "field"
```

### 올바른 패턴
```ruby
# ✅ 권장: 옵션 표시 대기
find("[data-combobox-target='input']").click
assert_selector "[data-combobox-target='option']", wait: 5
find("[data-combobox-target='option']", text: "옵션").click

# ✅ 대안: JavaScript로 직접 값 설정 (테스트 시간 단축)
page.execute_script(<<~JS)
  const input = document.querySelector('#field');
  input.value = '옵션값';
  input.dispatchEvent(new Event('change', { bubbles: true }));
JS
```

### 예방 규칙
- **드롭다운 클릭 후**: 옵션 표시 대기
- **커스텀 Combobox**: JavaScript 직접 조작 선호
- **Select2, TomSelect 등**: 라이브러리별 패턴 확인

---

## 5. 상태 오염 (State Pollution) (5% of failures)

### 증상
```
테스트 단독 실행 시 성공, 전체 실행 시 실패
Expected 1 but got 2
```

### 원인
이전 테스트의 데이터가 현재 테스트에 영향.

### 잘못된 패턴
```ruby
# ❌ 금지: 고정된 식별자 사용
test "creates comment" do
  fill_in "내용", with: "테스트 댓글"  # 다른 테스트와 충돌 가능
end
```

### 올바른 패턴
```ruby
# ✅ 권장: 유니크 식별자 사용
test "creates comment" do
  unique_text = "테스트 댓글 #{SecureRandom.hex(4)}"
  fill_in "내용", with: unique_text
  assert_text unique_text
end

# ✅ 권장: Time.now.to_i 사용
unique_title = "게시글 #{Time.now.to_i}"
```

### 예방 규칙
- **테스트 데이터**: `SecureRandom.hex(4)` 또는 `Time.now.to_i` 접미사
- **데이터 생성**: Fixture보다 `setup`에서 생성 선호
- **DB 정리**: `teardown`에서 생성 데이터 정리

---

## 6. JavaScript 클릭 vs Capybara 클릭 (5% of failures)

### 증상
```
Element is not clickable at point (x, y)
Other element would receive the click
```

### 원인
오버레이, z-index, 또는 요소 위치 문제로 Capybara 클릭 실패.

### 잘못된 패턴
```ruby
# ❌ 문제 발생 가능: Capybara 기본 클릭
find(".hidden-button").click
```

### 올바른 패턴
```ruby
# ✅ 권장: JavaScript 직접 클릭
page.execute_script("arguments[0].click()", find(".hidden-button"))

# ✅ 대안: 스크롤 후 클릭
button = find(".hidden-button")
page.execute_script("arguments[0].scrollIntoView({ block: 'center' })", button)
button.click
```

### 예방 규칙
- **숨겨진 요소**: JavaScript 클릭 사용
- **스크롤 필요**: `scrollIntoView` 먼저 실행
- **모달 내 버튼**: z-index 확인

---

## Quick Reference: CI 실패 디버깅

### 1단계: 에러 메시지 확인
```bash
gh run view <run-id> --log-failed
```

### 2단계: 패턴 매칭
| 에러 키워드 | 해당 패턴 |
|------------|----------|
| `StaleElementReferenceError` | #1 Stale Element |
| `keydown`, `Escape` | #2 ESC 키 |
| `data-controller`, `not found` | #3 Stimulus 타이밍 |
| `Unable to find option` | #4 Dropdown 경쟁 |
| `Expected X but got Y` | #5 상태 오염 |
| `not clickable` | #6 클릭 문제 |

### 3단계: 로컬 재현
```bash
# 특정 테스트만 실행
bin/rails test test/system/comments_test.rb:89

# 전체 System Test
bin/rails test:system

# 여러 번 실행 (간헐적 실패 확인)
for i in {1..5}; do bin/rails test test/system/comments_test.rb; done
```

### 4단계: 수정 후 검증
```bash
# Rubocop 검사
rubocop test/system/

# 전체 테스트 실행
bin/rails test
```

---

## 체크리스트: System Test 작성 시

```
☐ Turbo Stream 후 요소 재참조
☐ Stimulus 컨트롤러 연결 대기 (assert_selector wait: 5)
☐ 유니크 식별자 사용 (SecureRandom/Time.now)
☐ ESC 키는 document.dispatchEvent 사용
☐ 드롭다운 옵션 표시 대기
☐ 숨겨진 요소는 JavaScript 클릭
☐ 적절한 sleep 대신 assert_selector/assert_text wait 사용
```

---

## 관련 문서
- [Testing Standards](../testing/conventions.md)
- [Stimulus Patterns](../frontend/stimulus-patterns.md)
