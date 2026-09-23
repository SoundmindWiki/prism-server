class CreatePromptTags < ActiveRecord::Migration[8.1]
  def change
    create_table :prompt_tags do |t|
      t.references :prompt, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end
    add_index :prompt_tags, [ :prompt_id, :tag_id ], unique: true
  end
end
