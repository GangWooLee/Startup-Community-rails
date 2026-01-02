# UI Components Library - Phase 7.1

**프로덕션급 고급 UI 컴포넌트** (Sheet, Toast, Popover)

## 디자인 철학

### Refined/Professional 톤
- **스타트업 커뮤니티에 적합한 세련되고 전문적인 느낌**
- 부드러운 애니메이션과 섬세한 디테일
- 깊이감 있는 레이어링 (그라디언트, 블러 효과)
- IBM Plex Serif 폰트 유지

### 차별화 요소
✅ **제네릭 디자인 탈피** - Inter/Roboto 같은 평범한 스타일 피하기
✅ **레이어드 깊이감** - 그라디언트 메시, 블러 효과, 섬세한 그림자
✅ **의도적인 애니메이션** - 스태거드 리빌, 스프링 효과
✅ **undrew-design 토큰 완벽 통합** - 일관된 색상 시스템

---

## 1. Sheet Component (Slide Panel)

### 파일
- **Stimulus Controller**: `app/javascript/controllers/sheet_controller.js`
- **ERB Partial**: `app/views/components/ui/_sheet.html.erb`

### 기능
- 오른쪽/왼쪽/위/아래에서 슬라이드 인 (모바일 반응형)
- Backdrop blur 효과
- 키보드 접근성 (Escape, Tab trap)
- 포커스 관리 (자동 포커스, 복원)
- Body 스크롤 lock
- 부드러운 스프링 애니메이션

### 사용법

```erb
<%= render "components/ui/sheet",
           title: "프로필 상세",
           side: "right",
           id: "profile-sheet",
           closable: true do %>
  <div class="space-y-4">
    <p>콘텐츠...</p>
  </div>
<% end %>
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `title` | String | required | 헤더 제목 |
| `side` | String | `"right"` | `"right"`, `"left"`, `"top"`, `"bottom"` |
| `id` | String | auto-generated | Unique identifier |
| `closable` | Boolean | `true` | 닫기 버튼 표시 여부 |

### Use Cases
- 프로필 상세 보기
- 설정 패널
- 채팅 사이드바
- 필터 패널

---

## 2. Toast Component (Notifications)

### 파일
- **Stimulus Controller**: `app/javascript/controllers/toast_controller.js`

### 기능
- **4가지 variant**: success, error, warning, info
- **스택 관리**: 최대 3개 표시, 자동 대기열
- **아이콘 + 메시지 + 액션** 구조
- **진행 바**: 자동 dismiss 전까지 시간 표시
- **스태거드 애니메이션**: 순차적 리빌 (50ms delay)
- **XSS 안전**: textContent, createElementNS 사용

### 사용법

```javascript
// 기본 사용
ToastManager.show("success", "저장되었습니다!")

// 옵션 포함
ToastManager.show("error", "오류가 발생했습니다", {
  duration: 5000,
  action: "재시도",
  onAction: () => {
    console.log("Retry clicked")
  }
})
```

### Variants

| Variant | Color | Icon | Use Case |
|---------|-------|------|----------|
| `success` | Green | check-circle | 성공 메시지 |
| `error` | Red | x-circle | 오류 메시지 |
| `warning` | Yellow | exclamation-triangle | 경고 메시지 |
| `info` | Blue | information-circle | 정보 메시지 |

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `duration` | Number | `3000` | 자동 dismiss 시간 (ms) |
| `action` | String | `null` | 액션 버튼 텍스트 |
| `onAction` | Function | `null` | 액션 버튼 클릭 콜백 |

### Use Cases
- 폼 제출 성공/실패
- 데이터 저장 확인
- 에러 메시지
- 일시적 알림

---

## 3. Popover Component

### 파일
- **Stimulus Controller**: `app/javascript/controllers/popover_controller.js`
- **ERB Partial**: `app/views/components/ui/_popover.html.erb`

### 기능
- **자동 위치 조정**: Viewport edge detection
- **화살표 포인터**: 트리거 방향 지시
- **4방향 배치**: top, bottom, left, right, auto
- **외부 클릭 감지**: 자동 닫기
- **Escape 키 지원**
- **Window resize 대응**: 실시간 위치 재계산

### 사용법

```erb
<%= render "components/ui/popover",
           trigger_text: "더보기",
           placement: "auto",
           id: "actions-popover" do %>
  <ul class="space-y-2">
    <li class="px-2 py-1 hover:bg-muted rounded cursor-pointer">편집</li>
    <li class="px-2 py-1 hover:bg-muted rounded cursor-pointer">공유</li>
    <li class="px-2 py-1 hover:bg-muted rounded cursor-pointer text-destructive">삭제</li>
  </ul>
<% end %>
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `trigger_text` | String | required | 트리거 버튼 텍스트 |
| `placement` | String | `"auto"` | `"auto"`, `"top"`, `"bottom"`, `"left"`, `"right"` |
| `offset` | Number | `8` | 트리거와 팝오버 간격 (px) |
| `id` | String | auto-generated | Unique identifier |
| `close_on_outside_click` | Boolean | `true` | 외부 클릭 시 닫기 |
| `trigger_class` | String | `null` | 커스텀 트리거 버튼 클래스 |

### Placement Algorithm

