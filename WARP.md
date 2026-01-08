# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

---

## Core commands

All commands are intended to be run from the repository root.

### Environment & setup

```bash
# Install Ruby gems
bundle install

# Set up database (development)
bin/rails db:create db:migrate db:seed
```

### Running the app (development)

```bash
# Start Rails server on http://localhost:3000
bin/rails server

# or equivalently
bin/dev
```

The app will boot into the AI onboarding landing page (`onboarding#landing`).

### Tests (Minitest)

The project uses Rails’ built-in Minitest suite under `test/` (controllers, models, services, jobs, system/E2E).

Common commands:

```bash
# Run the full test suite
bin/rails test

# Run a specific test group
bin/rails test test/models
bin/rails test test/controllers
bin/rails test test/system

# Run a single test file
bin/rails test test/models/user_test.rb
```

### Linting & security checks

These tools are wired up via dedicated binstubs and `.rubocop.yml`:

```bash
# RuboCop (Rails Omakase config)
bin/rubocop

# Static security scan
bin/brakeman

# Dependency vulnerability scan
bin/bundler-audit
```

### Background jobs & CI

Solid Queue is used for background jobs; the CLI is wrapped by `bin/jobs`:

```bash
# Solid Queue worker CLI (see Solid Queue docs / --help for subcommands)
bin/jobs --help
```

Continuous integration is configured via ActiveSupport CI:

```bash
# Project CI entrypoint (uses config/ci.rb)
bin/ci
```

For production, `Procfile` defines:

```bash
# Web server
web: bundle exec puma -C config/puma.rb

# Release task
release: bundle exec rails db:migrate
```

---

## High-level architecture

### Overall

- Rails 8.1.1 / Ruby 3.4.7 monolith (`StartupCommunity`), using:
  - SQLite (development/test), PostgreSQL (production)
  - Solid Queue (jobs), Solid Cache, Solid Cable (WebSocket)
  - Hotwire (Turbo + Stimulus), Tailwind CSS v4, shadcn-ui components
  - Importmap + Propshaft for JS/CSS asset management
- Primary entrypoint is an AI-driven onboarding/idea analysis flow, then a community + chat + outsourcing marketplace.

Key documentation lives under `.claude/`:

- `.claude/CLAUDE.md` – main project context and rules
- `.claude/PROJECT_OVERVIEW.md` – feature and module overview
- `.claude/ARCHITECTURE_DETAIL.md` – deeper architecture and data-flow details
- `.claude/DATABASE.md`, `.claude/API.md` – schema and API routing

For any substantial change, prefer consulting those documents first.

### HTTP layer & routing

- Routes are defined in `config/routes.rb` and map cleanly to feature areas:
  - **Onboarding + AI analysis**: `root "onboarding#landing"`, `/ai/input`, `/ai/questions`, `/ai/analyze`, `/ai/result/:id`, `/ai/expert/:id`.
  - **Authentication**: `/login`, `/logout`, `/signup`, password recovery under `/password/*`.
  - **Email verification**: `resources :email_verifications, only: [:create]` with `verify` collection action.
  - **Community posts**: `resources :posts` (CRUD) with nested `comments` and member actions for `like`, `bookmark`, and `remove_image`.
  - **Profiles & social graph**: `resources :profiles, only: [:show]` with `follow` member action (via `FollowsController`).
  - **Chat**: `resources :chat_rooms` with nested `messages` and member actions for deals, profile overlays, leave, mark-as-read; helper routes to start chats from profiles/posts.
  - **Payments & orders**: `resources :payments` and `resources :orders` with success/fail/webhook and receipt/cancel/confirm actions.
  - **My page & settings**: `my_page`, `settings` routes for user dashboard and preferences.
  - **Search & notifications**: `search` controller routes and `resources :notifications` (index/show/destroy, dropdown, mark_all_read).
  - **Admin namespace**: `namespace :admin` with dashboard root and resources for users, chat rooms, user deletions (with reveal), reports, inquiries, and AI usage management.

Controllers live in `app/controllers/`, with an `Admin::` namespace for back-office features and dedicated controllers for each domain (onboarding, sessions, chat_rooms, posts, payments, orders, user_deletions, inquiries, reports, etc.).

### Domain models & persistence

Models live in `app/models/` with typical Rails conventions:

- Core domain models: `User`, `Post`, `Comment`, `ChatRoom`, `ChatRoomParticipant`, `Notification`, `JobPost`, `Order`, `Payment`, `Inquiry`, `Report`, `TalentListing`, `IdeaAnalysis`, `OauthIdentity` and others.
- Reusable concerns in `app/models/concerns/` (e.g., `Bookmarkable`, `Likeable`) encapsulate cross-cutting behavior for posts and comments.
- A dedicated `UserDeletion` model ties into the account deletion / retention system, with `AdminViewLog` capturing admin access to sensitive data.

Migrations and current schema are in `db/migrate/` and `db/schema.rb`. Database-related details and ERD are extended in `.claude/DATABASE.md`.

### Services & background processing

Service objects under `app/services/` capture non-trivial business logic:

