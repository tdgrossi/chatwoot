# == Schema Information
#
# Table name: pipeline_stages
#
#  id         :bigint           not null, primary key
#  color      :string
#  name       :string           not null
#  position   :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_pipeline_stages_on_account_id               (account_id)
#  index_pipeline_stages_on_account_id_and_position  (account_id,position) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
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
