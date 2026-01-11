import { Page, expect } from '@playwright/test';

/**
 * 테스트 헬퍼 함수들
 * Rails 앱의 E2E 테스트를 위한 공통 유틸리티
 */

// 테스트 사용자 정보
export const TEST_USER = {
  email: 'test@example.com',
  password: 'password123',
  name: '테스트 유저'
};

/**
 * 테스트 사용자 생성 (CI 환경용)
 * 테스트 환경에서 /test/create_user API를 호출하여 사용자 생성
 */
async function ensureTestUserExists(
  page: Page,
  email: string,
  password: string,
  name: string = '테스트 유저'
): Promise<void> {
  try {
    const response = await page.request.post('/test/create_user', {
      data: { email, password, name }
    });

    if (!response.ok()) {
      console.warn(`Failed to create test user: ${response.status()}`);
    }
  } catch (error) {
    // 라우트가 없는 경우 (개발 환경 등) 무시
    console.log('Test user creation skipped (route not available)');
  }
}

/**
 * 테스트 게시글 생성 (CI 환경용)
 * 테스트 환경에서 /test/create_post API를 호출하여 게시글 생성
 */
export async function createTestPost(
  page: Page,
  options: {
    title?: string;
    content?: string;
    userEmail?: string;
    postType?: 'community' | 'outsourcing';
  } = {}
): Promise<{ id: number; title: string } | null> {
  try {
    const response = await page.request.post('/test/create_post', {
      data: {
        title: options.title || '테스트 게시글',
        content: options.content || 'E2E 테스트를 위한 게시글입니다.',
        user_email: options.userEmail || TEST_USER.email,
        post_type: options.postType || 'community'
      }
    });

    if (response.ok()) {
      const data = await response.json();
      return data.post;
    } else {
      console.warn(`Failed to create test post: ${response.status()}`);
      return null;
    }
  } catch (error) {
    console.log('Test post creation skipped (route not available)');
    return null;
  }
}

/**
 * 이메일/비밀번호로 로그인
 */
export async function loginAs(
  page: Page,
  email: string = TEST_USER.email,
  password: string = TEST_USER.password
): Promise<void> {
  // CI 환경에서는 테스트 사용자를 먼저 생성
  if (process.env.CI) {
    await ensureTestUserExists(page, email, password);
  }

  await page.goto('/login');

  await page.fill('input[name="email"]', email);
  await page.fill('input[name="password"]', password);

  // JavaScript로 직접 폼 제출
  await page.evaluate(() => {
    const form = document.querySelector('form');
    if (form) form.submit();
  });

  // 네비게이션 완료 대기 (Turbo 사용 시 networkidle 필요)
  await page.waitForLoadState('networkidle', { timeout: 15000 });

  // 로그인 성공 확인 - URL이 /login이 아니면 성공
  const currentUrl = page.url();
  if (currentUrl.includes('/login')) {
    // 디버깅을 위한 추가 정보 로깅
    if (process.env.CI) {
      console.error(`Login failed. Email: ${email}, URL: ${currentUrl}`);
      const pageContent = await page.content();
      console.error(`Page contains error: ${pageContent.includes('error') || pageContent.includes('Error')}`);
    }
    throw new Error(`Login failed - still on login page. URL: ${currentUrl}`);
  }
}

/**
 * Remember Me 체크박스와 함께 로그인
 */
export async function loginWithRememberMe(
  page: Page,
  email: string = TEST_USER.email,
  password: string = TEST_USER.password
): Promise<void> {
  await page.goto('/login');

  await page.fill('input[name="email"]', email);
  await page.fill('input[name="password"]', password);

  // Remember Me 체크
  const checkbox = page.locator('input[name="remember_me"]');
  if (await checkbox.isVisible()) {
    await checkbox.check();
  }

  // JavaScript로 직접 폼 제출
  await page.evaluate(() => {
    const form = document.querySelector('form');
    if (form) form.submit();
  });

  // 네비게이션 완료 대기
  await page.waitForLoadState('networkidle', { timeout: 15000 });

  // 로그인 성공 확인
  const currentUrl = page.url();
  if (currentUrl.includes('/login')) {
    throw new Error(`Login with remember me failed - still on login page. URL: ${currentUrl}`);
  }
}

/**
 * 회원가입
 */
export async function signUp(
  page: Page,
  email: string,
  password: string,
  name: string
): Promise<void> {
  await page.goto('/signup');

  await page.fill('input[name="name"]', name);
  await page.fill('input[name="email"]', email);
  await page.fill('input[name="password"]', password);
  await page.fill('input[name="password_confirmation"]', password);

  // 약관 동의 (있는 경우)
  const termsCheckbox = page.locator('input[name="terms"]');
  if (await termsCheckbox.isVisible()) {
    await termsCheckbox.check();
  }

  // 회원가입 버튼 클릭
  await page.getByRole('button', { name: /회원가입|가입/ }).click();

  // 회원가입 성공 확인
  await expect(page).not.toHaveURL('/signup');
}

/**
 * 로그아웃
 */
export async function logout(page: Page): Promise<void> {
  // 사이드바의 사용자 버튼 클릭 (드롭다운 열기)
  const userButton = page.locator('button:has-text("@example.com")');
  if (await userButton.isVisible({ timeout: 3000 })) {
    await userButton.click();
    await page.waitForTimeout(300); // 드롭다운 애니메이션 대기
  }

  // 로그아웃 링크 클릭
  const logoutLink = page.locator('a[href="/logout"]');
  if (await logoutLink.isVisible({ timeout: 3000 })) {
    await logoutLink.click();
  } else {
    // 대안: 텍스트로 찾기
    await page.click('text=로그아웃');
  }

  // 로그인 페이지 또는 홈으로 리다이렉트
  await page.waitForURL(/\/(login|$)/, { timeout: 10000 });
}

