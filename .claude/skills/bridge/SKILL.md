---
description: Drawbridge UI 주석을 처리하여 코드 수정을 자동화하는 프론트엔드 엔지니어 스킬. moat-tasks-detail.json에서 태스크를 읽고, 스크린샷으로 시각적 컨텍스트를 파악하여 정확한 UI 수정을 수행합니다.
trigger_keywords:
  - bridge
  - drawbridge
  - moat tasks
  - process UI
  - UI annotations
  - 드로우브릿지
globs:
  - ".moat/**"
  - "**/moat-tasks.md"
  - "**/moat-tasks-detail.json"
alwaysApply: false
---

# Bridge Skill

Drawbridge 브라우저 확장 프로그램으로 생성된 UI 주석을 처리하여 코드 수정을 자동화합니다.

## 📋 처리 모드

| 모드 | 명령어 | 설명 |
|------|--------|------|
| **Step** | `/bridge` 또는 `/bridge step` | 하나씩 승인 받으며 처리 (기본값) |
| **Batch** | `/bridge batch` | 관련 태스크를 그룹화하여 처리 |
| **YOLO** | `/bridge yolo` | 전체 자동 처리 (승인 없음) |

## 🚀 Quick Start

```bash
# 1. 태스크 확인 (⚠️ 반드시 .moat/ 경로 사용!)
cat .moat/moat-tasks.md

# 2. 처리 시작
/bridge          # Step 모드 (기본)
/bridge batch    # Batch 모드
/bridge yolo     # YOLO 모드
```

## 📁 파일 구조 (⚠️ 중요!)

**모든 파일은 `.moat/` 디렉토리 내부에 있습니다!**

```
project/
└── .moat/                        # ← 이 디렉토리 안에 모든 파일!
    ├── moat-tasks.md             # 태스크 목록 (마크다운)
    ├── moat-tasks-detail.json    # 상세 메타데이터 (JSON) - 진실의 원천
    ├── screenshots/              # UI 스크린샷
    ├── config.json               # 설정
    └── README.md                 # 가이드
```

❌ **잘못된 경로**: `moat-tasks.md` (루트에 없음!)
✅ **올바른 경로**: `.moat/moat-tasks.md`

## 🔄 워크플로우

### 1단계: 태스크 로드
```markdown
1. moat-tasks-detail.json 읽기 (진실의 원천)
2. 스크린샷 경로 변환: ./screenshots/ → .moat/screenshots/
3. 의존성 분석 (태스크 간 참조 확인)
```

### 2단계: 태스크 처리
```markdown
🎯 Task {N}: "{comment}"
📍 {selector}
📸 {✅ Loaded | ⚠️ Missing}
{⚙️ Dependency: {info} - ✅ Satisfied | ⏸️ Waiting}
Implementing: {approach}
✅ doing → done
```

### 3단계: 상태 업데이트
```markdown
moat-tasks-detail.json: "to do" → "doing" → "done"
moat-tasks.md: [ ] → [x]
```

## ⚠️ 핵심 규칙

### 상태 순환 (반드시 준수)
```
to do → doing → done
```
- ❌ `to do` → `done` (스킵 금지)
- ❌ `done` → `doing` (재처리 금지)
- ✅ 실패 시: `doing` → `failed` → `to do`

### 스크린샷 경로 변환
```javascript
// JSON 상대 경로 → 실제 경로
"./screenshots/moat-xxx.png" → ".moat/screenshots/moat-xxx.png"
```

### 배치 처리 (효율성)
```markdown
OPERATION 1 (배치): JSON 상태 업데이트 + 발표
OPERATION 2: 코드 수정
OPERATION 3 (배치): JSON 완료 + MD 체크
= 3번 작업 (6번 아님)
```

## 📚 상세 레퍼런스

자세한 워크플로우와 프레임워크별 구현 패턴:
- [reference/workflow.md](reference/workflow.md) - 전체 워크플로우 가이드

## 🎨 이 프로젝트 적용

### Rails + Tailwind + Stimulus 패턴

**파일 우선순위:**
1. `app/views/**/*.html.erb` - 뷰 템플릿
2. `app/assets/stylesheets/` - CSS 파일
3. `app/javascript/controllers/` - Stimulus 컨트롤러

**Tailwind 클래스 수정:**
```erb
<%# Before %>
<button class="px-4 py-2 bg-primary">

<%# After (Drawbridge 주석: "버튼 크기 증가") %>
<button class="px-6 py-3 bg-primary">
```

**디자인 토큰 사용:**
```css
/* 프로젝트 토큰 활용 */
--color-primary     /* 브랜드 색상 */
--radius-lg         /* 모서리 둥글기 */
--spacing-md        /* 간격 */
```

## 🔍 의존성 감지 패턴

**참조 지시어:**
- "that button", "the blue element" → 이전 태스크 참조
- "after", "then", "once" → 순차 처리 필요

**그룹핑 기준:**
1. 같은 선택자 → 함께 처리
2. 같은 컴포넌트 → 함께 처리
3. 같은 변경 유형 (색상, 레이아웃 등)

## ⚡ 자동 모드 선택

`/bridge` 실행 시 태스크 분석 후 자동 선택:

| 조건 | 선택 모드 |
|------|----------|
| 1-5개, 혼합 유형 | Step |
| 6개+, 같은 파일 | Batch |
| 명시적 요청만 | YOLO |

---

**Version**: 1.0.0
**Compatible with**: Drawbridge Chrome Extension
**Last Updated**: 2026-01-01
