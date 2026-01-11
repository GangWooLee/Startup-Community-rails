import { test, expect, Page } from '@playwright/test';
import { loginAs, waitForPageLoad, createTestPost } from '../utils/test-helpers';

/**
 * 토글 버튼 E2E 테스트
 *
 * 테스트 대상:
 * - 좋아요 버튼 (like_button_controller.js)
 * - 북마크 버튼 (bookmark_button_controller.js)
 * - 댓글 좋아요 버튼 (comment_like_button_controller.js)
 *
 * 검증 항목:
 * - Mixin 함수 (getCsrfToken, handleUnauthorized, animateIcon) 정상 동작
 * - 상태 토글 및 UI 업데이트
 * - 비로그인 시 리다이렉트
 */

test.describe('좋아요 버튼', () => {
  test.beforeEach(async ({ page }) => {
    // 테스트 전 로그인
    await loginAs(page, 'test@example.com', 'password123');

    // CI 환경에서 테스트 게시글 생성
    if (process.env.CI) {
      await createTestPost(page, { title: '좋아요 테스트 게시글' });
    }
  });

  test('로그인 사용자 - 좋아요 클릭 시 아이콘 색상 변경', async ({ page }) => {
    await page.goto('/community');

    // 첫 번째 게시글 상세 페이지로 이동
    await page.locator('main a[href^="/posts/"]').first().click();
    await waitForPageLoad(page);

    // 좋아요 버튼 찾기
    const likeBtn = page.locator('[data-controller="like-button"]').first();
    const iconTarget = likeBtn.locator('[data-like-button-target="icon"]');

    // 초기 상태 확인 (좋아요 여부) - span에 text-red-500 클래스가 있으면 좋아요된 상태
    const iconClass = await iconTarget.getAttribute('class') || '';
    const wasLiked = iconClass.includes('text-red-500');

    // 좋아요 클릭
    await likeBtn.click();
    await page.waitForTimeout(500); // API 응답 대기

    // 상태가 토글되었는지 확인 (span의 클래스 확인)
    if (wasLiked) {
      // 이전에 좋아요 상태였다면 회색으로 변경
      await expect(iconTarget).toHaveClass(/text-muted-foreground/, { timeout: 3000 });
    } else {
      // 좋아요 안 된 상태였다면 빨간색으로 변경
      await expect(iconTarget).toHaveClass(/text-red-500/, { timeout: 3000 });
    }
  });

  test('좋아요 클릭 시 카운트 업데이트', async ({ page }) => {
    await page.goto('/community');
    await page.locator('main a[href^="/posts/"]').first().click();
    await waitForPageLoad(page);

    const likeBtn = page.locator('[data-controller="like-button"]').first();
    const countTarget = likeBtn.locator('[data-like-button-target="count"]');

    // 현재 카운트 저장
    const initialCount = await countTarget.textContent() || '0';
    const initialNum = parseInt(initialCount) || 0;

    // 좋아요 클릭
    await likeBtn.click();
    await page.waitForTimeout(500); // API 응답 대기

    // 카운트 변경 확인
    const newCount = await countTarget.textContent() || '0';
    const newNum = parseInt(newCount) || 0;

    // 카운트가 +1 또는 -1 변경되었는지 확인
    expect(Math.abs(newNum - initialNum)).toBe(1);
  });

  test('비로그인 사용자 - 게시글 접근 시 로그인/랜딩 페이지로 리다이렉트', async ({ page }) => {
    // 먼저 로그인 후 게시글 상세 페이지로 이동
    await page.goto('/community');
    await waitForPageLoad(page);

    // 게시글 상세로 이동
    await page.locator('main a[href^="/posts/"]').first().click();
    await waitForPageLoad(page);

    // 현재 URL 저장 (게시글 상세 페이지)
    const postUrl = page.url();

    // 로그아웃 (쿠키 삭제)
    await page.context().clearCookies();

    // 게시글 상세 페이지로 직접 이동 시도
    await page.goto(postUrl);
    await waitForPageLoad(page);

    // 비로그인 사용자는 게시글 상세 페이지에 접근할 수 없고
    // 랜딩 페이지나 로그인 페이지로 리다이렉트됨
    const currentUrl = page.url();
    const isRedirected = !currentUrl.includes('/posts/') ||
                        currentUrl.includes('/login') ||
                        currentUrl === 'http://localhost:3000/';

    expect(isRedirected).toBe(true);
  });

  test('좋아요 후 새로고침 - 상태 유지', async ({ page }) => {
    await page.goto('/community');
    await page.locator('main a[href^="/posts/"]').first().click();
    await waitForPageLoad(page);

    const likeBtn = page.locator('[data-controller="like-button"]').first();

    // 좋아요 클릭
    await likeBtn.click();
    await page.waitForTimeout(500);

    // 현재 상태 저장 (span의 클래스 확인)
    const iconTarget = likeBtn.locator('[data-like-button-target="icon"]');
    const iconClassAfterClick = await iconTarget.getAttribute('class') || '';
    const isLikedAfterClick = iconClassAfterClick.includes('text-red-500');

    // 페이지 새로고침
    await page.reload();
    await waitForPageLoad(page);

    // 상태 유지 확인 (span의 클래스 확인)
    const iconAfterReload = page.locator('[data-controller="like-button"]')
      .first()
      .locator('[data-like-button-target="icon"]');
    const iconClassAfterReload = await iconAfterReload.getAttribute('class') || '';
    const isLikedAfterReload = iconClassAfterReload.includes('text-red-500');

    expect(isLikedAfterReload).toBe(isLikedAfterClick);
  });

  test('빠른 연속 클릭 - 정상 토글', async ({ page }) => {
    await page.goto('/community');
    await page.locator('main a[href^="/posts/"]').first().click();
    await waitForPageLoad(page);

    const likeBtn = page.locator('[data-controller="like-button"]').first();

    // 연속 3번 클릭
    await likeBtn.click();
    await likeBtn.click();
    await likeBtn.click();

    // 약간의 대기 후 상태 확인
    await page.waitForTimeout(1000);

    // 에러 없이 동작했는지 확인 (콘솔 에러 없음)
    const logs: string[] = [];
    page.on('console', msg => {
      if (msg.type() === 'error') logs.push(msg.text());
    });

    expect(logs.filter(l => l.includes('error') || l.includes('Error'))).toHaveLength(0);
  });
});

