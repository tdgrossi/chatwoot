class Api::V1::Accounts::PipelineStatsController < Api::V1::Accounts::BaseController
  before_action :current_account

  # No check_authorization -- any authenticated account user can read stats (per D-09)

  def index
    render json: pipeline_stats
  end

  private

  def pipeline_stats
    cache_key = "pipeline_stats:account:#{Current.account.id}"

    cached = Redis::Alfred.get(cache_key)
    return JSON.parse(cached) if cached.present?

    stats = build_stats
    Redis::Alfred.setex(cache_key, 60, stats.to_json)
    stats
  end

  def build_stats
    Current.account.pipeline_stages.sorted.map do |stage|
      count = Contact.where(pipeline_stage_id: stage.id).count
      added_today = Contact.where(pipeline_stage_id: stage.id)
                           .where('created_at >= ?', Date.today.beginning_of_day)
                           .count

      {
        stage_id: stage.id,
        name: stage.name,
        count: count,
        added_today: added_today
      }
    end
  end
end
