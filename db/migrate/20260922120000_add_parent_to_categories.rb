# 카테고리도 상위·하위를 둘 수 있게 한다. 기존 카테고리는 전부 맨 위(루트)로 남는다.
class AddParentToCategories < ActiveRecord::Migration[8.1]
  def change
    add_reference :categories, :parent, null: true, foreign_key: { to_table: :categories }
    add_index :categories, [ :parent_id, :position ]
  end
end
