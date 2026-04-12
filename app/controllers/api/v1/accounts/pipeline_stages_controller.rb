class Api::V1::Accounts::PipelineStagesController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :fetch_pipeline_stage, except: [:index, :create]
  before_action :check_authorization

  def index
    @pipeline_stages = Current.account.pipeline_stages.sorted
    render json: @pipeline_stages
  end

  def show
    render json: @pipeline_stage
  end

  def create
    @pipeline_stage = Current.account.pipeline_stages.new(permitted_params)
    @pipeline_stage.save!
    render json: @pipeline_stage, status: :created
  end

  def update
    @pipeline_stage.update!(permitted_params)
    render json: @pipeline_stage
  end

  def destroy
    Contact.where(pipeline_stage_id: @pipeline_stage.id).update_all(pipeline_stage_id: nil)
    @pipeline_stage.destroy!
    head :ok
  end

  def move
    case params[:direction]
    when 'up', 'down'
      if params[:direction] == 'down'
        swap_with = @pipeline_stage.lower_item
      else
        swap_with = @pipeline_stage.higher_item
      end
      return head :ok if swap_with.nil?

      # Swap positions atomically: set both to a temporary value first
      # (avoiding the unique constraint violation), then set to final values.
      temp = -1
      PipelineStage.where(id: [@pipeline_stage.id, swap_with.id])
                   .update_all(["position = CASE id WHEN ? THEN ? WHEN ? THEN ? END",
                                swap_with.id, temp,
                                @pipeline_stage.id, temp])
      PipelineStage.where(id: [@pipeline_stage.id, swap_with.id])
                   .update_all(["position = CASE id WHEN ? THEN ? WHEN ? THEN ? END",
                                swap_with.id, @pipeline_stage.position,
                                @pipeline_stage.id, swap_with.position])
      head :ok
    else
      render json: { error: 'direction must be "up" or "down"' }, status: :unprocessable_entity
    end
  end

  private

  def fetch_pipeline_stage
    @pipeline_stage = Current.account.pipeline_stages.find(params[:id])
  end

  def permitted_params
    params.require(:pipeline_stage).permit(:name, :color)
  end
end
