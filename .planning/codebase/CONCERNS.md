# Codebase Concerns

**Analysis Date:** 2026-04-10

## Technical Debt

### Default Scopes

Default scopes can cause unexpected behavior throughout the codebase. They hide querying logic and can lead to subtle bugs.

- `app/models/message.rb:126` - `default_scope { order(created_at: :asc) }` - The default ordering on messages can cause performance issues on large tables. The TODO comment at line 123 indicates this is known: "Get rid of default scope"
- `app/models/label.rb:31` - `default_scope { order(:title) }` - Same pattern, same risk
- `app/models/installation_config.rb:30` - `default_scope { order(created_at: :desc) }` - Same anti-pattern

**Fix approach:** Remove default scopes and explicitly specify ordering where needed.

### Monkey Patches

- `config/initializers/monkey_patches/chat.rb` - Contains a monkey patch for slack-ruby-client to fix a bug. The comment indicates: "TODO: Remove this monkey patch when PR for this issue https://github.com/slack-ruby/slack-ruby-client/issues/388 is merged"

**Fix approach:** Monitor the upstream PR and remove the patch once merged.

### Temporary Fallbacks and Workarounds

- `app/builders/conversation_builder.rb:25` - "TODO: temporary fallback for the old bot status in conversation, we will remove after couple of releases"
- `app/controllers/api/v1/widget/conversations_controller.rb:14` - "TODO: Temporary fix for message type cast issue"
- `app/controllers/api/v1/accounts/bulk_actions_controller.rb:47` - "TODO: Align conversation payloads with the `{ action_name, action_attributes }`"

### State Machine Not Implemented

- `app/models/conversation.rb:150` - "FIXME: implement state machine with aasm" - The `toggle_status` method manually manages state transitions instead of using a proper state machine library.

**Fix approach:** Consider implementing aasm gem for proper state machine behavior.

### Legacy Code Patterns

- `lib/events/types.rb:21` - "FIXME: deprecate the opened and resolved events in future in favor of status changed event"
- `app/models/conversation.rb:140` - "TODO: Migrate to use a timestamp with microsecond precision" - Timestamp precision inconsistencies between Ruby and database
- `app/views/api/v1/models/_inbox.json.jbuilder:1` - "TODO: Move this into models jbuilder"

### Redis Connection Pool Wrappers

- `config/initializers/01_redis.rb` - Contains TODO to "Phase out the custom ConnectionPool wrappers ($alfred / $velma)" in favor of Rails 7.1+ pooling via `pool:` in RedisCacheStore.

### Multiple Rails Versions in CI

- `config/application.rb:39` - `config.load_defaults 7.0` - The application targets Rails 7.1 but defaults to 7.0 compatibility mode.

### Deprecated Feature Flags

- `config/features.yml` - Multiple features marked as `deprecated: true`:
  - `channel_twitter` (line 23)
  - `channel_facebook` (line 114)
  - Additional deprecated features exist but are not cleaned up from the UI

**Fix approach:** Remove deprecated feature flags from the codebase.

## Known Bugs

### Message Type Cast Issue

- `app/controllers/api/v1/widget/conversations_controller.rb:14` - message_type returns as string instead of integer, requiring a temporary fix.

### Typo in Additional Attributes

- `app/controllers/api/v1/widget/base_controller.rb:32` - "FIXME: typo referrer in additional attributes, will probably require a migration"

### IMAP Email Fetch IOError

- Recent commit `224b1f98b` - "fix: handle ioerror in imap fetch" indicates an edge case in IMAP email fetching that was not previously handled.

### Email Rate Limit Race Condition

- `app/jobs/delete_object_job.rb:8` - Comment mentions "timeouts & race conditions due to destroy_async fan-out"

## Security Considerations

### MFA Encryption Dependencies

- `config/application.rb:78-84` - Active Record encryption is optional and controlled by environment variables. The comment states "TODO: Remove once encryption is mandatory and legacy plaintext is migrated."
- MFA/2FA features depend on encryption being configured, but the system works without it.

**Current mitigation:** Encryption keys are required via environment variables for full MFA functionality.

**Recommendations:** Make encryption mandatory and provide migration tooling for existing installations.

### Devise Race Condition Workaround

- `app/models/user.rb:195-212` - Contains a workaround for a Devise race condition vulnerability (GHSA-57hq-95w6-v4fc). The comment explains:
  - The Confirmable module has a race condition where concurrent email change requests can desynchronize confirmation tokens
  - Cannot upgrade to Devise 5.0.3 because devise-two-factor only added Devise 5 support in v6.4.0, which requires Rails 7.2+
  - This is a known vulnerability that cannot be patched without a major dependency upgrade

**Fix approach:** Plan for a future upgrade path that resolves this security issue.

### API Access Token Handling

- `app/controllers/concerns/access_token_auth_helper.rb:8-18` - Access tokens are passed via headers and validated against database records on each request.

**Performance consideration:** This pattern requires a database query on every authenticated request.

### CSRF Protection

- `app/controllers/application_controller.rb:7` - `skip_before_action :verify_authenticity_token` - CSRF verification is skipped application-wide. This is intentional for API-only behavior but should be verified that all non-API routes are properly protected.

## Performance Bottlenecks

### Large Model Files

The following models have high line counts indicating potential complexity:
- `app/models/message.rb` (452 lines) - Largest model with many concerns mixed in
- `app/models/conversation.rb` (348 lines) - Complex conversation logic
- `app/models/contact.rb` (253 lines)
- `app/models/inbox.rb` (251 lines)

