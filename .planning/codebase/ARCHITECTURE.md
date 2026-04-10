# Architecture

**Analysis Date:** 2026-04-10

## Overall Design

**Pattern:** Rails Monolith with Vue.js 3 SPA Frontend

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
