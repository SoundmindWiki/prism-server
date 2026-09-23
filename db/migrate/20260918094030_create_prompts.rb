class CreatePrompts < ActiveRecord::Migration[8.1]
  def change
    create_table :prompts do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :summary
      t.text :body, null: false
      t.text :usage_notes
      t.string :model_hint
      t.string :status, null: false, default: "published"
      t.references :category, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.references :last_editor, null: true, foreign_key: { to_table: :users }
      t.integer :copy_count, null: false, default: 0
      t.integer :view_count, null: false, default: 0
      t.json :variables, null: false, default: []

      t.timestamps
    end
    add_index :prompts, :slug, unique: true
    add_index :prompts, :status
    add_index :prompts, :updated_at
  end
end