1. **4방향 공간 측정**: 상하좌우 여유 공간 계산
2. **우선순위 전략**: 세로 배치(top/bottom) 우선 → 가독성
3. **Fallback**: 공간이 부족하면 가장 넓은 방향 선택
4. **Viewport Constraint**: 화면 밖으로 나가지 않도록 보정 (8px margin)

### Use Cases
- 유저 카드 미리보기
- 액션 메뉴 (더보기)
- 폼 도움말 툴팁
- 컨텍스트 정보

---

## Component Comparison

| Component | Position | Dismissal | Use Case | Keyboard |
|-----------|----------|-----------|----------|----------|
| **Sheet** | 화면 측면/하단 (고정) | Backdrop, Escape | 상세 정보, 설정 | Tab trap |
| **Toast** | 우측 상단 (고정) | 자동 (3초), 수동 | 일시적 알림 | - |
| **Popover** | 트리거 근처 (동적) | 외부 클릭, Escape | 메뉴, 카드 | Escape |

---

## Accessibility Features

### 모든 컴포넌트 공통
✅ **ARIA 속성**: role, aria-modal, aria-hidden, aria-expanded
✅ **키보드 네비게이션**: Escape, Tab, Enter
✅ **포커스 관리**: 자동 포커스, 복원
✅ **prefers-reduced-motion**: 애니메이션 제거 지원

### Sheet 특화
- **Tab Trap**: 포커스가 Sheet 내부에만 순환
- **aria-modal="true"**: 모달 다이얼로그로 인식

### Toast 특화
- **aria-live="polite"**: 스크린 리더가 중단 없이 읽음
- **aria-atomic="true"**: 전체 메시지 읽기

### Popover 특화
- **aria-haspopup="true"**: 팝업 존재 알림
- **aria-controls**: 트리거와 콘텐츠 연결

---

## Design Tokens Usage

### 색상
```css
--background, --foreground
--primary, --primary-foreground
--muted, --muted-foreground
--border, --card
--destructive
```

### 간격
- **padding**: `p-4`, `p-6`, `p-8`
- **gap**: `gap-2`, `gap-3`, `gap-4`
- **rounded**: `rounded-lg`, `rounded-full`

### 그림자
- **sheet**: `shadow-2xl`
- **popover**: `shadow-xl`
- **toast**: `shadow-lg`

---

## Browser Support

- **Modern Browsers**: Chrome, Firefox, Safari, Edge (최신 2버전)
- **Mobile**: iOS Safari 14+, Chrome Android 90+
- **IE11**: 지원 안 함 (Stimulus 요구사항)

---

## Performance Considerations

### Sheet
- **Body Scroll Lock**: `overflow: hidden` (메모리 효율적)
- **Lazy Rendering**: 열릴 때까지 DOM에서 숨김 상태

### Toast
- **Stack Management**: 최대 3개로 제한 (메모리 누수 방지)
- **Auto Cleanup**: dismiss 후 DOM에서 완전 제거

### Popover
- **Position Calculation**: `requestAnimationFrame` 사용
- **Resize Throttling**: Window resize 이벤트 최적화 필요 (추후 개선)

---

## Security

### XSS 방지
✅ **Toast**: `textContent` 사용, `innerHTML` 금지
✅ **모든 컴포넌트**: 사용자 입력 sanitization 필요
✅ **SVG**: `createElementNS` 사용 (안전한 DOM API)

### Code Injection 방지
✅ **Toast**: 동적 코드 평가 함수 사용 안 함
✅ **콜백 저장**: Function reference로 직접 저장

---

## Testing Recommendations

### Unit Tests (Stimulus Controllers)
```javascript
// sheet_controller.test.js
test("opens sheet on button click", async () => {
  const controller = application.getControllerForElementAndIdentifier(element, "sheet")
  controller.open()
  expect(controller.isOpen).toBe(true)
})
```

### Integration Tests (System Tests)
```ruby
# test/system/ui_components_test.rb
test "shows toast notification" do
  visit root_path
  execute_script("ToastManager.show('success', 'Test message')")
  assert_selector ".toast-base.toast-enter", text: "Test message"
end
```

---

## Migration from Admin Slide Panel

기존 관리자 페이지의 `admin/shared/_slide_panel.html.erb`를 새 Sheet 컴포넌트로 마이그레이션할 수 있습니다:

```erb
<%# Before (Old Admin Slide Panel) %>
<%= render "admin/shared/slide_panel", title: "상세 정보" do %>
  ...
<% end %>

<%# After (New Sheet Component) %>
<%= render "components/ui/sheet", title: "상세 정보", side: "right" do %>
  ...
<% end %>
```

---

## Future Enhancements

### Phase 7.2+
- [ ] 아이콘 시스템 통일 (Lucide Icons, icon 헬퍼)
- [ ] Popover resize throttling 최적화
- [ ] Toast 위치 커스터마이징 (top-left, bottom-right 등)
- [ ] Sheet 드래그하여 닫기 (모바일)
- [ ] Popover 호버 트리거 지원

---

**Version**: 1.0.0
**Created**: 2026-01-02
**Based on**: [Anthropic Frontend Design Skill](https://github.com/anthropics/claude-code/tree/main/plugins/frontend-design)
**Design System**: undrew-design tokens