- **AI multi-agent system (`app/services/ai/`)**
  - `Ai::BaseAgent` – shared utilities and error handling for all AI agents.
  - Agents in `app/services/ai/agents/` (`SummaryAgent`, `TargetUserAgent`, `MarketAnalysisAgent`, `StrategyAgent`, `ScoringAgent`) each handle a slice of the idea analysis, typically calling Gemini models via `LangchainConfig`.
  - `Ai::Orchestrators::AnalysisOrchestrator` sequences those agents, merges their results, tracks timing, and returns a single structured payload used in onboarding results.
  - `app/services/ai/tools/*` – integration points for external/generative tools (Gemini grounding, market data, competitor database).
  - Additional helpers like `FollowUpGenerator` and `ExpertScorePredictor` refine outputs and recommendations.
- **Domain services**
  - `app/services/orders/create_service.rb` – encapsulated order creation logic.
  - `app/services/toss_payments/*` – payment lifecycle (approve, cancel, etc.).
  - `app/services/users/deletion_service.rb` – implements irreversible, encrypted account deletion and deferred data destruction.
  - `app/services/expert_matcher.rb` – matches users/ideas to experts.

Background jobs (`app/jobs/`) include AI analysis, DB backup, and automatic destruction of expired `UserDeletion` records, all executed via Solid Queue.

### Views, components, and frontend behavior

- Views live under `app/views/` with feature-oriented directories (`posts/`, `chat_rooms/`, `search/`, `onboarding/`, `payments/`, etc.).
- Design system and UI components:
  - `app/views/components/ui/` contains shadcn-style reusable components, with its own README.
  - Helpers under `app/helpers/components/*` and `app/helpers/components_helper.rb` provide rendering utilities.
- Stimulus controllers are under `app/javascript/controllers/` (dozens of controllers for chat, live search, AI loading/result, uploads, admin interactions, etc.), tightly coupled to Turbo streams.
- High-level design tokens, layout rules, and component patterns are documented in `.claude/DESIGN_SYSTEM.md` and `.claude/standards/tailwind-frontend.md`.

### Testing structure

Tests live entirely under `test/` (no RSpec):

- `test/models/` – model unit tests for all core domain models.
- `test/controllers/` – controller/integration tests (including `Admin::` controllers).
- `test/services/` – tests for AI agents, orchestrators, and service objects.
- `test/jobs/`, `test/mailers/`, `test/system/` – job, mailer, and end-to-end/system tests.
- `test/fixtures/` – fixtures for posts, users, notifications, orders, etc.

`.claude/standards/testing.md` defines stricter local expectations (e.g., TDD-style workflow and coverage targets) if you need to align with the project’s preferred testing style.

### Additional folders

- `.claude/` – extensive, project-specific docs, standards, workflows, rules, and custom Claude Skills; treat this as the primary reference for deeper architectural or product questions.
- `rails-frontend-ex/` – a separate Rails example app used for frontend/UI experiments; do not confuse it with the main `StartupCommunity` app, but you may borrow patterns from it when working on UI.

---

## Project-specific rules & pitfalls (from .claude/CLAUDE.md)

These are **local, non-generic rules** that future agents should respect when editing code.

### UI helpers and search behavior

- **Avatar rendering**: Do **not** call `render_avatar(user)`. Use the shadcn-compatible helper instead:
  - `render_user_avatar(user, size: "md")` (and similar variants) are the expected entrypoints.
- **Open Graph meta tags**: Do not assemble OG tags manually or rely on `request.original_url` directly for share URLs; use the `og_meta_tags` helper so that UTF-8 encoding and metadata remain correct.
- **Search result clicks**: Search result links must use `onmousedown` (not `onclick`) to avoid re-triggering searches when focus changes. If you need to alter search result templates, preserve that pattern.

### Infrastructure-sensitive files

- **`config/initializers/faraday_ssl.rb`** must not be removed; it is required to prevent SSL errors on macOS.
- **Animation CSS in `application.html.erb`**:
  - Custom animations are defined inline in the main layout and are **not** loaded from the compiled Tailwind CSS.
  - Do not delete or move these inline styles unless you fully migrate the animation pipeline and verify the landing page visually; otherwise the marketing/onboarding experience will break.

### Planning & documentation

- For multi-step or risky changes, prefer aligning with the existing planning ecosystem in `.claude/`:
  - Use `.claude/references/cc-feature-implementer-main/plan-template.md` as a reference if you need a phase-based implementation plan.
  - `.claude/workflows/feature-development.md` describes the project’s preferred feature workflow.
- The project assumes tests and linting are part of every significant change; see the testing and standards docs in `.claude/standards/` for the expected level of rigor.

---

## How to use this file as Warp

- For **quick tasks** (small bugfixes, minor refactors), use the commands and architectural pointers above, plus the concrete patterns already present in `app/` and `test/`.
- For **larger features or cross-cutting changes**, first skim:
  - `README.md` (high-level status and feature list)
  - `.claude/CLAUDE.md` (project rules and quick references)
  - `.claude/PROJECT_OVERVIEW.md` and `.claude/ARCHITECTURE_DETAIL.md` (for module boundaries and flows)
- When in doubt about domain rules (e.g., AI analysis, account deletion, payments), prefer reading the corresponding service + model + tests before generating new code, and mirror existing patterns.