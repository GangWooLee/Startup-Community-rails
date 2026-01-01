# Drawbridge Workflow: 상세 가이드

> 이 문서는 Drawbridge 태스크 처리의 전체 워크플로우를 설명합니다.

## 핵심 원칙

당신은 전문 프론트엔드 엔지니어로서 시각적 피드백을 코드로 변환합니다:

- **의도 해석**: 문자 그대로가 아닌 사용자의 근본적인 목표 이해
- **컨벤션 준수**: 기존 패턴과 베스트 프랙티스 적용
- **일관성 유지**: 디자인 시스템과 코딩 규칙 엄수
- **품질 보장**: 깔끔하고 성능 좋은 접근성 있는 코드 생성

---

## 태스크 수집 및 세션 메모리

### 첫 단계: 파일 읽기

세션 시작 시 반드시 두 파일을 읽습니다:

```bash
# 진실의 원천 (상세 메타데이터)
cat moat-tasks-detail.json

# 인간 친화적 목록
cat moat-tasks.md
```

### JSON 파일 구조

```json
{
  "id": "4aa13cb3-7f02-451e-a7c5-fb5f11a0941c",
  "title": "Colored Container",
  "comment": "저 프로젝트의 대표 로고로 바꾸고 싶네요",
  "selector": "main.flex-1.flex > div.mb-8:nth-child(1) > div.rounded-2xl.bg-primary/10",
  "boundingRect": {"x": 680, "y": 297, "w": 64, "h": 64},
  "screenshotPath": "./screenshots/moat-1767235108271-k0rgelqww.png",
  "status": "to do"
}
```

### 스크린샷 경로 변환 (필수!)

```javascript
// JSON 경로 → 실제 파일 경로
const resolveScreenshotPath = (path) => {
  return path.replace(/^\.\/screenshots\//, '.moat/screenshots/')
             .replace(/^screenshots\//, '.moat/screenshots/');
};

// 예시
"./screenshots/moat-1234-abc.png" → ".moat/screenshots/moat-1234-abc.png"
```

---

## 의존성 감지

### 참조 지시어 패턴

**대명사 참조:**
- "that button", "this element", "the component"
- "it", "that one"

**설명적 참조:**
- "the blue button" (이전에 파란색으로 변경된 버튼)
- "the centered div" (이전에 중앙 정렬된 div)

**위치 참조:**
- "the button above", "the element below"
- "the left sidebar"

**순차 지시어:**
- "after": "after making it blue, center it"
- "then": "make it blue then move it"
- "once": "once it's styled, position it"

### 의존성 분석 예시

```
Task 1: "Make this button blue" → 생성: 파란 버튼
Task 2: "Move that blue button right" → 의존: Task 1
Task 3: "Add shadow to the blue button" → 의존: Task 1

결과: Task 1 먼저 완료 필요
```

### 의존성 그룹핑

- **독립 태스크**: 다른 태스크 참조 없음, 순서 무관
- **의존성 체인**: Task A → Task B → Task C (순차 필수)
- **병렬 의존성**: B와 C가 모두 A에 의존 (A 먼저, 그 다음 B&C 동시)

---

## 상태 순환 규칙

### 유효한 상태 전환

```
to do → doing → done
   ↓      ↓       ↑
   ↓      ↓    failed
   ↓   (retry)    ↓
   ↑←←←←←←←←←←←←←←↓
```

**허용 전환:**
- `to do` → `doing` (처리 시작)
- `doing` → `done` (성공 완료)
- `doing` → `failed` (처리 오류)
- `failed` → `to do` (재시도)
- `done` → `to do` (사용자 변경 요청)

**금지 전환:**
- ❌ `to do` → `done` (처리 건너뛰기)
- ❌ `done` → `doing` (완료 후 재처리)
- ❌ `done` → `failed` (성공 후 실패)

---

## 처리 모드 상세

### Mode 1: Step (증분 처리)

기본 안전 모드. 복잡한 태스크에 적합.

**워크플로우:**

1. **의존성 확인**: 선행 태스크 완료 여부 확인

2. **배치 시작** (한 번의 도구 호출):
   ```
   - moat-tasks-detail.json: "to do" → "doing"
   - 표준 템플릿으로 발표
   - 내부 TODO 업데이트
   ```

3. **구현**: 실제 코드 파일 수정

4. **배치 완료** (한 번의 도구 호출):
   ```
   - moat-tasks-detail.json: "doing" → "done"
   - moat-tasks.md: [ ] → [x]
   - 내부 TODO 업데이트
   ```

5. **승인 대기**: 검토 후 다음 진행

### Mode 2: Batch (그룹 처리)

효율성 모드. 관련 태스크를 그룹화.

**그룹핑 기준 (우선순위):**

1. **같은 선택자**: 동일 CSS 선택자 대상
2. **같은 컴포넌트**: 동일 컴포넌트 내 요소
3. **같은 파일**: 동일 CSS/컴포넌트 파일 수정
4. **같은 변경 유형**:
   - 스타일링: 색상, 폰트, 간격, 그림자
   - 레이아웃: 위치, 정렬, 크기
   - 콘텐츠: 텍스트 변경, 요소 추가/제거
5. **같은 시각 영역**: boundingRect 기준 200px 이내

**그룹 제외 기준:**
- 크로스 프레임워크 변경
- 파일 구조 변경
- 복잡한 상태 관리 변경

### Mode 3: YOLO (전체 자동)

가장 빠른 자율 모드. 승인 없이 전체 처리.

**워크플로우:**

```markdown
🚀 YOLO Mode: Processing 8 tasks in dependency order
⚙️ Dependency chains identified: 2 chains, 3 independent tasks
🔄 Estimated completion: ~2 minutes
```

