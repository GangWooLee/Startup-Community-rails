import { test, expect, Page } from '@playwright/test';
import { waitForPageLoad } from '../utils/test-helpers';

/**
 * AI 아이디어 분석 - 태그 입력 UI 테스트
 *
 * 이 테스트는 AI 아이디어 분석 플로우에서 추가 질문에 대한
 * 태그 입력 UI가 올바르게 동작하는지 검증합니다.
 *
 * 테스트 시나리오:
 * 1. 아이디어 입력 -> 추가 질문 화면 전환
 * 2. 예시 버튼 클릭 -> 태그로 변환
 * 3. 태그 × 클릭 -> 태그 제거, 버튼 복귀
 * 4. 여러 예시 선택 -> 모두 태그로 표시
 * 5. 필수 필드 입력 시 -> 제출 버튼 활성화
 */

// 테스트용 아이디어
const TEST_IDEA = '대학생들이 스터디 그룹을 만들고 관리할 수 있는 앱';

test.describe('AI 아이디어 분석 - 태그 입력 UI', () => {
  // LLM API 호출 대기 시간 (최대 30초)
  const LLM_TIMEOUT = 30000;

  /**
   * 추가 질문 화면까지 이동하는 헬퍼 함수
   */
  async function navigateToFollowUpQuestions(page: Page): Promise<void> {
    // AI 입력 페이지로 이동
    await page.goto('/ai/input');
    await waitForPageLoad(page);

    // 아이디어 입력 (실제 target 이름은 'textarea')
    const ideaInput = page.locator('textarea[data-ai-input-target="textarea"]');
    await expect(ideaInput).toBeVisible({ timeout: 5000 });
    await ideaInput.fill(TEST_IDEA);

    // "다음" 버튼 클릭 (send-button-premium 클래스)
    const nextButton = page.locator('button[data-ai-input-target="submitButton"]');
    await expect(nextButton).toBeEnabled();
    await nextButton.click();

    // 추가 질문 화면 로드 대기 (LLM 응답 필요)
    // step2가 보이고 questionsContainer에 카드가 생성될 때까지 대기
    const step2 = page.locator('[data-ai-input-target="step2"]');
    await expect(step2).toBeVisible({ timeout: LLM_TIMEOUT });

    // 질문 카드가 렌더링될 때까지 대기
    const questionCard = page.locator('.tag-input-container');
    await expect(questionCard.first()).toBeVisible({ timeout: LLM_TIMEOUT });
  }

  test('아이디어 입력 후 추가 질문 화면이 표시된다', async ({ page }) => {
    await navigateToFollowUpQuestions(page);

    // 태그 입력 컨테이너가 표시되는지 확인 (질문 카드의 일부)
    const tagContainers = page.locator('.tag-input-container');
    const count = await tagContainers.count();
    expect(count).toBeGreaterThanOrEqual(2); // 최소 2개 (필수 질문)
    expect(count).toBeLessThanOrEqual(3); // 최대 3개
  });

  test('예시 버튼 클릭 시 태그로 변환된다', async ({ page }) => {
    await navigateToFollowUpQuestions(page);

    // 첫 번째 예시 버튼 찾기
    const exampleButton = page.locator('.example-chip').first();
    await expect(exampleButton).toBeVisible();

    // 예시 버튼의 텍스트 저장
    const exampleText = await exampleButton.textContent();

    // 첫 번째 태그 입력 컨테이너
    const firstTagContainer = page.locator('.tag-input-container').first();

    // 예시 버튼 클릭
    await exampleButton.click();

    // 버튼이 숨겨졌는지 확인 (display: none)
    await expect(exampleButton).toBeHidden();

    // 태그 입력 컨테이너에 태그가 생성되었는지 확인
    const tag = firstTagContainer.locator('.selected-tag').filter({ hasText: exampleText?.trim() || '' });
    await expect(tag).toBeVisible();

    // 태그에 × 버튼이 있는지 확인
    const removeButton = tag.locator('.tag-remove-btn');
    await expect(removeButton).toBeVisible();
  });

  test('태그 × 버튼 클릭 시 태그가 제거되고 버튼이 복귀된다', async ({ page }) => {
    await navigateToFollowUpQuestions(page);

    // 첫 번째 예시 버튼
    const exampleButton = page.locator('.example-chip').first();
    const exampleText = await exampleButton.textContent();

    // 예시 버튼 클릭하여 태그 생성
    await exampleButton.click();

    // 태그가 생성되었는지 확인
    const firstTagContainer = page.locator('.tag-input-container').first();
    const tag = firstTagContainer.locator('.selected-tag').first();
    await expect(tag).toBeVisible();

    // × 버튼 클릭
    const removeButton = tag.locator('.tag-remove-btn');
    await removeButton.click();

    // 태그가 제거되었는지 확인
    await expect(tag).toBeHidden();

    // 예시 버튼이 다시 나타났는지 확인
    const restoredButton = page.locator('.example-chip').filter({ hasText: exampleText?.trim() || '' });
    await expect(restoredButton).toBeVisible();
  });

  test('여러 예시를 선택하면 모두 태그로 표시된다', async ({ page }) => {
    await navigateToFollowUpQuestions(page);

    // 첫 번째 질문의 예시 버튼들 찾기 (첫 번째 examples 컨테이너)
    const firstExamplesContainer = page.locator('[data-examples-for-question]').first();
    const exampleButtons = firstExamplesContainer.locator('.example-chip');
    const buttonCount = await exampleButtons.count();

    // 2개의 예시 버튼 클릭
    const clickCount = Math.min(2, buttonCount);
    for (let i = 0; i < clickCount; i++) {
      const button = exampleButtons.nth(i);
      // 버튼이 아직 보이는지 확인 (이미 클릭되지 않았는지)
      if (await button.isVisible()) {
        await button.click();
        await page.waitForTimeout(100); // 애니메이션 대기
      }
    }

    // 첫 번째 태그 컨테이너에서 태그 수 확인
    const firstTagContainer = page.locator('.tag-input-container').first();
    const tags = firstTagContainer.locator('.selected-tag');
    const tagCount = await tags.count();
    expect(tagCount).toBeGreaterThanOrEqual(clickCount);
  });

  test('태그와 함께 추가 텍스트를 입력할 수 있다', async ({ page }) => {
    await navigateToFollowUpQuestions(page);

    // 첫 번째 태그 컨테이너
    const firstTagContainer = page.locator('.tag-input-container').first();

    // 예시 버튼 클릭하여 태그 생성
    const exampleButton = page.locator('.example-chip').first();
    await exampleButton.click();

    // 태그 입력 영역의 텍스트 입력란 찾기
    const textInput = firstTagContainer.locator('.tag-input-field');
    await expect(textInput).toBeVisible();

    // 추가 텍스트 입력
    const additionalText = '추가 입력 테스트';
    await textInput.fill(additionalText);

    // 입력값 확인
    await expect(textInput).toHaveValue(additionalText);
  });

  test('필수 필드에 값이 있으면 제출 버튼이 활성화된다', async ({ page }) => {
    await navigateToFollowUpQuestions(page);

    // 제출 버튼 찾기
    const submitButton = page.locator('[data-ai-input-target="analyzeButton"]');

    // 초기에는 비활성화 상태 (필수 필드 미입력)
    await expect(submitButton).toBeDisabled();

    // 모든 태그 입력 컨테이너에서 required 필드만 찾기
    const requiredInputs = page.locator('.tag-input-field[data-required="true"]');
    const requiredCount = await requiredInputs.count();

    // 각 필수 필드에 값 입력
    for (let i = 0; i < requiredCount; i++) {
      const input = requiredInputs.nth(i);
      // 해당 질문의 예시 버튼 클릭하거나 직접 입력
      const questionId = await input.getAttribute('data-question-id');
      const examplesContainer = page.locator(`[data-examples-for-question="${questionId}"]`);
      const exampleBtn = examplesContainer.locator('.example-chip').first();

      if (await exampleBtn.isVisible()) {
        await exampleBtn.click();
      } else {
        // 예시가 없으면 텍스트 직접 입력
        await input.fill('테스트 입력');
      }
      await page.waitForTimeout(100);
    }

    // 제출 버튼이 활성화되었는지 확인
    await expect(submitButton).toBeEnabled();
  });

  test('선택 필드는 비어있어도 제출 가능하다', async ({ page }) => {
    await navigateToFollowUpQuestions(page);

    // 필수 질문만 입력 (data-required="true" 필드들)
    const requiredInputs = page.locator('.tag-input-field[data-required="true"]');
    const requiredCount = await requiredInputs.count();

    for (let i = 0; i < requiredCount; i++) {
      const input = requiredInputs.nth(i);
      const questionId = await input.getAttribute('data-question-id');
      const examplesContainer = page.locator(`[data-examples-for-question="${questionId}"]`);
      const exampleBtn = examplesContainer.locator('.example-chip').first();

      if (await exampleBtn.isVisible()) {
        await exampleBtn.click();
      }
    }

    // 선택 필드(required=false)는 비워둠
    // 제출 버튼 확인
    const submitButton = page.locator('[data-ai-input-target="analyzeButton"]');
    await expect(submitButton).toBeEnabled();
  });

  test('예시에 부적절한 값("직접 입력", "기타" 등)이 포함되지 않는다', async ({ page }) => {
    await navigateToFollowUpQuestions(page);

    // 부적절한 예시 목록
    const badExamples = ['직접 입력', '기타', '없음', '해당 없음', '모름', '선택 안함'];

    // 모든 예시 버튼 수집
    const exampleButtons = page.locator('.example-chip');
    const buttonCount = await exampleButtons.count();

    // 각 버튼의 텍스트가 부적절한 예시를 포함하지 않는지 확인
    for (let i = 0; i < buttonCount; i++) {
      const button = exampleButtons.nth(i);
      const text = await button.textContent();
      for (const badExample of badExamples) {
        expect(text).not.toContain(badExample);
      }
    }
  });
});

