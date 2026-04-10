AGENTS.md

<!-- GSD:project-start source:PROJECT.md -->
## Project

**CRM Pipeline — Chatwoot Extension**

A pipeline-first CRM layer built on top of Chatwoot's existing contact system. Every Chatwoot contact gets a pipeline stage field, allowing contacts to be visualized in a Kanban board, filtered by stage, and tracked through a simple pipeline. The goal is lead management and basic automation hooks — not a full sales suite.

**Core Value:** Contacts (leads) flow through customizable pipeline stages. Teams see their pipeline in Kanban or list view, get stats on volume and movement, and eventually trigger automations on stage transitions or inactivity.
<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->
## Technology Stack

## Languages
- Ruby 3.4.4 - Backend API and business logic
- JavaScript/TypeScript - Frontend applications
- Vue 3 (SFC with Composition API) - UI framework
## Runtime
- Ruby 3.4.4 (MRI)
- Node.js 24.x (for frontend build)
- pnpm 10.x (package manager for Node)
- Bundler 2.x for Ruby gems
- pnpm 10.x for JavaScript packages
## Frameworks
- Rails 7.1 - Full-stack web framework
- Rails API mode for API-only concerns
- Vue.js 3.5.12 - Progressive JavaScript framework
- Vue Router 4.4.5 - SPA routing
- Pinia 3.0.4 - State management (primary store)
- Vuex 4.1.0 - Legacy state management (still in use)
- vuex-router-sync 6.0.0-rc.1 - Vuex/Router synchronization
- Vite 5.4.21 - Next-generation frontend build tool
- vite-plugin-ruby 5.0.0 - Rails integration for Vite
- Tailwind CSS 3.4.19 - Utility-first CSS framework
- PostCSS 8.4.47 - CSS transformation
- esbuild 0.19.x (via Vite) - JavaScript bundler
- Vitest 3.0.5 - Unit testing framework
- RSpec Rails 6.1.5 - BDD testing for Ruby
- jest-dom / @vue/test-utils - Vue component testing
- FakeIndexedDB 6.0.0 - IndexedDB mock for tests
- jsdom 27.2.0 - DOM implementation for Node
- Factory Bot Rails 6.4.3 - Test fixture generation
- ESLint 8.57.0 - JavaScript linting
- RuboCop - Ruby linting
- Prettier 3.3.3 - Code formatting
- Husky 7.0.0 - Git hooks
- lint-staged 16.2.7 - Run linters on staged files
## Database
- PostgreSQL (default adapter: `pg` gem)
- Configuration: `config/database.yml`
- Connection pooling via `pg` gem with Sidekiq concurrency integration
- Statement timeout: 14s (configurable via `POSTGRES_STATEMENT_TIMEOUT`)
- Active Record Encryption support for sensitive columns (MFA passwords)
- ActiveRecord with PostgreSQL-specific features
- Groupdate - Grouped date calculations
- pg_search - Full-text search
- Searchkick - Elasticsearch-backed search
- Opensearch-ruby - OpenSearch integration
- pgvector - Vector similarity search for AI features
- Activerecord-import - Bulk record imports
- Hairtrigger - Database triggers
- Audited - Audit logging
## Cache and Sessions
- Redis - Primary caching solution
- Multiple Redis namespaces:
- Redis namespace: `redis-namespace` gem
- Redis-backed sessions (default)
- Cookie-based sessions with Rails 7.1
- Redis URL via `REDIS_URL` env var (default: `redis://127.0.0.1:6379`)
- SSL verification configurable via `REDIS_OPENSSL_VERIFY_MODE`
- Connection pool sizing via `REDIS_ALFRED_SIZE` and `REDIS_VELMA_SIZE`
## Background Job Processing
- Sidekiq 7.3.1 - Background job processor
- sidekiq-cron 1.12.0 - Scheduled/cron jobs
- sidekiq_alive - Health check support
- Default: 10 workers (configurable via `SIDEKIQ_CONCURRENCY`)
- Timeout: 25 seconds
## File Storage
- Local disk (development/test)
- Amazon S3 (`aws-sdk-s3`)
- Google Cloud Storage (`google-cloud-storage`)
- Azure Blob Storage (`azure-storage-blob` - custom chatwoot fork)
- S3-compatible services (DigitalOcean Spaces, Minio)
- image_processing gem (MiniMagick or libvips backend)
- Preview generation disabled
- Direct uploads to cloud storage via Active Storage
- URL signing for secure access
- Attachment processing via Sidekiq jobs
## Real-time / WebSocket
- Redis adapter for production (`config/cable.yml`)
- channel_prefix: `chatwoot_{environment}_action_cable`
- Test adapter for test environment
- Location: `app/channels/room_channel.rb`
- Presence tracking via `OnlineStatusTracker`
- Pub/sub token-based authentication
- Support for both User and Contact connections
- `@rails/actioncable` 6.1.3 - JavaScript client
- `ActionCableConnector` in widget app
- Pubsub token-based authentication
## Key Dependencies
- Devise 4.9.4 - Authentication
- devise_token_auth - Token-based API auth
- devise-two-factor 5.0.0 - 2FA support
- devise-secure_password - Secure password hashing
- JWT - JSON Web Tokens
- Pundit - Authorization
- Omniauth variants (Google OAuth, SAML, OAuth2)
- Rest-client - HTTP client
- Faraday - HTTP library (with AWS SigV4 middleware)
- `rack-cors` - CORS support
- `rack-attack` - Rate limiting/throttling
- facebook-messenger - Facebook Messenger integration
- koala - Facebook Graph API client
- twilio-ruby - Twilio API client
- line-bot-api - LINE Messaging API
- telegram-bot-ruby - Telegram support
- Twitty - Twitter API client
- `gmail_xoauth` - Gmail OAuth2 for IMAP/SMTP
- ruby-openai - OpenAI API client
- google-cloud-dialogflow-v2 - Dialogflow
- google-cloud-translate-v3 - Google Translate
- grpc - gRPC support for Dialogflow
- neighbor - Vector similarity (pgvector companion)
- ruby_llm - LLM abstraction layer
- ai-agents 0.9.1 - AI agent framework
- FCM - Firebase Cloud Messaging (push)
- web-push 3.0.1 - Web push notifications
- Sentry (sentry-rails, sentry-ruby, sentry-sidekiq)
- Datadog 2.0
- New Relic RPM
- Elastic APM
- Scout APM
- OpenTelemetry SDK - LLM observability
- lograge - Structured logging
- Barnes - Heroku metrics
- Action Mailbox - Inbound emails
- Action Mailer - Outbound emails
- AWS SES (aws-actionmailbox-ses)
- Email Reply Trimmer
- HTML2Text
- valid_email2 - Email validation
- Liquid - Template engine
- CommonMarker - Markdown parsing
- JSON Schema validator
- Telephone Number - Phone number parsing/validation
- Geocoder - IP geolocation
- MaxMindDB - GeoIP database
- Countries and Timezones
- ActsAsTaggableOn - Tagging
- Haikunator - Name generation
- FlagShihTzu - Bit flags
- Hashie - Hash extensions
- Down - File downloading
- SSRF filter - URL fetching security
- CSV Safe - CSV injection prevention
- administrate - Admin framework
- shopify_api - Shopify integration
- nearshore bot processor services
## Platform Support
- Heroku (with judoscale autoscaling)
- Docker/Docker Compose
- Cloud platforms (AWS, GCP, Azure)
- Foreman - Process management
- Letter opener - Email preview
- Bullet - N+1 query detection
- Rack mini-profiler - Performance profiling
- Spring - Faster Rails commands
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