/**
 * 로그인 상태 확인
 */
export async function isLoggedIn(page: Page): Promise<boolean> {
  // 사용자 이메일이 포함된 버튼이 있으면 로그인 상태
  // 사이드바의 사용자 버튼 확인
  const userButton = page.locator('button:has-text("@example.com")');
  const isUserButtonVisible = await userButton.isVisible({ timeout: 2000 }).catch(() => false);
  if (isUserButtonVisible) return true;

  // 대안: 로그인 환영 메시지 확인
  const welcomeMessage = page.locator('text=로그인되었습니다');
  return await welcomeMessage.isVisible({ timeout: 2000 }).catch(() => false);
}

/**
 * 플래시 메시지 확인
 */
export async function assertFlashMessage(
  page: Page,
  text: string,
  type: 'notice' | 'alert' = 'notice'
): Promise<void> {
  const flashSelector = type === 'notice'
    ? '.flash-notice, [role="alert"]:has-text("' + text + '")'
    : '.flash-alert, .flash-error, [role="alert"]:has-text("' + text + '")';

  await expect(page.locator(flashSelector).first()).toContainText(text);
}

/**
 * 모달 열림 확인
 */
export async function assertModalOpen(page: Page, modalId?: string): Promise<void> {
  const selector = modalId ? `#${modalId}` : '[role="dialog"], .modal';
  await expect(page.locator(selector).first()).toBeVisible();
}

/**
 * 모달 닫힘 확인
 */
export async function assertModalClosed(page: Page, modalId?: string): Promise<void> {
  const selector = modalId ? `#${modalId}` : '[role="dialog"], .modal';
  await expect(page.locator(selector).first()).not.toBeVisible();
}

/**
 * 페이지 로드 완료 대기 (Turbo 포함)
 */
export async function waitForPageLoad(page: Page): Promise<void> {
  // Turbo progress bar가 사라질 때까지 대기
  await page.waitForSelector('.turbo-progress-bar', { state: 'hidden' }).catch(() => {});
  // DOM 안정화 대기
  await page.waitForLoadState('domcontentloaded');
}

/**
 * 게시글 생성
 */
export async function createPost(
  page: Page,
  title: string,
  content: string,
  category: string = 'free'
): Promise<void> {
  await page.goto('/posts/new');

  await page.fill('input[name="post[title]"]', title);
  await page.fill('textarea[name="post[content]"]', content);

  // 카테고리 선택
  const categorySelect = page.locator('select[name="post[category]"]');
  if (await categorySelect.isVisible()) {
    await categorySelect.selectOption(category);
  }

  // 게시글 작성 버튼 클릭
  await page.getByRole('button', { name: /작성|등록|저장/ }).click();
  await page.waitForURL(/\/posts\/\d+/);
}

/**
 * 테스트 데이터 초기화용 타임스탬프
 */
export function uniqueId(): string {
  return Date.now().toString(36) + Math.random().toString(36).substring(2);
}

/**
 * 쿠키 확인
 */
export async function hasCookie(
  page: Page,
  name: string
): Promise<boolean> {
  const cookies = await page.context().cookies();
  return cookies.some(c => c.name === name);
}

/**
 * 특정 쿠키 가져오기
 */
export async function getCookie(
  page: Page,
  name: string
): Promise<{ name: string; value: string } | undefined> {
  const cookies = await page.context().cookies();
  return cookies.find(c => c.name === name);
}

/**
 * 세션 쿠키만 삭제 (Remember Me 쿠키 유지)
 */
export async function clearSessionCookie(page: Page): Promise<void> {
  const cookies = await page.context().cookies();
  const sessionCookies = cookies.filter(c =>
    c.name.includes('session') || c.name === '_startup_community_session'
  );

  for (const cookie of sessionCookies) {
    await page.context().clearCookies({ name: cookie.name });
  }
}

/**
 * 스크린샷 저장 (디버깅용)
 */
export async function debugScreenshot(page: Page, name: string): Promise<void> {
  await page.screenshot({
    path: `e2e/screenshots/${name}-${Date.now()}.png`,
    fullPage: true
  });
}

/**
 * 이미지 업로드 테스트 헬퍼
 */
export async function uploadTestImage(
  page: Page,
  fileInputSelector: string = 'input[type="file"]'
): Promise<void> {
  const fileInput = page.locator(fileInputSelector);
  await fileInput.setInputFiles('e2e/fixtures/test-image.png');
}

/**
 * 여러 이미지 업로드
 */
export async function uploadMultipleImages(
  page: Page,
  count: number,
  fileInputSelector: string = 'input[type="file"]'
): Promise<void> {
  const fileInput = page.locator(fileInputSelector);
  const files = Array(count).fill('e2e/fixtures/test-image.png');
  await fileInput.setInputFiles(files);
}

/**
 * alert 다이얼로그 핸들러 설정
 */
export function setupDialogHandler(
  page: Page,
  expectedMessage?: string
): Promise<string> {
  return new Promise((resolve) => {
    page.once('dialog', async (dialog) => {
      const message = dialog.message();
      if (expectedMessage) {
        expect(message).toContain(expectedMessage);
      }
      await dialog.accept();
      resolve(message);
    });
  });
}
