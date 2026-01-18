/**
 * Undrew Design System - Tailwind Configuration
 * Ported from: https://github.com/GangWooLee/Undrew-design
 */

const defaultTheme = require("tailwindcss/defaultTheme");

module.exports = {
  darkMode: ["class"],
  content: [
    "./public/*.html",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/views/**/*.{erb,haml,html,slim}",
  ],
  // ============================================================
  // Safelist: CDN → 빌드 CSS 전환 시 필요한 임의값 클래스
  // 이 클래스들은 JIT 컴파일러가 자동 감지하지 못하므로 명시적 등록 필요
  // ============================================================
  safelist: [
    // ========== 색상 (헥스코드) ==========
    // 배경색
    "bg-[#2C2825]", "bg-[#FDFBF7]", "bg-[#FEE500]", "bg-[#1877F2]",
    "bg-[#F9FAFB]", "bg-[#F3F4F6]", "bg-[#E5E7EB]", "bg-[#D1D5DB]",
    "bg-[#9CA3AF]", "bg-[#6B7280]", "bg-[#4B5563]", "bg-[#374151]",
    "bg-[#1F2937]", "bg-[#111827]", "bg-[#F0F9FF]", "bg-[#DBEAFE]",
    "bg-[#BFDBFE]", "bg-[#93C5FD]", "bg-[#60A5FA]", "bg-[#3B82F6]",
    "bg-[#2563EB]", "bg-[#1D4ED8]", "bg-[#1E40AF]", "bg-[#1E3A8A]",
    "bg-[#FEF2F2]", "bg-[#FEE2E2]", "bg-[#FECACA]", "bg-[#FCA5A5]",
    "bg-[#F87171]", "bg-[#EF4444]", "bg-[#DC2626]", "bg-[#B91C1C]",
    "bg-[#F0FDF4]", "bg-[#DCFCE7]", "bg-[#BBF7D0]", "bg-[#86EFAC]",
    "bg-[#4ADE80]", "bg-[#22C55E]", "bg-[#16A34A]", "bg-[#15803D]",
    "bg-[#FFFBEB]", "bg-[#FEF3C7]", "bg-[#FDE68A]", "bg-[#FCD34D]",
    "bg-[#FBBF24]", "bg-[#F59E0B]", "bg-[#D97706]", "bg-[#B45309]",
    "bg-[#FDF4FF]", "bg-[#FAE8FF]", "bg-[#F5D0FE]", "bg-[#E879F9]",
    "bg-[#D946EF]", "bg-[#C026D3]", "bg-[#A855F7]", "bg-[#9333EA]",
    "bg-[#24292F]", "bg-[#333333]", "bg-[#4285F4]", "bg-[#34A853]",
    "bg-[#FBBC05]", "bg-[#EA4335]", "bg-[#DB4437]", "bg-[#F4B400]",
    "bg-[#0F9D58]", "bg-[#f5f5f5]", "bg-[#e0e0e0]", "bg-[#757575]",
    "bg-[#333]", "bg-[#fff]", "bg-[#fafafa]",
    // 텍스트색
    "text-[#2C2825]", "text-[#FDFBF7]", "text-[#4B5563]", "text-[#6B7280]",
    "text-[#9CA3AF]", "text-[#D1D5DB]", "text-[#E5E7EB]", "text-[#F3F4F6]",
    "text-[#F9FAFB]", "text-[#1F2937]", "text-[#111827]", "text-[#374151]",
    "text-[#3B82F6]", "text-[#EF4444]", "text-[#22C55E]", "text-[#F59E0B]",
    "text-[#333]", "text-[#fff]", "text-[#000]", "text-[#666]",
    "text-[#999]", "text-[#ccc]", "text-[#24292F]",
    // 테두리색
    "border-[#2C2825]", "border-[#FDFBF7]", "border-[#E5E7EB]", "border-[#D1D5DB]",
    "border-[#9CA3AF]", "border-[#6B7280]", "border-[#4B5563]", "border-[#374151]",
    "border-[#3B82F6]", "border-[#EF4444]", "border-[#22C55E]", "border-[#F59E0B]",
    "border-[#FEE500]", "border-[#1877F2]", "border-[#24292F]", "border-[#333]",
    // from/via/to (그라데이션)
    "from-[#2C2825]", "from-[#FDFBF7]", "from-[#3B82F6]", "from-[#8B5CF6]",
    "from-[#EC4899]", "from-[#EF4444]", "from-[#F59E0B]", "from-[#10B981]",
    "via-[#8B5CF6]", "via-[#EC4899]", "via-[#F59E0B]", "via-[#3B82F6]",
    "to-[#EC4899]", "to-[#F59E0B]", "to-[#10B981]", "to-[#3B82F6]",
    "to-[#8B5CF6]", "to-[#EF4444]", "to-[#FDFBF7]", "to-[#transparent]",
    // 링 색상
    "ring-[#3B82F6]", "ring-[#EF4444]", "ring-[#22C55E]", "ring-[#F59E0B]",
    "ring-[#2C2825]", "ring-[#FEE500]", "ring-[#1877F2]",
    // placeholder 색상
    "placeholder-[#9CA3AF]", "placeholder-[#6B7280]",
    // 투명도 포함 색상
    "bg-[#2C2825]/5", "bg-[#2C2825]/10", "bg-[#2C2825]/20", "bg-[#2C2825]/50",
    "bg-[#2C2825]/80", "bg-[#2C2825]/90", "bg-[#FDFBF7]/80", "bg-[#FDFBF7]/90",
    "bg-[#3B82F6]/10", "bg-[#3B82F6]/20", "bg-[#EF4444]/10", "bg-[#22C55E]/10",
    "bg-black/5", "bg-black/10", "bg-black/20", "bg-black/30", "bg-black/40",
    "bg-black/50", "bg-black/60", "bg-black/70", "bg-black/80", "bg-white/80",
    "bg-white/90", "bg-white/95", "text-[#2C2825]/60", "text-[#2C2825]/80",

    // ========== Z-index ==========
    "z-[1]", "z-[2]", "z-[5]", "z-[10]", "z-[20]", "z-[30]", "z-[40]",
    "z-[50]", "z-[60]", "z-[70]", "z-[80]", "z-[90]", "z-[100]",
    "z-[999]", "z-[1000]", "z-[9999]", "z-[-1]", "z-[-10]",

    // ========== Blur ==========
    "blur-[50px]", "blur-[80px]", "blur-[100px]", "blur-[120px]", "blur-[150px]",
    "blur-[200px]", "backdrop-blur-[10px]", "backdrop-blur-[20px]",

    // ========== 크기 (고정값) ==========
    // 너비
    "w-[1px]", "w-[2px]", "w-[4px]", "w-[6px]", "w-[8px]", "w-[10px]",
    "w-[12px]", "w-[14px]", "w-[16px]", "w-[18px]", "w-[20px]", "w-[24px]",
    "w-[28px]", "w-[32px]", "w-[36px]", "w-[40px]", "w-[48px]", "w-[56px]",
    "w-[64px]", "w-[72px]", "w-[80px]", "w-[96px]", "w-[120px]", "w-[150px]",
    "w-[180px]", "w-[200px]", "w-[240px]", "w-[280px]", "w-[300px]", "w-[320px]",
    "w-[360px]", "w-[400px]", "w-[480px]", "w-[560px]", "w-[640px]",
    // 높이
    "h-[1px]", "h-[2px]", "h-[4px]", "h-[6px]", "h-[8px]", "h-[10px]",
    "h-[12px]", "h-[14px]", "h-[16px]", "h-[18px]", "h-[20px]", "h-[24px]",
    "h-[28px]", "h-[32px]", "h-[36px]", "h-[40px]", "h-[48px]", "h-[56px]",
    "h-[64px]", "h-[72px]", "h-[80px]", "h-[96px]", "h-[120px]", "h-[150px]",
    "h-[180px]", "h-[200px]", "h-[240px]", "h-[280px]", "h-[300px]", "h-[320px]",
    "h-[360px]", "h-[400px]", "h-[480px]", "h-[560px]", "h-[640px]",
    // min/max 크기
    "min-w-[200px]", "min-w-[240px]", "min-w-[280px]", "min-w-[320px]",
    "max-w-[320px]", "max-w-[400px]", "max-w-[480px]", "max-w-[560px]",
    "max-w-[640px]", "max-w-[720px]", "max-w-[800px]", "max-w-[960px]",
    "min-h-[200px]", "min-h-[300px]", "min-h-[400px]", "min-h-[500px]",
    "max-h-[200px]", "max-h-[300px]", "max-h-[400px]", "max-h-[500px]",
    "max-h-[600px]", "max-h-[80vh]", "max-h-[90vh]",

    // ========== 크기 (clamp - 반응형) ==========
    "w-[clamp(3rem,8vw,4rem)]", "w-[clamp(200px,50vw,400px)]",
    "w-[clamp(280px,80vw,560px)]", "w-[clamp(300px,90vw,600px)]",
    "h-[clamp(200px,30vh,280px)]", "h-[clamp(250px,40vh,320px)]",
    "h-[clamp(300px,50vh,400px)]", "h-[clamp(150px,25vh,200px)]",
    "text-[clamp(1rem,2vw,1.25rem)]", "text-[clamp(1.5rem,4vw,2.5rem)]",
    "text-[clamp(2rem,5vw,3rem)]", "text-[clamp(2.5rem,6vw,4rem)]",
    "gap-[clamp(0.5rem,2vw,1rem)]", "gap-[clamp(1rem,3vw,2rem)]",
    "p-[clamp(1rem,3vw,2rem)]", "p-[clamp(1.5rem,4vw,3rem)]",
    "py-[clamp(2rem,8vw,4rem)]", "px-[clamp(1rem,4vw,2rem)]",

    // ========== 위치 ==========
    "top-[0]", "top-[1px]", "top-[2px]", "top-[4px]", "top-[8px]",
    "top-[50%]", "top-[100%]", "top-[-1px]", "top-[-4px]",
    "left-[0]", "left-[1px]", "left-[2px]", "left-[4px]", "left-[8px]",
    "left-[50%]", "left-[100%]", "left-[-1px]", "left-[-4px]",
    "right-[0]", "right-[1px]", "right-[2px]", "right-[4px]", "right-[8px]",
    "right-[50%]", "right-[100%]", "right-[-1px]", "right-[-4px]",
    "bottom-[0]", "bottom-[1px]", "bottom-[2px]", "bottom-[4px]", "bottom-[8px]",
    "bottom-[50%]", "bottom-[100%]", "bottom-[-1px]", "bottom-[-4px]",
    "inset-[0]", "inset-x-[0]", "inset-y-[0]",
    "translate-x-[-50%]", "translate-y-[-50%]", "-translate-x-1/2", "-translate-y-1/2",

    // ========== 간격 ==========
    "gap-[2px]", "gap-[4px]", "gap-[6px]", "gap-[8px]", "gap-[10px]",
    "gap-[12px]", "gap-[16px]", "gap-[20px]", "gap-[24px]", "gap-[32px]",
    "space-x-[4px]", "space-x-[8px]", "space-x-[12px]", "space-x-[16px]",
    "space-y-[4px]", "space-y-[8px]", "space-y-[12px]", "space-y-[16px]",
    "p-[2px]", "p-[4px]", "p-[6px]", "p-[8px]", "p-[10px]", "p-[12px]",
    "px-[2px]", "px-[4px]", "px-[6px]", "px-[8px]", "px-[10px]", "px-[12px]",
    "py-[2px]", "py-[4px]", "py-[6px]", "py-[8px]", "py-[10px]", "py-[12px]",
    "m-[2px]", "m-[4px]", "m-[8px]", "m-[-2px]", "m-[-4px]", "m-[-8px]",
    "mx-[auto]", "my-[auto]",

    // ========== 테두리 ==========
    "border-[0.5px]", "border-[1px]", "border-[1.5px]", "border-[2px]",
    "border-[3px]", "border-[4px]",
    "rounded-[2px]", "rounded-[4px]", "rounded-[6px]", "rounded-[8px]",
    "rounded-[10px]", "rounded-[12px]", "rounded-[16px]", "rounded-[20px]",
    "rounded-[24px]", "rounded-[32px]", "rounded-[50%]",

    // ========== 폰트 ==========
    "text-[10px]", "text-[11px]", "text-[12px]", "text-[13px]", "text-[14px]",
    "text-[15px]", "text-[16px]", "text-[18px]", "text-[20px]", "text-[24px]",
    "text-[28px]", "text-[32px]", "text-[36px]", "text-[40px]", "text-[48px]",
    "leading-[1]", "leading-[1.2]", "leading-[1.4]", "leading-[1.5]",
    "leading-[1.6]", "leading-[1.8]", "leading-[2]",
    "tracking-[-0.02em]", "tracking-[-0.01em]", "tracking-[0.02em]",
    "tracking-[0.05em]", "tracking-[0.1em]",

    // ========== 그림자 ==========
    "shadow-[0_1px_2px_rgba(0,0,0,0.05)]",
    "shadow-[0_2px_4px_rgba(0,0,0,0.1)]",
    "shadow-[0_4px_6px_rgba(0,0,0,0.1)]",
    "shadow-[0_10px_15px_rgba(0,0,0,0.1)]",
    "shadow-[0_20px_25px_rgba(0,0,0,0.15)]",
    "shadow-[inset_0_2px_4px_rgba(0,0,0,0.05)]",

    // ========== 애니메이션 ==========
    "animate-[fadeIn_0.2s_ease]", "animate-[fadeIn_0.3s_ease]",
    "animate-[fadeIn_0.5s_ease]", "animate-[slideUp_0.3s_ease]",
    "animate-[slideDown_0.3s_ease]", "animate-[pulse_2s_infinite]",
    "animate-[spin_1s_linear_infinite]", "animate-[bounce_1s_infinite]",
    "duration-[50ms]", "duration-[100ms]", "duration-[150ms]",
    "duration-[200ms]", "duration-[250ms]", "duration-[300ms]",
    "duration-[400ms]", "duration-[500ms]", "duration-[700ms]",
    "delay-[50ms]", "delay-[100ms]", "delay-[150ms]", "delay-[200ms]",
    "delay-[300ms]", "delay-[500ms]",

    // ========== 변환 ==========
    "scale-[0.95]", "scale-[0.98]", "scale-[1.02]", "scale-[1.05]",
    "rotate-[15deg]", "rotate-[45deg]", "rotate-[90deg]", "rotate-[180deg]",
    "rotate-[-15deg]", "rotate-[-45deg]", "rotate-[-90deg]",
    "skew-x-[3deg]", "skew-y-[3deg]",

    // ========== 그리드 ==========
    "grid-cols-[repeat(auto-fill,minmax(200px,1fr))]",
    "grid-cols-[repeat(auto-fill,minmax(250px,1fr))]",
    "grid-cols-[repeat(auto-fill,minmax(300px,1fr))]",
    "grid-cols-[repeat(auto-fit,minmax(200px,1fr))]",
    "grid-cols-[repeat(auto-fit,minmax(250px,1fr))]",
    "grid-cols-[repeat(auto-fit,minmax(300px,1fr))]",
    "grid-rows-[auto_1fr_auto]", "grid-rows-[1fr_auto]",

    // ========== 스크롤 ==========
    "scroll-m-[20px]", "scroll-p-[20px]",
    "scrollbar-thin", "scrollbar-none",

    // ========== 기타 유틸리티 ==========
    "aspect-[16/9]", "aspect-[4/3]", "aspect-[1/1]", "aspect-[3/2]",
    "line-clamp-[2]", "line-clamp-[3]", "line-clamp-[4]", "line-clamp-[5]",
    "columns-[2]", "columns-[3]", "columns-[4]",
    "order-[1]", "order-[2]", "order-[3]", "order-[-1]",
    "flex-[1]", "flex-[2]", "flex-[0_0_auto]",
    "basis-[100px]", "basis-[200px]", "basis-[50%]",
    "grow-[1]", "grow-[2]", "shrink-[0]", "shrink-[1]",
  ],
  theme: {
    container: {
      center: true,
      padding: "2rem",
      screens: {
        "2xl": "1400px",
      },
    },
    extend: {
      fontFamily: {
        // CDN 설정과 동일하게 Montserrat + Nanum Gothic Coding 사용
        sans: ["'Montserrat'", "'Nanum Gothic Coding'", "sans-serif"],
        serif: ["'Montserrat'", "'Nanum Gothic Coding'", "serif"],
      },
      colors: {
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        "input-background": "hsl(var(--input-background))",
        "switch-background": "hsl(var(--switch-background))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        success: {
          DEFAULT: "hsl(var(--success))",
          foreground: "hsl(var(--success-foreground))",
        },
        info: {
          DEFAULT: "hsl(var(--info))",
          foreground: "hsl(var(--info-foreground))",
        },
        attention: {
          DEFAULT: "hsl(var(--attention))",
          foreground: "hsl(var(--attention-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
        sidebar: {
          DEFAULT: "hsl(var(--sidebar))",
          foreground: "hsl(var(--sidebar-foreground))",
          primary: "hsl(var(--sidebar-primary))",
          "primary-foreground": "hsl(var(--sidebar-primary-foreground))",
          accent: "hsl(var(--sidebar-accent))",
          "accent-foreground": "hsl(var(--sidebar-accent-foreground))",
          border: "hsl(var(--sidebar-border))",
          ring: "hsl(var(--sidebar-ring))",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
        xl: "calc(var(--radius) + 4px)",
      },
      keyframes: {
        "accordion-down": {
          from: { height: 0 },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: 0 },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/aspect-ratio"),
    require("@tailwindcss/typography"),
    require("@tailwindcss/container-queries"),
    require("tailwindcss-animate"),
  ],
};
