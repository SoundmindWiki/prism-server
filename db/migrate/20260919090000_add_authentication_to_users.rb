class AddAuthenticationToUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.string :password_digest
      t.string :role, null: false, default: "member"
      t.boolean :active, null: false, default: true
      t.datetime :last_signed_in_at
    end

    add_index :users, :role
    add_index :users, :active
  end
end