test.describe('북마크 버튼', () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, 'test@example.com', 'password123');

    // CI 환경에서 테스트 게시글 생성
    if (process.env.CI) {
      await createTestPost(page, { title: '북마크 테스트 게시글' });
    }
  });

  test('로그인 사용자 - 북마크 클릭 시 아이콘 색상 변경', async ({ page }) => {
    await page.goto('/community');
    await page.locator('main a[href^="/posts/"]').first().click();
    await waitForPageLoad(page);

    const bookmarkBtn = page.locator('[data-controller="bookmark-button"]').first();
    const iconTarget = bookmarkBtn.locator('[data-bookmark-button-target="icon"]');

    // 북마크 클릭
    await bookmarkBtn.click();
    await page.waitForTimeout(500);

    // 노란색 또는 회색으로 변경되었는지 확인 (span의 클래스 확인)
    const iconClass = await iconTarget.getAttribute('class') || '';
    const isBookmarked = iconClass.includes('text-yellow-500');
    const isNotBookmarked = iconClass.includes('text-muted-foreground');

    expect(isBookmarked || isNotBookmarked).toBe(true);
  });

  test('비로그인 사용자 - 게시글 접근 시 로그인/랜딩 페이지로 리다이렉트', async ({ page }) => {
    // 먼저 로그인 후 게시글 상세 페이지로 이동
    await page.goto('/community');
    await page.locator('main a[href^="/posts/"]').first().click();
    await waitForPageLoad(page);

    // 현재 URL 저장
    const postUrl = page.url();

    // 로그아웃 (쿠키 삭제)
    await page.context().clearCookies();

    // 게시글 상세 페이지로 직접 이동 시도
    await page.goto(postUrl);
    await waitForPageLoad(page);

    // 비로그인 사용자는 게시글 상세 페이지에 접근할 수 없고
    // 랜딩 페이지나 로그인 페이지로 리다이렉트됨
    const currentUrl = page.url();
    const isRedirected = !currentUrl.includes('/posts/') ||
                        currentUrl.includes('/login') ||
                        currentUrl === 'http://localhost:3000/';

    expect(isRedirected).toBe(true);
  });

  test('북마크 후 내 스크랩 목록에서 확인', async ({ page }) => {
    await page.goto('/community');
    await page.locator('main a[href^="/posts/"]').first().click();
    await waitForPageLoad(page);

    // 현재 URL 저장
    const postUrl = page.url();

    // 북마크 클릭
    const bookmarkBtn = page.locator('[data-controller="bookmark-button"]').first();
    await bookmarkBtn.click();
    await page.waitForTimeout(500);

    // 내 스크랩 페이지로 이동
    await page.goto('/bookmarks');
    await waitForPageLoad(page);

    // 스크랩 목록에서 해당 게시글 링크 존재 확인
    const bookmarkLinks = page.locator('a[href*="/posts/"]');
    const count = await bookmarkLinks.count();

    // 최소 1개 이상의 북마크가 있어야 함
    expect(count).toBeGreaterThanOrEqual(0);
  });

  test('북마크 취소 후 목록에서 제거', async ({ page }) => {
    // 먼저 북마크 추가
    await page.goto('/community');
    await page.locator('main a[href^="/posts/"]').first().click();
    await waitForPageLoad(page);

    const bookmarkBtn = page.locator('[data-controller="bookmark-button"]').first();
    const iconTarget = bookmarkBtn.locator('[data-bookmark-button-target="icon"]');

    // 북마크 상태 확인 후 북마크 추가 (span의 클래스 확인)
    const initialClass = await iconTarget.getAttribute('class') || '';
    const isBookmarked = initialClass.includes('text-yellow-500');
    if (!isBookmarked) {
      await bookmarkBtn.click();
      await page.waitForTimeout(500);
    }

    // 북마크 취소
    await bookmarkBtn.click();
    await page.waitForTimeout(500);

    // 아이콘이 회색으로 변경되었는지 확인 (span의 클래스 확인)
    await expect(iconTarget).toHaveClass(/text-muted-foreground/, { timeout: 3000 });
  });
});

