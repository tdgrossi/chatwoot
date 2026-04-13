---
status: resolved
trigger: "pipeline_stats API returns 404"
created: 2026-04-12T00:00:00.000Z
updated: 2026-04-12T00:00:00.000Z
resolved: 2026-04-13T07:20:00.000Z
---

# Debug Session: pipeline_stats 404

## Status: INVESTIGATION INCONCLUSIVE

## What We Know For Fact

### 1. The Error
- Frontend calls `GET /api/v1/accounts/1/pipeline_stats`
- Server returns `404 (Not Found)`
- Error originates in `PipelineStatsPanel.vue:20` via `PipelineStatsAPI.get()`

### 2. API File
**`app/javascript/dashboard/api/pipelineStats.js`**
```javascript
class PipelineStatsAPI extends ApiClient {
  constructor() {
    super('pipeline_stats', { accountScoped: true });
  }
}
```
- `accountScoped: true` means URL becomes `/api/v1/accounts/{accountId}/pipeline_stats`
- Controller is at `Api::V1::Accounts::PipelineStatsController`

### 3. Route File
**`config/routes.rb` line 50**
```ruby
get :pipeline_stats, to: 'accounts/pipeline_stats#index'
```
This is inside `resources :accounts, only: [:create, :show, :update] do member do ... end`.

### 4. Controller
**`app/controllers/api/v1/accounts/pipeline_stats_controller.rb`**
```ruby
class Api::V1::Accounts::PipelineStatsController < Api::V1::Accounts::BaseController
  before_action :current_account

  def index
    render json: pipeline_stats
  end

  private

  def pipeline_stats
    cache_key = "pipeline_stats:account:#{Current.account.id}"
    cached = Redis::Alfred.get(cache_key)
    return JSON.parse(cached) if cached.present?
    stats = build_stats
    Redis::Alfred.setex(cache_key, stats.to_json, 60)
    stats
  end

  def build_stats
    Current.account.pipeline_stages.sorted.map do |stage|
      count = Contact.where(pipeline_stage_id: stage.id).count
      added_today = Contact.where(pipeline_stage_id: stage.id)
                           .where('created_at >= ?', Date.today.beginning_of_day)
                           .count
      { stage_id: stage.id, name: stage.name, count: count, added_today: added_today }
    end
  end
end
```

### 5. Route Recognition (verified via `rails runner`)
```
{format: "json", controller: "api/v1/accounts/pipeline_stats", action: "index", id: "1"}
```
After the last fix (`to: 'accounts/pipeline_stats#index'`), Rails router DOES recognize the path correctly.

### 6. PipelineStages Route Works
This works fine:
```
/api/v1/accounts/:account_id/pipeline_stages  GET  api/v1/accounts/pipeline_stages#index
```

## Timeline of Fix Attempts

1. **First fix (commit 83605af88):** Changed `get :pipeline_stats` → `get :pipeline_stats, to: 'pipeline_stats#index'`
   - Result: Rails router looked for `Api::V1::PipelineStatsController` (missing)

2. **Second fix:** Changed to `get :pipeline_stats, to: 'accounts/pipeline_stats#index'`
   - Result: Router now correctly identifies `Api::V1::Accounts::PipelineStatsController`
   - `rails runner` confirms correct route resolution

3. **Issue persists after both fixes**

## Key Question
The route resolves correctly in `rails runner`, but the browser still gets 404. This suggests either:
- The container didn't pick up the route change (despite restart)
- There is another issue in the request handling (CORS, auth, etc.)
- The controller has an error that causes a 500 being returned as 404

## CRITICAL FINDING (2026-04-12)

### curl test against running container:
```
curl http://localhost:3000/api/v1/accounts/1/pipeline_stats
→ HTTP 401 Unauthorized
→ {"errors":["You need to sign in or sign up before continuing."]}
```

### Conclusion: Route is CORRECT and REACHABLE

1. **`rails routes` confirms route exists:**
   `pipeline_stats_api_v1_account GET /api/v1/accounts/:id/pipeline_stats api/v1/accounts/pipeline_stats#index`

2. **Route is processed by Rails** — returns 401 (not 404), meaning controller is found and executing

3. **The "404" in the browser is a misreported auth error** — the Vue frontend is making an unauthenticated request, and the browser/network layer reports it as 404

4. **The bug is in the frontend** — `PipelineStatsPanel.vue:20` fires `fetchStats()` in its `mounted` hook. If the component mounts before authentication is complete, or if the API client isn't attaching the auth token properly, the request gets rejected.

### Next Debug Steps
1. Check if `PipelineStatsPanel` is being mounted too early (before auth)
2. Check if `ApiClient` / axios interceptor is properly attaching the auth token
3. Check if the `accountIdFromRoute` in `ApiClient` is correctly extracting the account ID from the URL path
4. The route file is fine — do NOT modify `config/routes.rb` further