**Why fragile:** Large models often indicate too many responsibilities. Testing becomes harder, and changes have wider blast radius.

### N+1 Query Patterns

Multiple locations show potential N+1 patterns:
- `app/listeners/notification_listener.rb:6,20` - `conversation.inbox.members.each do |agent|` - Loading inbox members in a loop
- `app/listeners/hook_listener.rb:40,51` - `account.webhooks.account_type.each do |webhook|` and `account.hooks.account_hooks.find_each do |hook|`

### Unoptimized Loops

- `app/models/application_record.rb:25` - `self.class.columns.each do |column|` - Iterating over all columns
- `app/listeners/installation_webhook_listener.rb:17` - `account(event).administrators.map(&:webhook_data)`

### Missing Batching

While some areas use `find_in_batches`, many operations still iterate with `.each` over potentially large collections without batching.

### Serialization Performance

- `app/drops/conversation_drop.rb:13` - `@obj.try(:recent_messages).map do |message|` - Potentially loading many messages for serialization

## Scalability Limits

### ActionCable Broadcasting

- `app/listeners/action_cable_listener.rb` - Broadcasts events to all conversation participants. For conversations with many participants, this could scale poorly.

### Message Notifications

- `app/models/message.rb:154` - `attachments.map(&:push_event_data)` - Loading all attachments into memory for push event data

### Database Connection Pooling

- Custom Redis connection pools (`$alfred`, `$velma`) are manually managed rather than using Rails 7.1+ built-in pooling.

### Image Processing

- `app/services/telegram/send_attachments_service.rb:131-132` - Sets timeout to 300 seconds for file uploads

## Maintenance Challenges

### Many TODO/FIXME Comments

The codebase has 80+ TODO/FIXME/HACK comments indicating known issues that need attention:
- 3 HACK comments in `spec/listeners/action_cable_listener_spec.rb`
- Multiple TODO comments across models, controllers, and services
- Several FIXME comments indicating known issues

### Complex Configuration

- `config/application.rb` - Multiple conditional gem loading based on environment variables (Datadog, Elastic APM, Scout APM, New Relic, Sentry, Judoscale)
- Feature flags are scattered across `config/features.yml` with deprecated entries

### Deprecated Patterns Still in Use

- `app/controllers/public_controller.rb:1` - "TODO: we should switch to ActionController::API for the base classes"
- `app/controllers/widgets_controller.rb:1` - "TODO : Delete this and associated spec once 'api/widget/config' end point is merged"

### Complex Serialization

- Multiple jbuilder templates in `app/views/api/v1/` - Views contain logic that should potentially be moved to presenters or serializers

### Multiple API Versions

- `app/controllers/api/v1/` and `app/controllers/api/v2/` - API versioning may lead to maintenance burden

## Configuration Pain Points

### Environment Variable Heavy

- `config/application.rb:14-34` - Multiple APM agents loaded conditionally based on environment variables
- Encryption keys required but optional (creates confusion)
- Redis SSL verification mode has a complex fallback

### Complex Initializers

- `config/initializers/devise.rb` (13KB) - Very large Devise configuration
- `config/initializers/rack_attack.rb` - Contains TODO about deprecating a feature

### Feature Flag Complexity

- `app/helpers/super_admin/account_features_helper.rb` - Filter logic for deprecated features indicates feature flags are not fully cleaned up

## Fragile Areas

### Message Model

- `app/models/message.rb` - 452 lines with multiple concerns (`MessageFilterHelpers`, `Liquidable`), enums, validations, callbacks, and methods. This is a high-risk file for changes.

### Conversation Status Toggle

- `app/models/conversation.rb:149-154` - The `toggle_status` method manually manages state instead of using a proper state machine.

### ActionCable Listener

- `app/listeners/action_cable_listener.rb` (225 lines) - Handles many event types with repetitive broadcast patterns. The HACK comments in tests indicate reliance on specific behavior.

### Hook System

- `app/listeners/hook_listener.rb` - Uses `find_each` which is good, but the overall hook dispatching logic is complex.

## Test Coverage Gaps

### Spec Files with HACKs

- `spec/listeners/action_cable_listener_spec.rb` - Multiple "HACK: to reload conversation inbox members" comments indicating test instability

### Edge Cases Not Tested

- `app/services/telegram/incoming_message_service_spec.rb:136` - "TODO: The language code is not present when we send the first message to the client"

## Dependencies at Risk

### Devise and devise-two-factor

- Devise upgrade path blocked by devise-two-factor compatibility (see security section)
- Current workaround is a local patch for a known vulnerability

### Deprecated NPM Packages

From `pnpm-lock.yaml`:
- Multiple deprecated packages including `vue-i18n` older versions
- `shikiji` deprecated in favor of another package
- ESLint-related deprecated packages

### RestClient

- `Gemfile:19` - Using `rest-client` with a TODO: "lets use HTTParty instead of RestClient"

### Slack Ruby Client

- Custom monkey patch required for slack-ruby-client (see monkey patches section)

## Missing Critical Features

### No Message Search Index Cleanup

- Message reindexing happens on create/update but there's no visible cleanup mechanism for deleted messages.

### No Conversation Merge

- Bulk actions exist but there's no dedicated conversation merge feature despite having contact merge action.

### No Background Job Monitoring

- While Sidekiq is used, there's no visible built-in monitoring of job queue health in the codebase.

---

*Concerns audit: 2026-04-10*
