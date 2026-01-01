---
description: 독특하고 프로덕션급 프론트엔드 인터페이스를 고품질 디자인으로 생성합니다. 웹 컴포넌트, 페이지, 애플리케이션 빌드 시 사용하세요. 제네릭한 AI 미학을 피하고 창의적이고 세련된 코드를 생성합니다.
trigger_keywords:
  - frontend design
  - design component
  - beautiful UI
  - create landing page
  - make it pretty
  - improve design
  - design system
  - visual design
  - 예쁘게
  - 디자인 개선
globs:
  - "app/views/**/*.html.erb"
  - "app/assets/stylesheets/**/*.css"
  - "app/javascript/**/*.js"
alwaysApply: false
---

# Frontend Design Skill

> Anthropic 공식 frontend-design 스킬 기반
> 출처: [anthropics/claude-code/plugins/frontend-design](https://github.com/anthropics/claude-code/tree/main/plugins/frontend-design)

## 핵심 원칙

**"명확한 컨셉 방향을 선택하고 정밀하게 실행하라"**

LLM은 통계적 패턴에 기반해 토큰을 예측합니다. 방향 없이는 고확률 중심부에서 샘플링하여 "AI 슬롭"을 생성합니다. 이 스킬은 대담한 디자인 결정을 유도합니다.

---

## 구현 전 분석 (필수)

코딩 전 다음을 평가:

### 1. 목적 & 대상
- 이 인터페이스가 해결하는 문제는?
- 사용자 베이스는 누구인가?

### 2. 톤 선택 (하나를 강하게 선택)
| 톤 | 특징 |
|-----|------|
| Brutally Minimal | 극도로 절제된, 화이트 스페이스 |
| Maximalist Chaos | 풍부한 레이어, 과감한 색상 |
| Retro-Futuristic | 복고 + 미래, 네온/그라디언트 |
| Organic/Natural | 자연스러운 곡선, 어스톤 |
| Luxury/Refined | 고급스러운, 섬세한 타이포 |
| Playful/Toy-like | 장난스러운, 애니메이션 |
| Editorial/Magazine | 매거진 스타일 레이아웃 |
| Brutalist/Raw | 원초적, 거친 테두리 |
| Art Deco/Geometric | 기하학적, 대칭적 |

### 3. 차별화 요소
- 이 디자인을 잊을 수 없게 만드는 단 하나의 요소는?

---

## 디자인 가이드라인

### Typography
```css
/* ❌ 피할 것 */
font-family: Inter, Arial, Roboto, sans-serif;

/* ✅ 사용할 것 - 독특하고 아름다운 폰트 */
font-family: 'Playfair Display', serif;  /* Display */
font-family: 'Noto Sans KR', sans-serif; /* Body - 한글 */
```

**규칙**:
- 제네릭 폰트(Inter, Arial, Roboto) 피하기
- Display 폰트 + Body 폰트 페어링
- 한글: Pretendard, Noto Sans KR, Spoqa Han Sans

### Color & Theme

```css
/* ❌ 피할 것 - 자주색 그라디언트 */
background: linear-gradient(to-r, purple-500, pink-500);

/* ✅ 사용할 것 - 대담한 색상 결정 */
:root {
  --dominant: #0F172A;      /* 지배적 색상 */
  --accent: #F97316;        /* 강렬한 악센트 */
  --surface: #FEFCE8;       /* 표면 */
}
```

**규칙**:
- 소심한 균등 분배 팔레트 ❌
- 지배적 색상 + 강렬한 악센트 ✅
- CSS 변수로 일관성 유지

### Motion & Animation

```css
/* ✅ 고영향 순간에 집중 */
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}

.card {
  animation: fadeIn 0.6s ease-out;
  animation-delay: calc(var(--index) * 0.1s);
}
```

**규칙**:
- CSS 전용 애니메이션 우선 (HTML)
- 페이지 로드 시 스태거드 리빌 효과
- 분산된 마이크로인터랙션보다 조화로운 연출

### Spatial Composition

```erb
<%# ✅ 비대칭, 오버랩, 대각선 흐름 %>
<div class="relative">
  <div class="absolute -left-10 -top-10 w-40 h-40 bg-primary/10 rounded-full blur-3xl"></div>
  <div class="relative z-10 grid grid-cols-2 gap-0">
    <div class="col-span-1 -mr-8 z-20">...</div>
    <div class="col-span-1 mt-12">...</div>
  </div>
</div>
```

**규칙**:
- 요소 오버랩 활용
- 대각선 흐름
- 그리드 브레이킹
- 여유로운 또는 통제된 네거티브 스페이스

### Atmospheric Details

```erb
<%# ✅ 깊이감 있는 레이어링 %>
<div class="relative overflow-hidden">
  <%# 그라디언트 메시 배경 %>
  <div class="absolute inset-0 bg-gradient-to-br from-primary/5 via-transparent to-accent/10"></div>

  <%# 노이즈 텍스처 %>
  <div class="absolute inset-0 opacity-30" style="background-image: url('data:image/svg+xml,...')"></div>

  <%# 콘텐츠 %>
  <div class="relative z-10">...</div>
</div>
```

**요소**:
- 그라디언트 메시
- 노이즈 텍스처
- 기하학적 패턴
- 레이어드 투명도
- 섬세한 그림자
- 장식적 보더
- 그레인 오버레이

---

## 이 프로젝트에 적용

### Tailwind CSS v4 토큰 활용

```erb
<%# 프로젝트 색상 변수 사용 %>
<button class="bg-primary text-primary-foreground hover:bg-primary/90">
  ...
</button>

<%# 일관된 간격 %>
<div class="space-y-6 p-8">
  ...
</div>
```

### 컴포넌트 디자인 체크리스트

| 항목 | 확인 |
|------|------|
| 톤 결정됨? | □ |
| 폰트 독특함? | □ |
| 색상 대담함? | □ |
| 애니메이션 포함? | □ |
| 레이어링 적용? | □ |
| 제네릭 피함? | □ |

---

## Anti-Patterns (절대 하지 말 것)

| ❌ 피할 것 | ✅ 대안 |
|-----------|---------|
| Inter, Roboto, Arial 폰트 | Playfair, Pretendard, 독특한 폰트 |
| 자주색 그라디언트 | 브랜드 컬러 기반 팔레트 |
| 예측 가능한 레이아웃 | 비대칭, 오버랩 |
| 균등 분배 색상 | 지배적 색상 + 악센트 |
| "쿠키커터" 디자인 | 컨텍스트 특화 캐릭터 |

---

## 구현 복잡도 매칭

**원칙**: 코드 복잡도는 미학적 비전에 맞춰야 함

| 디자인 스타일 | 구현 요구사항 |
|--------------|---------------|
| Maximalist | 정교한 애니메이션, 다층 레이어 |
| Minimalist | 타이포그래픽 정밀도, 절제된 코드 |
| Playful | 마이크로인터랙션, 호버 효과 |
| Luxury | 섬세한 디테일, 완벽한 간격 |

---

**Version**: 1.0.0
**Based on**: [Anthropic Official Frontend Design Skill](https://github.com/anthropics/claude-code/blob/main/plugins/frontend-design/skills/frontend-design/SKILL.md)
**Last Updated**: 2026-01-01