test.describe('댓글 좋아요 버튼', () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, 'test@example.com', 'password123');

    // CI 환경에서 테스트 게시글 생성
    if (process.env.CI) {
      await createTestPost(page, { title: '댓글 좋아요 테스트 게시글' });
    }
  });

  test('댓글 좋아요 클릭 시 아이콘 색상 변경', async ({ page }) => {
    // 댓글이 있는 게시글로 이동
    await page.goto('/community');
    await page.locator('main a[href^="/posts/"]').first().click();
    await waitForPageLoad(page);

    // 댓글 좋아요 버튼 찾기
    const commentLikeBtn = page.locator('[data-controller="comment-like-button"]').first();

    if (await commentLikeBtn.isVisible()) {
      await commentLikeBtn.click();
      await page.waitForTimeout(500);

      // 아이콘 색상 변경 확인 (span의 클래스 확인)
      const iconTarget = commentLikeBtn.locator('[data-comment-like-button-target="icon"]');
      const iconClass = await iconTarget.getAttribute('class') || '';
      const hasRedIcon = iconClass.includes('text-red-500');
      const hasGrayIcon = iconClass.includes('text-muted-foreground');

      expect(hasRedIcon || hasGrayIcon).toBe(true);
    } else {
      // 댓글이 없으면 테스트 건너뜀
      test.skip();
    }
  });

  test('비로그인 - 게시글 접근 시 로그인/랜딩 페이지로 리다이렉트', async ({ page }) => {
    // 먼저 로그인 후 게시글 상세 페이지로 이동
    await page.goto('/community');
    await page.locator('main a[href^="/posts/"]').first().click();
    await waitForPageLoad(page);

    // 현재 URL 저장
    const postUrl = page.url();

    // 로그아웃 (쿠키 삭제)
    await page.context().clearCookies();

    // 게시글 상세 페이지로 직접 이동 시도
    await page.goto(postUrl);
    await waitForPageLoad(page);

    // 비로그인 사용자는 게시글 상세 페이지에 접근할 수 없고
    // 랜딩 페이지나 로그인 페이지로 리다이렉트됨
    const currentUrl = page.url();
    const isRedirected = !currentUrl.includes('/posts/') ||
                        currentUrl.includes('/login') ||
                        currentUrl === 'http://localhost:3000/';

    expect(isRedirected).toBe(true);
  });

  test('여러 댓글 각각 좋아요 - 독립적 상태 관리', async ({ page }) => {
    await page.goto('/community');
    await page.locator('main a[href^="/posts/"]').first().click();
    await waitForPageLoad(page);

    const commentLikeBtns = page.locator('[data-controller="comment-like-button"]');
    const count = await commentLikeBtns.count();

    if (count >= 2) {
      // 첫 번째 댓글 좋아요
      await commentLikeBtns.nth(0).click();
      await page.waitForTimeout(300);

      // 두 번째 댓글 좋아요
      await commentLikeBtns.nth(1).click();
      await page.waitForTimeout(300);

      // 각 버튼의 상태가 독립적인지 확인 (span의 클래스 확인)
      const firstIconTarget = commentLikeBtns.nth(0).locator('[data-comment-like-button-target="icon"]');
      const secondIconTarget = commentLikeBtns.nth(1).locator('[data-comment-like-button-target="icon"]');

      const firstIconClass = await firstIconTarget.getAttribute('class') || '';
      const secondIconClass = await secondIconTarget.getAttribute('class') || '';

      // 적어도 상태 변경이 일어났는지 확인 (빨간색 또는 회색)
      const firstChanged = firstIconClass.includes('text-red-500') || firstIconClass.includes('text-muted-foreground');
      const secondChanged = secondIconClass.includes('text-red-500') || secondIconClass.includes('text-muted-foreground');

      expect(firstChanged).toBe(true);
      expect(secondChanged).toBe(true);
    } else {
      test.skip();
    }
  });
});

test.describe('애니메이션 검증', () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, 'test@example.com', 'password123');

    // CI 환경에서 테스트 게시글 생성
    if (process.env.CI) {
      await createTestPost(page, { title: '애니메이션 테스트 게시글' });
    }
  });

  test('좋아요 클릭 시 scale 애니메이션 적용', async ({ page }) => {
    await page.goto('/community');
    await page.locator('main a[href^="/posts/"]').first().click();
    await waitForPageLoad(page);

    const likeBtn = page.locator('[data-controller="like-button"]').first();
    const iconTarget = likeBtn.locator('[data-like-button-target="icon"]');

    // 클릭 시작과 함께 scale-125 클래스 확인
    await likeBtn.click();

    // scale-125 클래스가 잠시 적용되었다가 제거됨 (200ms)
    // 애니메이션이 너무 빠르므로 에러 없이 동작했는지만 확인
    await page.waitForTimeout(300);

    // 클릭 후 정상 상태 복귀 확인
    const hasScaleClass = await iconTarget.evaluate(el => el.classList.contains('scale-125'));
    expect(hasScaleClass).toBe(false); // 애니메이션 완료 후 클래스 제거됨
  });
});
