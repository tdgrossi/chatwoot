class AddCachedLabelsList < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :cached_label_list, :string
    Conversation.reset_column_information
    # ActsAsTaggableOn::Taggable::Cache.included(Conversation)
    # Note: This line was removed as ActsAsTaggableOn 12.0.0 no longer has Cache.included method
  end
end
