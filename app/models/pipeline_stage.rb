# == Schema Information
#
# Table name: pipeline_stages
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  position   :integer          not null
#  color      :string
#  account_id :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_pipeline_stages_on_account_id          (account_id)
#  index_pipeline_stages_on_account_id_position (account_id, position)
#

class PipelineStage < ApplicationRecord
  belongs_to :account
  acts_as_list scope: :account

  validates :name, presence: true
  validates :color, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: I18n.t('errors.pipeline_stage.color.invalid') }, allow_blank: true

  scope :sorted, -> { order(:position) }

  def color_with_hash
    color.present? ? color : '#6B7280'
  end
end
