class CreatePromptVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :prompt_versions do |t|
      t.references :prompt, null: false, foreign_key: true
      t.references :editor, null: true, foreign_key: { to_table: :users }
      t.integer :version_number, null: false
      t.string :title, null: false
      t.text :body, null: false
      t.text :summary
      t.text :usage_notes
      t.string :model_hint
      t.string :change_note
      t.json :variables, null: false, default: []

      t.timestamps
    end
    add_index :prompt_versions, [ :prompt_id, :version_number ], unique: true
  end
end
