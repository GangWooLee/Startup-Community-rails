import { test, expect } from '@playwright/test';
import {
  loginAs,
  waitForPageLoad,
  uploadTestImage,
  uploadMultipleImages,
  setupDialogHandler
} from '../utils/test-helpers';

/**
 * 이미지 업로드 E2E 테스트
 *
 * 게시물 작성 시 이미지 업로드 기능 검증:
 * - 파일 선택으로 이미지 업로드
 * - 미리보기 표시
 * - 카운터 업데이트
 * - 5장 제한
 * - 이미지 삭제
 */

// 게시물 작성 폼의 이미지 업로드 입력 셀렉터 (Stimulus target 기반)
const POST_IMAGE_INPUT = '[data-image-upload-target="input"]';

test.describe('게시물 이미지 업로드', () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page);
    await page.goto('/posts/new');
    await waitForPageLoad(page);
  });

  test('파일 선택으로 이미지 업로드 시 미리보기 표시', async ({ page }) => {
    // 이미지 업로드 (구체적인 셀렉터 사용)
    await uploadTestImage(page, POST_IMAGE_INPUT);

    // FileReader가 비동기로 이미지를 로드하므로 충분한 대기 시간 필요
    await page.waitForTimeout(1000);

    // 미리보기 이미지 표시 확인 - 먼저 DOM에 존재하는지 확인
    const previewImage = page.locator('[data-image-upload-target="preview"] img').first();
    await expect(previewImage).toBeAttached({ timeout: 5000 });

    // 스크롤하여 뷰포트에 보이게 함
    await previewImage.scrollIntoViewIfNeeded();
    await expect(previewImage).toBeVisible({ timeout: 5000 });

    // 이미지 alt 텍스트 확인 (접근성)
    await expect(previewImage).toHaveAttribute('alt', '업로드 이미지 미리보기');
  });

  test('이미지 업로드 후 카운터 업데이트', async ({ page }) => {
    // 카운터 초기값 확인
    const counter = page.locator('[data-image-upload-target="counter"]');

    // 이미지 업로드
    await uploadTestImage(page, POST_IMAGE_INPUT);

    // 카운터가 1/5로 업데이트되었는지 확인
    await expect(counter.first()).toContainText('1/5', { timeout: 5000 });
  });

  test('여러 이미지 업로드 시 카운터 업데이트', async ({ page }) => {
    // 3장 업로드
    await uploadMultipleImages(page, 3, POST_IMAGE_INPUT);

    // 카운터 확인
    const counter = page.locator('[data-image-upload-target="counter"]');
    await expect(counter.first()).toContainText('3/5', { timeout: 5000 });

    // 미리보기 이미지 3개 확인
    const previewImages = page.locator('[data-image-upload-target="preview"] img');
    await expect(previewImages).toHaveCount(3, { timeout: 5000 });
  });

  test('5장 초과 시 경고 표시', async ({ page }) => {
    // 다이얼로그 핸들러 설정
    const dialogPromise = setupDialogHandler(page, '최대');

    // 6장 시도 업로드
    await uploadMultipleImages(page, 6, POST_IMAGE_INPUT);

    // 경고 다이얼로그 표시 확인
    const dialogMessage = await dialogPromise;
    expect(dialogMessage).toContain('최대');

    // 5장만 업로드됨 확인
    const counter = page.locator('[data-image-upload-target="counter"]');
    await expect(counter.first()).toContainText('5/5', { timeout: 5000 });
  });

  test('이미지 삭제 버튼 클릭 시 이미지 제거', async ({ page }) => {
    // 이미지 업로드
    await uploadTestImage(page, POST_IMAGE_INPUT);

    // FileReader 비동기 로딩 대기
    await page.waitForTimeout(1000);

    // 미리보기 확인
    const previewImage = page.locator('[data-image-upload-target="preview"] img').first();
    await expect(previewImage).toBeAttached({ timeout: 5000 });
    await previewImage.scrollIntoViewIfNeeded();
    await expect(previewImage).toBeVisible({ timeout: 5000 });

    // 삭제 버튼 클릭
    const deleteButton = page.locator('[data-action="click->image-upload#removeNewImage"]').first();
    await deleteButton.scrollIntoViewIfNeeded();
    await deleteButton.click();

    // 미리보기가 사라졌는지 확인
    await expect(page.locator('[data-image-upload-target="preview"] img')).toHaveCount(0, { timeout: 5000 });

    // 카운터가 0/5로 업데이트되었는지 확인
    const counter = page.locator('[data-image-upload-target="counter"]');
    await expect(counter.first()).toContainText('0/5');
  });

  test('이미지 삭제 버튼 접근성 속성 확인', async ({ page }) => {
    // 이미지 업로드
    await uploadTestImage(page, POST_IMAGE_INPUT);

    // FileReader 비동기 로딩 대기
    await page.waitForTimeout(1000);

    // 삭제 버튼 확인
    const deleteButton = page.locator('[data-action="click->image-upload#removeNewImage"]').first();
    await expect(deleteButton).toBeAttached({ timeout: 5000 });
    await deleteButton.scrollIntoViewIfNeeded();
    await expect(deleteButton).toBeVisible({ timeout: 5000 });

    // 접근성 속성 확인
    await expect(deleteButton).toHaveAttribute('type', 'button');
    await expect(deleteButton).toHaveAttribute('aria-label', '이미지 삭제');
  });

  test('5장 업로드 후 dropzone 숨김', async ({ page }) => {
    // dropzone 초기 표시 확인
    const dropzone = page.locator('[data-image-upload-target="dropzone"]');

    // 5장 업로드
    await uploadMultipleImages(page, 5, POST_IMAGE_INPUT);

    // dropzone이 숨겨졌는지 확인 (첫 번째 dropzone)
    await expect(dropzone.first()).toHaveClass(/hidden/, { timeout: 5000 });
  });

  test('이미지 삭제 후 dropzone 다시 표시', async ({ page }) => {
    // 5장 업로드
    await uploadMultipleImages(page, 5, POST_IMAGE_INPUT);

    // FileReader 비동기 로딩 대기
    await page.waitForTimeout(1500);

    const dropzone = page.locator('[data-image-upload-target="dropzone"]');
    await expect(dropzone.first()).toHaveClass(/hidden/, { timeout: 5000 });

    // 1장 삭제
    const deleteButton = page.locator('[data-action="click->image-upload#removeNewImage"]').first();
    await deleteButton.scrollIntoViewIfNeeded();
    await deleteButton.click();

    // 삭제 처리 대기
    await page.waitForTimeout(500);

    // dropzone 다시 표시
    await expect(dropzone.first()).not.toHaveClass(/hidden/, { timeout: 5000 });
  });
});
