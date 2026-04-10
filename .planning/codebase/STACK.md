# Technology Stack

**Analysis Date:** 2026-04-10

## Languages

**Primary:**
- Ruby 3.4.4 - Backend API and business logic
- JavaScript/TypeScript - Frontend applications

**Secondary:**
- Vue 3 (SFC with Composition API) - UI framework

## Runtime

**Environment:**
- Ruby 3.4.4 (MRI)
- Node.js 24.x (for frontend build)
- pnpm 10.x (package manager for Node)

**Package Manager:**
- Bundler 2.x for Ruby gems
- pnpm 10.x for JavaScript packages

## Frameworks

**Core Backend:**
- Rails 7.1 - Full-stack web framework
- Rails API mode for API-only concerns

**Frontend:**
- Vue.js 3.5.12 - Progressive JavaScript framework
- Vue Router 4.4.5 - SPA routing
- Pinia 3.0.4 - State management (primary store)
- Vuex 4.1.0 - Legacy state management (still in use)
- vuex-router-sync 6.0.0-rc.1 - Vuex/Router synchronization

**Build Tools:**
- Vite 5.4.21 - Next-generation frontend build tool
- vite-plugin-ruby 5.0.0 - Rails integration for Vite
- Tailwind CSS 3.4.19 - Utility-first CSS framework
- PostCSS 8.4.47 - CSS transformation
- esbuild 0.19.x (via Vite) - JavaScript bundler

**Testing:**
- Vitest 3.0.5 - Unit testing framework
- RSpec Rails 6.1.5 - BDD testing for Ruby
- jest-dom / @vue/test-utils - Vue component testing
- FakeIndexedDB 6.0.0 - IndexedDB mock for tests
- jsdom 27.2.0 - DOM implementation for Node
- Factory Bot Rails 6.4.3 - Test fixture generation

**Code Quality:**
- ESLint 8.57.0 - JavaScript linting
- RuboCop - Ruby linting
- Prettier 3.3.3 - Code formatting
- Husky 7.0.0 - Git hooks
- lint-staged 16.2.7 - Run linters on staged files

## Database

**Primary Database:**
- PostgreSQL (default adapter: `pg` gem)
- Configuration: `config/database.yml`
- Connection pooling via `pg` gem with Sidekiq concurrency integration
- Statement timeout: 14s (configurable via `POSTGRES_STATEMENT_TIMEOUT`)
- Active Record Encryption support for sensitive columns (MFA passwords)

**ORM and Extensions:**
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

**Cache Layer:**
- Redis - Primary caching solution
- Multiple Redis namespaces:
  - `alfred` - Round robin, conversation emails, online presence
  - `velma` - Rack::Attack rate limiting
- Redis namespace: `redis-namespace` gem

**Session Storage:**
- Redis-backed sessions (default)
- Cookie-based sessions with Rails 7.1

**Configuration:**
- Redis URL via `REDIS_URL` env var (default: `redis://127.0.0.1:6379`)
- SSL verification configurable via `REDIS_OPENSSL_VERIFY_MODE`
- Connection pool sizing via `REDIS_ALFRED_SIZE` and `REDIS_VELMA_SIZE`

## Background Job Processing

**Primary:**
- Sidekiq 7.3.1 - Background job processor
- sidekiq-cron 1.12.0 - Scheduled/cron jobs
- sidekiq_alive - Health check support

**Queue Priority (config/sidekiq.yml):**
1. critical
2. high
3. medium
4. default
5. mailers
6. action_mailbox_routing
7. low
8. scheduled_jobs
9. deferred
10. purgable
11. housekeeping
12. async_database_migration
13. bulk_reindex_low
14. active_storage_analysis
15. active_storage_purge
16. action_mailbox_incineration

**Concurrency:**
- Default: 10 workers (configurable via `SIDEKIQ_CONCURRENCY`)
- Timeout: 25 seconds

## File Storage