1. 모든 태스크 의존성 분석 및 정렬
2. 순서대로 전체 처리
3. 실패 시 로그 후 계속 진행
4. 최종 결과 보고

---

## 표준 발표 템플릿

**모든 태스크에 이 형식 사용:**

```
🎯 Task {N}: "{exact comment from JSON}"
📍 {selector from JSON}
📸 {✅ Loaded | ⚠️ Missing}
{⚙️ Dependency: {info} - ✅ Satisfied | ⏸️ Waiting}
Implementing: {one-line approach summary}
✅ doing → done
```

**예시 (독립 태스크):**
```
🎯 Task 2: "Make this button blue"
📍 button.cta-primary
📸 ✅ Loaded
Implementing: Update background-color to var(--color-brand-blue)
✅ doing → done
```

**예시 (의존성 있음):**
```
🎯 Task 3: "Move that blue button to the right"
📍 button.cta-primary
📸 ✅ Loaded
⚙️ Dependency: Task 2 (blue button styling) - ✅ Satisfied
Implementing: Add margin-left: 2rem
✅ doing → done
```

---

## 프레임워크별 구현 패턴

### Rails + Tailwind + Stimulus (이 프로젝트)

**파일 탐색 우선순위:**
1. `app/views/**/*.html.erb` - 뷰 템플릿
2. `app/helpers/` - 뷰 헬퍼
3. `app/assets/stylesheets/` - CSS
4. `app/javascript/controllers/` - Stimulus

**Tailwind 클래스 수정:**
```erb
<%# 색상 변경 %>
<button class="bg-primary hover:bg-primary/90">

<%# 크기 변경 %>
<div class="px-4 py-2"> → <div class="px-6 py-3">

<%# 반응형 추가 %>
<div class="w-full md:w-1/2 lg:w-1/3">
```

**디자인 토큰 (DESIGN_SYSTEM.md 참조):**
```css
/* 색상 */
--color-primary, --color-secondary, --color-muted

/* 간격 */
--spacing-xs (0.25rem) ~ --spacing-xl (2rem)

/* 둥글기 */
--radius-sm, --radius-md, --radius-lg, --radius-full
```

### React/Next.js

**파일 우선순위:**
1. `styles/globals.css` 또는 `app/globals.css`
2. `components/[Name]/[Name].module.css`
3. `pages/` 또는 `app/` 디렉토리

**구현 예시:**
```jsx
<button className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
  Click me
</button>
```

### Vue.js

**파일 우선순위:**
1. `src/assets/css/` 또는 `src/styles/`
2. `src/components/[Name].vue`
3. `src/views/[View].vue`

**구현 예시:**
```vue
<template>
  <button :class="buttonClasses">{{ buttonText }}</button>
</template>

<style scoped>
.primary-button {
  background-color: var(--color-primary);
}
</style>
```

---

## UI 변경 패턴 라이브러리

### 색상 & 테마

- "Make this blue": 색상 토큰 `var(--color-brand-blue)` 우선
- "Use our brand color": CSS 변수에서 브랜드 색상 검색

### 레이아웃 & 간격

- "Center this": Flexbox `justify-content: center` 또는 `margin-inline: auto`
- "Add spacing": 간격 토큰 `var(--spacing-md)` 또는 `rem` 단위

### 타이포그래피

- "Make this text bigger": 폰트 사이즈 토큰 `var(--font-size-lg)`
- "Use the heading font": 헤딩 폰트 패밀리 적용

### 효과 & 폴리시

- "Add a shadow": 그림자 토큰 `var(--shadow-md)`
- "Round the corners": 둥글기 토큰 `var(--radius-lg)`

---

## 오류 처리

### 스크린샷 없음

```
⚠️ Screenshot not found: .moat/screenshots/moat-[id].png
→ Proceeding with selector and description only
→ Using: [selector] + "[comment]"
→ Request user confirmation if unclear
```

### 선택자 없음

```
❌ Issue: The selector for the "Submit Button" was not found.
Suggestion: The element may be dynamically rendered.
Could you provide a more specific selector or the component file name?
```

### 잘못된 상태 전환

```
❌ Status Transition Error
Current: done → Attempted: doing
→ Invalid: Cannot re-process done tasks
→ Suggestion: Reset to 'to do' first if changes needed
```

---

## 동시 업데이트 처리

Moat 확장 프로그램이 실시간 동기화할 수 있습니다:

```
ℹ️ Task file already synchronized by Moat extension
✅ Status tracking up-to-date - continuing with next task
```

**충돌 해결:**
1. 파일 재읽기로 현재 상태 확인
2. 현재 상태에 업데이트 적용
3. 오류 없이 진행

**업데이트 순서:**
1. 먼저: `moat-tasks-detail.json` (진실의 원천)
2. 그 다음: `moat-tasks.md` (인간 친화적 뷰)

---

## 커뮤니케이션 스타일

### 처리 중 (사용자 대기 중)
- **간결하게**: 속도 우선
- **표준 템플릿 사용**: 일관된 형식

### 오류 또는 불명확한 상황
- **상세하게**: 전체 컨텍스트와 조치 안내
- **포함**: 오류 상세, 영향 파일, 라인 번호, 제안 수정

### 첫 세션 또는 새 사용자
- **교육 모드**: 작업 내용과 이유 설명
- **패턴 가르치기**: 워크플로우 이해 도움

### 반복 세션
- **간결하게**: 설명 생략, 결과만 표시

---

**Version**: 1.0.0
**Based on**: .moat/drawbridge-workflow.md
**Last Updated**: 2026-01-01
