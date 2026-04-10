class CreatePipelineStages < ActiveRecord::Migration[7.1]
  def change
    create_table :pipeline_stages do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.integer :position, null: false
      t.string :color

      t.timestamps
    end

    add_index :pipeline_stages, [:account_id, :position], unique: true
  end
end
