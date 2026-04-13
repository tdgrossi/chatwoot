---
status: resolved
trigger: "Fix pipeline_stats 404, FilterService nil check, and cache_keys duplicate calls"
created: 2026-04-12T00:00:00Z
updated: 2026-04-12T00:00:00Z
---

## Current Focus

All 3 issues have been fixed.

## Symptoms

### Issue 1: pipeline_stats API returns 404
- **Expected:** `GET /api/v1/accounts/1/pipeline_stats` returns pipeline statistics
- **Actual:** 404 error - route was missing controller specification
- **Reproduction:** Calls `pipelineStore.fetchStats()` which hits `/api/v1/accounts/:id/pipeline_stats`

### Issue 2: FilterService#validate_query_operator NoMethodError (500)
- **Expected:** Filter contacts by `pipeline_stage_id` works
- **Actual:** `undefined method 'each' for nil` at `filter_service.rb:189`
- **Cause:** `query_params` is nil when filtering contacts by `pipeline_stage_id`
- **Root cause:** `validate_query_operator` calls `@params[:payload].each` without checking if `payload` is nil

### Issue 3: Cache keys API called 3 times redundantly
- **Expected:** `cache_keys` API called once per dashboard load
- **Actual:** Called 3 times (labels, teams, inboxes all trigger parallel cache checks)
- **Cause:** `CacheEnabledApiClient.getFromCache()` calls `axios.get(/cache_keys)` directly for each subclass instance
- **Root cause:** No memoization of the cache_keys API call across concurrent `getFromCache()` invocations

## Resolution

### Issue 1: pipeline_stats route fix
**File:** `config/routes.rb`

**Root cause:** Route `get :pipeline_stats` was present but missing controller specification. Rails treated it as a `pipeline_stats` action on `AccountsController` instead of routing to `PipelineStatsController#index`.

**Fix:** Changed `get :pipeline_stats` to `get :pipeline_stats, to: 'pipeline_stats#index'`

```ruby
# Before
get :pipeline_stats

# After
get :pipeline_stats, to: 'pipeline_stats#index'
```

### Issue 2: FilterService nil check
**File:** `app/services/filter_service.rb`

**Root cause:** `validate_query_operator` method calls `@params[:payload].each` without checking if `@params[:payload]` is nil.

**Fix:** Added null check before iterating:

```ruby
def validate_query_operator
  return if @params[:payload].nil?

  @params[:payload].each do |query_hash|
    validate_single_condition(query_hash)
  end
end
```

### Issue 3: Cache keys deduplication
**File:** `app/javascript/dashboard/api/CacheEnabledApiClient.js`

**Root cause:** `getFromCache()` makes a direct `axios.get(/cache_keys)` call. When multiple cache-enabled API classes (Labels, Teams, Inboxes) all call `getFromCache()` in parallel on page load, each triggers its own `/cache_keys` fetch before resolving.

**Fix:** Added memoization of the cache_keys promise in the constructor and used it in `getFromCache()`:

```javascript
// In constructor:
this._cacheKeysPromise = null;

// In getFromCache():
if (!this._cacheKeysPromise) {
  this._cacheKeysPromise = axios.get(
    `/api/v1/accounts/${this.accountIdFromRoute}/cache_keys`
  );
}
const { data } = await this._cacheKeysPromise;
```

This ensures only one `/cache_keys` request is made even when multiple CacheEnabledApiClient subclasses call `getFromCache()` concurrently.

## Files Changed

1. `config/routes.rb` - Pipeline stats route fix
2. `app/services/filter_service.rb` - Null check for payload
3. `app/javascript/dashboard/api/CacheEnabledApiClient.js` - Memoization of cache_keys API call

## Verification

- Issue 1: Route now correctly routes to `PipelineStatsController#index`
- Issue 2: Filter service handles nil payload gracefully
- Issue 3: Only one cache_keys API call per dashboard load regardless of concurrent CacheEnabledApiClient usage