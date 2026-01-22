# Code Review Report - Startup Community Rails

Date: 2026-01-20
Scope: Static review of core app code (controllers, models, services, helpers, JS controllers), schema, and admin/API paths.
Method: Manual reading + targeted searches for high-risk patterns (html_safe, raw, constantize, update_all, inline JS, redirect, Net::HTTP usage, rescues).
Limitations: No automated scanners or test suites executed for this report.

## Executive Summary
This review focuses on correctness, security, performance, and operational stability. The codebase shows strong structure and thoughtful service extraction, but several high-risk areas exist around API image ingestion, message post-processing reliability, and unread-count computation. Admin filtering and API pagination show correctness gaps. Security posture is generally good, but API tokens are stored in plaintext and some inline JS reduces CSP readiness.

Severity counts (this report):
- High: 2
- Medium: 5
- Low: 3

## Findings

### High
1) API image URL ingestion enables SSRF and unbounded downloads
   - Impact: A token holder can request internal network resources or trigger large downloads, risking data exposure and memory exhaustion.
   - Evidence: `app/controllers/api/v1/posts_controller.rb:143`, `app/controllers/api/v1/posts_controller.rb:178`.
   - Notes: No host allowlist, no content-length cap, full body loaded into memory.

2) Message post-create pipeline re-raises after commit, causing client-visible failures and possible duplicates
   - Impact: Message persists but request fails; clients may retry, generating duplicates and confusing UX.
   - Evidence: `app/models/message.rb:48`, `app/services/messages/post_creation_service.rb:26`.

### Medium
3) Unread count method bypasses stored counter and triggers N+1
   - Impact: Each call computes COUNT across messages; heavy in list views and can degrade at scale.
   - Evidence: `app/models/chat_room_participant.rb:11`.

4) total_unread_messages uses raw join/count on each call
   - Impact: Badge rendering can perform expensive queries on every request; counter cache already exists.
   - Evidence: `app/models/concerns/messageable.rb:8`.

5) Admin users date filters do not rescue invalid dates
   - Impact: Invalid input can raise 500 for admin list/export.
   - Evidence: `app/controllers/admin/users_controller.rb:38`, `app/controllers/admin/users_controller.rb:91`.

6) API post creation attaches images before record save
   - Impact: Validation failure leaves orphaned Active Storage blobs; storage bloat over time.
   - Evidence: `app/controllers/api/v1/posts_controller.rb:42`, `app/controllers/api/v1/posts_controller.rb:165`.

7) API tokens stored in plaintext
   - Impact: DB leak grants immediate API access; cannot safely show tokens only once.
   - Evidence: `app/models/concerns/api_tokenable.rb:11`.

### Low
8) API posts index total_count ignores filters
   - Impact: Pagination metadata incorrect for filtered requests.
   - Evidence: `app/controllers/api/v1/posts_controller.rb:80`.

9) has_unread_messages? compares EXISTS to integer
   - Impact: Returns false on PostgreSQL (EXISTS yields 't'/'f'); method is unreliable.
   - Evidence: `app/models/concerns/messageable.rb:26`.

10) Inline onclick handlers reduce CSP readiness
   - Impact: Harder to enforce strict CSP; inconsistent with Stimulus patterns.
   - Evidence: `app/views/shared/_floating_write_button.html.erb:35`, `app/views/comments/_comment.html.erb:140`.

## Recommendations (Prioritized)

1) Security hardening for API image ingestion
   - Add URL allowlist or block private IP ranges (RFC1918, link-local, loopback).
   - Enforce max content length and streaming download with size cap.
   - Consider background ingestion with validation and timeouts.

2) Message post-create error handling
   - Avoid re-raising after commit or separate persistence from side effects.
   - Make broadcast/notification failures non-fatal and idempotent.

3) Unread count strategy
   - Use `unread_count` column consistently for UI counts.
   - Provide reconciliation jobs to fix drift.

4) Admin date parsing
   - Wrap Date.parse with safe parsing (already used elsewhere) and user-facing errors.

5) API token storage
   - Store only hashed tokens; return plaintext only at creation time.
   - Add rotation/revocation and last-used tracking.

6) API pagination metadata
   - Use filtered scope for total_count and pagination.

## Open Questions
- Is API v1 intended for internal automation only, or exposed to third parties?
- Should unread counts be authoritative via the counter column or recomputed from messages?
- Is `has_unread_messages?` used anywhere? If not, should it be removed to avoid incorrect behavior on PostgreSQL?
- Do you want strict CSP enforcement in the near term? (affects inline JS changes)

## Next Steps (Optional)
- Run automated scanners and tests to corroborate findings:
  - `ruby .claude/skills/code-review/scripts/full_review.rb --deep`
  - `ruby .claude/skills/security-audit/scripts/security_audit.rb`
  - `ruby .claude/skills/performance-check/scripts/performance_check.rb`
  - `bundle exec rubocop`
  - `bin/rails test`

