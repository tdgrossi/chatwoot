class AddPipelineStageToContacts < ActiveRecord::Migration[7.1]
  def change
    add_reference :contacts, :pipeline_stage, foreign_key: true, index: true, type: :bigint
  end
end
