class Api::V1::Accounts::PipelineStagesController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :fetch_pipeline_stage, except: [:index, :create]
  before_action :check_authorization

  def index
    @pipeline_stages = Current.account.pipeline_stages.sorted
  end

  def show; end

  def create
    @pipeline_stage = Current.account.pipeline_stages.new(permitted_params)
    @pipeline_stage.save!
  end

  def update
    @pipeline_stage.update!(permitted_params)
  end

  def destroy
    Contact.where(pipeline_stage_id: @pipeline_stage.id).update_all(pipeline_stage_id: nil)
    @pipeline_stage.destroy!
    head :ok
  end

  def move
    case params[:direction]
    when 'up'
      @pipeline_stage.move_higher
    when 'down'
      @pipeline_stage.move_lower
    else
      render json: { error: 'direction must be "up" or "down"' }, status: :unprocessable_entity
      return
    end
    head :ok
  end

  private

  def fetch_pipeline_stage
    @pipeline_stage = Current.account.pipeline_stages.find(params[:id])
  end

  def permitted_params
    params.require(:pipeline_stage).permit(:name, :color)
  end
end
