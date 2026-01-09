import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright E2E Test Configuration
 *
 * 실행 방법:
 * - 전체 테스트: npx playwright test
 * - UI 모드: npx playwright test --ui
 * - 특정 브라우저: npx playwright test --project=chromium
 * - 특정 파일: npx playwright test toggle-buttons.spec.ts
 */
export default defineConfig({
  testDir: './e2e/tests',

  // 테스트 타임아웃 (30초)
  timeout: 30000,

  // expect 타임아웃 (5초)
  expect: {
    timeout: 5000
  },

  // 전체 테스트 타임아웃 (10분)
  globalTimeout: 600000,

  // 실패 시 재시도
  retries: process.env.CI ? 2 : 1,

  // 병렬 실행 워커 수
  workers: process.env.CI ? 1 : undefined,

  // 리포터 설정
  reporter: [
    ['html', { open: 'never' }],
    ['list']
  ],

  // 공통 설정
  use: {
    // Rails 개발 서버 URL
    baseURL: 'http://localhost:3000',

    // 실패 시 스크린샷
    screenshot: 'only-on-failure',

    // 실패 시 비디오
    video: 'retain-on-failure',

    // 실패 시 트레이스
    trace: 'retain-on-failure',

    // 뷰포트 크기
    viewport: { width: 1400, height: 900 },

    // 액션 타임아웃
    actionTimeout: 10000,

    // 네비게이션 타임아웃
    navigationTimeout: 15000,
  },

  // 브라우저 프로젝트
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    {
      name: 'mobile-chrome',
      use: { ...devices['Pixel 5'] },
    },
    {
      name: 'mobile-safari',
      use: { ...devices['iPhone 13'] },
    },
  ],

  // 테스트 전 Rails 서버 시작
  webServer: {
    command: 'bin/rails server -p 3000',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120000,
  },
});
