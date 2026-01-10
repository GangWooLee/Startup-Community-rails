import { test, expect } from '@playwright/test';
import { loginAs, waitForPageLoad, uploadTestImage } from '../utils/test-helpers';

/**
 * 채팅 이미지 E2E 테스트
 *
 * 채팅방에서 이미지 전송 기능 검증:
 * - 이미지 업로드 및 전송
 * - 전송된 이미지 표시 확인
 * - 이미지+텍스트 조합 메시지
 * - Active Storage URL 확인
 */

// 채팅 폼의 이미지 입력 셀렉터
const CHAT_IMAGE_INPUT = '[data-message-form-target="imageInput"]';

test.describe('채팅 이미지 전송', () => {
  // 채팅 테스트를 위한 테스트 데이터 설정 필요
  // 실제 테스트 환경에서는 테스트 사용자와 채팅방이 미리 생성되어 있어야 함

  test.beforeEach(async ({ page }) => {
    await loginAs(page);
  });

  test('채팅방에서 이미지 전송 후 표시 확인', async ({ page }) => {
    // 채팅방 목록으로 이동
    await page.goto('/chat_rooms');
    await waitForPageLoad(page);

    // 채팅방 목록에서 실제 채팅방 링크 찾기 (ID가 있는 링크만)
    // /chat_rooms/1, /chat_rooms/2 등의 패턴 (네비게이션의 /chat_rooms 제외)
    const chatRoomLink = page.locator('a[href*="/chat_rooms/"][href$="1"], a[href*="/chat_rooms/"][href$="2"], a[href*="/chat_rooms/"][href$="3"]').first();
    const hasChatRoom = await chatRoomLink.isVisible({ timeout: 3000 }).catch(() => false);

    if (!hasChatRoom) {
      test.skip(true, '테스트할 채팅방이 없습니다 (테스트 데이터 필요)');
      return;
    }

    await chatRoomLink.click();
    await waitForPageLoad(page);

    // 채팅 메시지 폼의 이미지 입력 찾기 (hidden 상태이지만 setInputFiles는 동작)
    const fileInput = page.locator(CHAT_IMAGE_INPUT);

    // 이미지 업로드
    await fileInput.setInputFiles('e2e/fixtures/test-image.png');

    // 전송 버튼 클릭
    const submitButton = page.locator('[data-message-form-target="button"]');
    await submitButton.click();

    // 이미지 메시지 표시 확인 (Active Storage URL 패턴)
    const imageMessage = page.locator('img[alt="첨부 이미지"]').last();
    await expect(imageMessage).toBeVisible({ timeout: 10000 });

    // Active Storage URL 확인
    const src = await imageMessage.getAttribute('src');
    expect(src).toMatch(/\/rails\/active_storage/);

    // 이미지가 실제로 로드되었는지 확인 (깨진 이미지 아닌지)
    const isLoaded = await imageMessage.evaluate((img: HTMLImageElement) => {
      return img.complete && img.naturalWidth > 0;
    });
    expect(isLoaded).toBe(true);
  });

  test('이미지+텍스트 조합 메시지 전송', async ({ page }) => {
    // 채팅방으로 이동
    await page.goto('/chat_rooms');
    await waitForPageLoad(page);

    const chatRoomLink = page.locator('a[href*="/chat_rooms/"][href$="1"], a[href*="/chat_rooms/"][href$="2"], a[href*="/chat_rooms/"][href$="3"]').first();
    const hasChatRoom = await chatRoomLink.isVisible({ timeout: 3000 }).catch(() => false);

    if (!hasChatRoom) {
      test.skip(true, '테스트할 채팅방이 없습니다 (테스트 데이터 필요)');
      return;
    }

    await chatRoomLink.click();
    await waitForPageLoad(page);

    // 이미지 업로드
    const fileInput = page.locator(CHAT_IMAGE_INPUT);
    await fileInput.setInputFiles('e2e/fixtures/test-image.png');

    // 텍스트 입력
    const textarea = page.locator('[data-message-form-target="input"]');
    const testMessage = `이미지와 함께 보내는 테스트 메시지 ${Date.now()}`;
    await textarea.fill(testMessage);

    // 전송
    const submitButton = page.locator('[data-message-form-target="button"]');
    await submitButton.click();

    // 메시지가 전송되었는지 확인
    await page.waitForTimeout(2000); // 메시지 전송 및 렌더링 대기

    // 최근 메시지에서 이미지와 텍스트 모두 확인
    const messages = page.locator('[id^="message_"]');
    const lastMessage = messages.last();

    // 이미지 확인
    const messageImage = lastMessage.locator('img');
    await expect(messageImage).toBeVisible({ timeout: 5000 });

    // 텍스트 확인
    await expect(lastMessage).toContainText(testMessage.substring(0, 20), { timeout: 5000 });
  });

  test('이미지 미리보기 표시 확인', async ({ page }) => {
    // 채팅방으로 이동
    await page.goto('/chat_rooms');
    await waitForPageLoad(page);

    const chatRoomLink = page.locator('a[href*="/chat_rooms/"][href$="1"], a[href*="/chat_rooms/"][href$="2"], a[href*="/chat_rooms/"][href$="3"]').first();
    const hasChatRoom = await chatRoomLink.isVisible({ timeout: 3000 }).catch(() => false);

    if (!hasChatRoom) {
      test.skip(true, '테스트할 채팅방이 없습니다 (테스트 데이터 필요)');
      return;
    }

    await chatRoomLink.click();
    await waitForPageLoad(page);

    // 이미지 업로드
    const fileInput = page.locator(CHAT_IMAGE_INPUT);
    await fileInput.setInputFiles('e2e/fixtures/test-image.png');

    // 미리보기 컨테이너가 표시되는지 확인
    const previewContainer = page.locator('[data-message-form-target="imagePreviewContainer"]');
    await expect(previewContainer).not.toHaveClass(/hidden/, { timeout: 5000 });

    // 미리보기 이미지가 표시되는지 확인
    const previewImage = page.locator('[data-message-form-target="imagePreview"]');
    await expect(previewImage).toBeVisible();
    await expect(previewImage).toHaveAttribute('src', /^data:image/);
  });
});