**Active Storage (Rails 7.1):**
- Local disk (development/test)
- Amazon S3 (`aws-sdk-s3`)
- Google Cloud Storage (`google-cloud-storage`)
- Azure Blob Storage (`azure-storage-blob` - custom chatwoot fork)
- S3-compatible services (DigitalOcean Spaces, Minio)

**Image Processing:**
- image_processing gem (MiniMagick or libvips backend)
- Preview generation disabled

**Upload Handling:**
- Direct uploads to cloud storage via Active Storage
- URL signing for secure access
- Attachment processing via Sidekiq jobs

## Real-time / WebSocket

**Action Cable (Rails WebSocket):**
- Redis adapter for production (`config/cable.yml`)
- channel_prefix: `chatwoot_{environment}_action_cable`
- Test adapter for test environment

**Room Channel Implementation:**
- Location: `app/channels/room_channel.rb`
- Presence tracking via `OnlineStatusTracker`
- Pub/sub token-based authentication
- Support for both User and Contact connections

**Frontend Cable Connection:**
- `@rails/actioncable` 6.1.3 - JavaScript client
- `ActionCableConnector` in widget app
- Pubsub token-based authentication

## Key Dependencies

**Authentication & Authorization:**
- Devise 4.9.4 - Authentication
- devise_token_auth - Token-based API auth
- devise-two-factor 5.0.0 - 2FA support
- devise-secure_password - Secure password hashing
- JWT - JSON Web Tokens
- Pundit - Authorization
- Omniauth variants (Google OAuth, SAML, OAuth2)

**API and HTTP:**
- Rest-client - HTTP client
- Faraday - HTTP library (with AWS SigV4 middleware)
- `rack-cors` - CORS support
- `rack-attack` - Rate limiting/throttling

**Messaging Channels:**
- facebook-messenger - Facebook Messenger integration
- koala - Facebook Graph API client
- twilio-ruby - Twilio API client
- line-bot-api - LINE Messaging API
- telegram-bot-ruby - Telegram support
- Twitty - Twitter API client
- `gmail_xoauth` - Gmail OAuth2 for IMAP/SMTP

**AI/ML Integrations:**
- ruby-openai - OpenAI API client
- google-cloud-dialogflow-v2 - Dialogflow
- google-cloud-translate-v3 - Google Translate
- grpc - gRPC support for Dialogflow
- neighbor - Vector similarity (pgvector companion)
- ruby_llm - LLM abstraction layer
- ai-agents 0.9.1 - AI agent framework

**Notifications:**
- FCM - Firebase Cloud Messaging (push)
- web-push 3.0.1 - Web push notifications

**Monitoring & Observability:**
- Sentry (sentry-rails, sentry-ruby, sentry-sidekiq)
- Datadog 2.0
- New Relic RPM
- Elastic APM
- Scout APM
- OpenTelemetry SDK - LLM observability
- lograge - Structured logging
- Barnes - Heroku metrics

**Email:**
- Action Mailbox - Inbound emails
- Action Mailer - Outbound emails
- AWS SES (aws-actionmailbox-ses)
- Email Reply Trimmer
- HTML2Text
- valid_email2 - Email validation

**Data & Parsing:**
- Liquid - Template engine
- CommonMarker - Markdown parsing
- JSON Schema validator
- Telephone Number - Phone number parsing/validation
- Geocoder - IP geolocation
- MaxMindDB - GeoIP database
- Countries and Timezones

**Utilities:**
- ActsAsTaggableOn - Tagging
- Haikunator - Name generation
- FlagShihTzu - Bit flags
- Hashie - Hash extensions
- Down - File downloading
- SSRF filter - URL fetching security
- CSV Safe - CSV injection prevention

**Enterprise Features:**
- administrate - Admin framework
- shopify_api - Shopify integration
- nearshore bot processor services

## Platform Support

**Deployment:**
- Heroku (with judoscale autoscaling)
- Docker/Docker Compose
- Cloud platforms (AWS, GCP, Azure)

**Development:**
- Foreman - Process management
- Letter opener - Email preview
- Bullet - N+1 query detection
- Rack mini-profiler - Performance profiling
- Spring - Faster Rails commands

---

*Stack analysis: 2026-04-10*
