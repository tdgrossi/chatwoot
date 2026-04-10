# Coding Conventions

**Analysis Date:** 2026-04-10

## Languages

**Primary:**
- Ruby 3.4.4 - Backend Rails application
- JavaScript/TypeScript - Frontend Vue.js application

**Secondary:**
- SCSS - Styling

## Code Style

### Ruby (Rails)

**Linter:** RuboCop with custom configuration
- Config: `.rubocop.yml`
- Line length max: 150 characters
- Class length max: 175 lines
- Method length max: 19 lines
- Block length max: 30 lines

**Key RuboCop Settings:**
```yaml
Style/ClassAndModuleChildren:
  EnforcedStyle: compact

Style/HashSyntax:
  EnforcedStyle: no_mixed_keys
  EnforcedShorthandSyntax: never

RSpec/MultipleExpectations:
  Max: 7

Metrics/AbcSize:
  Max: 26
```

**Plugins used:**
- rubocop-performance
- rubocop-rails
- rubocop-rspec
- rubocop-factory_bot
- Custom cops: `use_from_email.rb`, `custom_cop_location.rb`, `attachment_download.rb`, `one_class_per_file.rb`

**Running RuboCop:**
```bash
bundle exec rubocop --parallel              # Run all cops
bundle exec rubocop -a                       # Auto-fix
ruby:prettier                               # npm script for auto-fix
```

### JavaScript/Vue

**Linter:** ESLint with Vue 3 and Vitest support
- Config: `.eslintrc.js`
- Extends: `airbnb-base/legacy`, `prettier`, `plugin:vue/vue3-recommended`, `plugin:vitest-globals/recommended`

**Key ESLint Rules:**
- `prettier/prettier`: error level
- Vue component ordering: `['script', 'template', 'style']`
- Vue naming: PascalCase for components
- Custom event naming: camelCase
- `no-console`: error

**Running ESLint:**
```bash
pnpm run eslint                              # Check
pnpm run eslint:fix                          # Auto-fix
```

**Formatter:** Prettier
- Config: `.prettierrc`
- Print width: 80
- Single quotes: true
- Trailing commas: es5
- Arrow parens: avoid

## Naming Conventions

### Files

**Ruby:**
- Classes: `snake_case` file names matching class name (e.g., `contact_identify_action.rb`)
- Tests: `*_spec.rb` for RSpec examples
- Factories: `snake_case` in `spec/factories/`

**JavaScript/Vue:**
- Components: PascalCase (e.g., `DashboardChart.vue`)
- Spec files: `*.spec.js` or `*.spec.ts`
- Helpers: camelCase

### Code Elements

**Ruby:**
- Methods/variables: snake_case
- Classes/modules: PascalCase
- Constants: SCREAMING_SNAKE_CASE
- Database columns: snake_case
- Environment variables: SCREAMING_SNAKE_CASE

**JavaScript:**
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

**Pre-commit:** Runs `lint-staged` for JS/Vue files
**Pre-push:** Runs validation and linting
```bash
#!/bin/sh
# lint-staged for JS/Vue
npx --no-install lint-staged

# RuboCop for staged Ruby files
git diff --name-only --cached | xargs -I {} bundle exec rubocop --force-exclusion -a "{}"
```

### Lint-Staged Configuration

```json
{
  "app/**/*.{js,vue}": ["eslint --fix", "git add"],
  "*.scss": ["scss-lint"]
}
```

## Pull Request Conventions

### PR Template

Located at `.github/PULL_REQUEST_TEMPLATE.md`:

**Required sections:**
- Description (summary of change, motivation, context)
- Type of change (bug fix / new feature / breaking change / documentation update)
- How Has This Been Tested? (instructions to reproduce)
- Checklist (style guidelines, self-review, documentation, tests, warnings)

### PR Process

1. Create feature branch from `develop`
2. Make changes with passing tests
3. Submit PR with filled template
4. Pass CI/CD checks (linting, tests)
5. Code review by maintainers
6. Squash and merge to `develop`

## Code Review Patterns

**Backend Rails:**
- Use RSpec for testing
- Include OpenAPI schema validation via Skooma
- Pundit for authorization testing
- Factory Bot for test data

**Frontend Vue:**
- Vue Test Utils for component testing
- Vitest globals enabled in spec files
- API tests mock axios directly

## Documentation Standards

**Inline Documentation:**
- Comment complex logic in Ruby
- JSDoc for complex JavaScript functions
- Vue components should be self-documenting with clear prop types

**External Documentation:**
- CONTRIBUTING.md points to external guide at https://www.chatwoot.com/docs/contributing-guide
- API documentation via Swagger/OpenAPI (Skooma for validation)

## Environment Configuration

**Ruby/Rails:**
- Use `.env` for local development (gitignored)
- Environment variables loaded via `dotenv-rails`
- `RAILS_ENV=test` for test environment

**JavaScript:**
- Vite config supports `TEST` and `BUILD_MODE` environment variables
- Path aliases defined in `vite.config.ts`

## Special Conventions

### Vue Component Structure

Order must be: `script` -> `template` -> `style`

### i18n

- Vue i18n plugin configured
- Locale files: `app/javascript/*/i18n/**.json`
- ESLint rules warn about dynamic keys and unused keys

### Rails Multiple Databases

- Chatwoot uses multiple database pattern (main + enterprise)
- Custom cop `UseFromEmail` enforces email service usage

---

*Convention analysis: 2026-04-10*
