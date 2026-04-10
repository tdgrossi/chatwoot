# frozen_string_literal: true

FactoryBot.define do
  factory :pipeline_stage do
    account
    sequence(:name) { |n| "Stage #{n}" }
    color { '#22C55E' }
  end
end
