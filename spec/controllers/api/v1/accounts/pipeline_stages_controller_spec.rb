require 'rails_helper'

RSpec.describe 'PipelineStages API', type: :request do
  let!(:account) { create(:account) }
  let!(:pipeline_stage) { create(:pipeline_stage, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/pipeline_stages' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/pipeline_stages"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'returns all pipeline stages ordered by position' do
        get "/api/v1/accounts/#{account.id}/pipeline_stages",
            headers: admin.create_new_auth_token,
            as: :json
        expect(response).to have_http_status(:success)
        expect(response.body).to include(pipeline_stage.name)
      end
    end

    context 'when it is an authenticated agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns forbidden' do
        get "/api/v1/accounts/#{account.id}/pipeline_stages",
            headers: agent.create_new_auth_token,
            as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/pipeline_stages/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/pipeline_stages/#{pipeline_stage.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'shows the pipeline stage' do
        get "/api/v1/accounts/#{account.id}/pipeline_stages/#{pipeline_stage.id}",
            headers: admin.create_new_auth_token,
            as: :json
        expect(response).to have_http_status(:success)
        expect(response.body).to include(pipeline_stage.name)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/pipeline_stages' do
    let(:valid_params) { { pipeline_stage: { name: 'Qualified', color: '#3B82F6' } } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect { post "/api/v1/accounts/#{account.id}/pipeline_stages", params: valid_params }.not_to change(PipelineStage, :count)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'creates a pipeline stage' do
        expect do
          post "/api/v1/accounts/#{account.id}/pipeline_stages",
               headers: admin.create_new_auth_token,
               params: valid_params
        end.to change(PipelineStage, :count).by(1)
        expect(response).to have_http_status(:success)
      end
    end

    context 'when it is an authenticated agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns forbidden' do
        post "/api/v1/accounts/#{account.id}/pipeline_stages",
             headers: agent.create_new_auth_token,
             params: valid_params
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/pipeline_stages/:id' do
    let(:valid_params) { { pipeline_stage: { name: 'Won' } } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/pipeline_stages/#{pipeline_stage.id}",
              params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'updates the pipeline stage' do
        patch "/api/v1/accounts/#{account.id}/pipeline_stages/#{pipeline_stage.id}",
              headers: admin.create_new_auth_token,
              params: valid_params,
              as: :json
        expect(response).to have_http_status(:success)
        expect(pipeline_stage.reload.name).to eq('Won')
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/pipeline_stages/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/pipeline_stages/#{pipeline_stage.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'destroys the pipeline stage' do
        expect do
          delete "/api/v1/accounts/#{account.id}/pipeline_stages/#{pipeline_stage.id}",
                 headers: admin.create_new_auth_token
        end.to change(PipelineStage, :count).by(-1)
        expect(response).to have_http_status(:ok)
      end

      it 'nullifies pipeline_stage_id on contacts before destroying' do
        contact = create(:contact, account: account, pipeline_stage: pipeline_stage)
        delete "/api/v1/accounts/#{account.id}/pipeline_stages/#{pipeline_stage.id}",
               headers: admin.create_new_auth_token
        expect(contact.reload.pipeline_stage_id).to be_nil
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/pipeline_stages/:id/move' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/pipeline_stages/#{pipeline_stage.id}/move",
              params: { direction: 'down' }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let!(:stage1) { create(:pipeline_stage, account: account, name: 'Stage 1', position: 1) }
      let!(:stage2) { create(:pipeline_stage, account: account, name: 'Stage 2', position: 2) }

      it 'moves a stage down' do
        patch "/api/v1/accounts/#{account.id}/pipeline_stages/#{stage1.id}/move",
              headers: admin.create_new_auth_token,
              params: { direction: 'down' },
              as: :json
        expect(response).to have_http_status(:ok)
        expect(stage1.reload.position).to be > stage2.reload.position
      end

      it 'moves a stage up' do
        patch "/api/v1/accounts/#{account.id}/pipeline_stages/#{stage2.id}/move",
              headers: admin.create_new_auth_token,
              params: { direction: 'up' },
              as: :json
        expect(response).to have_http_status(:ok)
        expect(stage2.reload.position).to be < stage1.reload.position
      end

      it 'returns unprocessable_entity for invalid direction' do
        patch "/api/v1/accounts/#{account.id}/pipeline_stages/#{stage1.id}/move",
              headers: admin.create_new_auth_token,
              params: { direction: 'invalid' },
              as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