test.describe('AI 분석 플로우 통합 테스트', () => {
  test.skip('전체 플로우: 아이디어 입력 -> 질문 응답 -> 분석 결과', async ({ page }) => {
    // 이 테스트는 실제 LLM API 호출이 필요하므로 skip 처리
    // 필요시 수동으로 실행: npx playwright test ai-tag-input.spec.ts --grep "전체 플로우" --project=chromium

    // 1. AI 입력 페이지로 이동
    await page.goto('/ai/input');
    await waitForPageLoad(page);

    // 2. 아이디어 입력
    const ideaInput = page.locator('textarea[data-ai-input-target="textarea"]');
    await ideaInput.fill(TEST_IDEA);

    // 3. 다음 버튼 클릭
    const nextButton = page.locator('button[data-ai-input-target="submitButton"]');
    await nextButton.click();

    // 4. 추가 질문 응답
    const step2 = page.locator('[data-ai-input-target="step2"]');
    await expect(step2).toBeVisible({ timeout: 30000 });

    // 각 질문에 태그 선택
    const exampleButtons = page.locator('.example-chip');
    const buttonCount = await exampleButtons.count();
    for (let i = 0; i < Math.min(3, buttonCount); i++) {
      const btn = exampleButtons.nth(i);
      if (await btn.isVisible()) {
        await btn.click();
        await page.waitForTimeout(100);
      }
    }

    // 5. 분석 요청
    const analyzeButton = page.locator('[data-ai-input-target="analyzeButton"]');
    await analyzeButton.click();

    // 6. 분석 결과 페이지로 이동 확인
    // AI 분석은 시간이 오래 걸릴 수 있음 (최대 2분)
    await expect(page).toHaveURL(/\/ai\/result|\/ai\/analysis/, { timeout: 120000 });
  });
});