## Languages
- Ruby 3.4.4 - Backend Rails application
- JavaScript/TypeScript - Frontend Vue.js application
- SCSS - Styling
## Code Style
### Ruby (Rails)
- Config: `.rubocop.yml`
- Line length max: 150 characters
- Class length max: 175 lines
- Method length max: 19 lines
- Block length max: 30 lines
- rubocop-performance
- rubocop-rails
- rubocop-rspec
- rubocop-factory_bot
- Custom cops: `use_from_email.rb`, `custom_cop_location.rb`, `attachment_download.rb`, `one_class_per_file.rb`
### JavaScript/Vue
- Config: `.eslintrc.js`
- Extends: `airbnb-base/legacy`, `prettier`, `plugin:vue/vue3-recommended`, `plugin:vitest-globals/recommended`
- `prettier/prettier`: error level
- Vue component ordering: `['script', 'template', 'style']`
- Vue naming: PascalCase for components
- Custom event naming: camelCase
- `no-console`: error
- Config: `.prettierrc`
- Print width: 80
- Single quotes: true
- Trailing commas: es5
- Arrow parens: avoid
## Naming Conventions
### Files
- Classes: `snake_case` file names matching class name (e.g., `contact_identify_action.rb`)
- Tests: `*_spec.rb` for RSpec examples
- Factories: `snake_case` in `spec/factories/`
- Components: PascalCase (e.g., `DashboardChart.vue`)
- Spec files: `*.spec.js` or `*.spec.ts`
- Helpers: camelCase
### Code Elements
- Methods/variables: snake_case
- Classes/modules: PascalCase
- Constants: SCREAMING_SNAKE_CASE
- Database columns: snake_case
- Environment variables: SCREAMING_SNAKE_CASE
- Variables/functions: camelCase
- Classes/components: PascalCase
- Constants: SCREAMING_SNAKE_CASE
- Vue component options: camelCase
## Git Workflow
### Branch Protection
- Direct pushes to `master` and `develop` are blocked
- Pre-push hook validates branch name in `bin/validate_push`
### Commit Messages
- No specific commit message convention enforced
- Follow conventional commits style (not enforced)
### Hooks (Husky)
#!/bin/sh
### Lint-Staged Configuration
## Pull Request Conventions
### PR Template
- Description (summary of change, motivation, context)
- Type of change (bug fix / new feature / breaking change / documentation update)
- How Has This Been Tested? (instructions to reproduce)
- Checklist (style guidelines, self-review, documentation, tests, warnings)
### PR Process
## Code Review Patterns
- Use RSpec for testing
- Include OpenAPI schema validation via Skooma
- Pundit for authorization testing
- Factory Bot for test data
- Vue Test Utils for component testing
- Vitest globals enabled in spec files
- API tests mock axios directly
## Documentation Standards
- Comment complex logic in Ruby
- JSDoc for complex JavaScript functions
- Vue components should be self-documenting with clear prop types
- CONTRIBUTING.md points to external guide at https://www.chatwoot.com/docs/contributing-guide
- API documentation via Swagger/OpenAPI (Skooma for validation)
## Environment Configuration
- Use `.env` for local development (gitignored)
- Environment variables loaded via `dotenv-rails`
- `RAILS_ENV=test` for test environment
- Vite config supports `TEST` and `BUILD_MODE` environment variables
- Path aliases defined in `vite.config.ts`
## Special Conventions
### Vue Component Structure
### i18n
- Vue i18n plugin configured
- Locale files: `app/javascript/*/i18n/**.json`
- ESLint rules warn about dynamic keys and unused keys
### Rails Multiple Databases
- Chatwoot uses multiple database pattern (main + enterprise)
- Custom cop `UseFromEmail` enforces email service usage
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

## Overall Design
## Backend
- **Framework:** Ruby on Rails 7.1
- **Database:** PostgreSQL
- **Cache:** Redis
- **Background Jobs:** Sidekiq
- **Real-time:** ActionCable with `RoomChannel` at `app/channels/room_channel.rb`
## Frontend
- **Framework:** Vue.js 3 SPA
- **Entry Point:** `app/javascript/dashboard/`
- **Build System:** Vite
- **Styling:** Tailwind CSS
## Multi-tenancy
- Account-based isolation
- Join table: `account_users`
## Key Architectural Patterns
- **Builder Pattern:** `app/builders/`
- **Service Objects:** `app/services/`
- **Policy Objects:** `app/policies/` (Pundit)
- **Event System:** Wisper (`app/listeners/`)
## API Design
- RESTful JSON API
- Versions v1 and v2 at `/api/v1/` and `/api/v2/`
- Widget API for website widget
- Platform API
## Authentication
- Devise + Devise Token Auth
- OAuth support
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, or `.github/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
