# Integrations

**Analysis Date:** 2026-04-10

## Email Integration

- **Channel::Email** with IMAP/SMTP support
- OAuth2 authentication for Google and Microsoft
- AWS SES support
- Forward-to email system with routing via Action Mailbox

## Chat Integrations

- **Website Widget** (`Channel::WebWidget`) - SDK at `public/packs/js/sdk.js`
- **API Channel** (`Channel::Api`) - HMAC authentication

## Social Media

- **Facebook Messenger** via `Channel::FacebookPage` (facebook-messenger gem)
- **Instagram** via Facebook platform
- **Twitter/X** via `Channel::TwitterProfile` (twitty gem)
- **LINE** via `Channel::Line` (line-bot-api gem)

## Messaging & Voice

- **Twilio SMS/WhatsApp** (`Channel::TwilioSms`)
- **WhatsApp Direct** (`Channel::Whatsapp`) - 360Dialog and WhatsApp Cloud providers
- **Voice channel** (Enterprise) via Twilio
- **Telegram**

## AI Integrations

- Dialogflow
- Google Translate
- OpenAI
- LLM Framework with OpenTelemetry

## CRM & Project

- Slack
- Linear
- LeadSquared
- Shopify

## Video

- Dyte for in-app video calls

## Storage

- Active Storage with support for:
  - Amazon S3
  - Google Cloud Storage
  - Azure
  - S3-compatible storage

## Error Tracking (Optional via environment variables)

- Sentry
- Datadog
- New Relic
- Elastic APM
- Scout APM
