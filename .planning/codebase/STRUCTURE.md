# Structure

**Analysis Date:** 2026-04-10

## Root Level

Standard Rails directory structure with:
- `app/` - Main application code
- `config/` - Configuration files
- `db/` - Database migrations and schema
- `spec/` - Backend tests

## Backend Structure (`app/`)

- `models/` - ActiveRecord models
- `controllers/api/` - API controllers
- `services/` - Service objects
- `builders/` - Builder pattern classes
- `jobs/` - Background jobs
- `listeners/` - Event listeners (Wisper)
- `channels/` - ActionCable channels

## Frontend Structure (`app/javascript/dashboard/`)

- `api/` - API client modules
- `components/` - Vue components
- `store/modules/` - Vuex/Pinia store modules
- `routes/dashboard/` - Route definitions

## Entry Points

- `dashboard_controller.rb` - SPA entry point
- API controllers at `app/controllers/api/v1/` and `app/controllers/api/v2/`

## Key Configuration Files

- `config/routes.rb` - Route definitions
- `vite.config.ts` - Vite/frontend build configuration
- `tailwind.config.js` - Tailwind CSS configuration
