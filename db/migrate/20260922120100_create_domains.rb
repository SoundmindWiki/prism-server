# 도메인(산업 분야). 제조 · 금융/보험 · 공공 처럼 문서를 쓰는 "업계" 로 나누는 두 번째 축이다.
# 카테고리가 "어느 팀 것" 이라면 도메인은 "어느 업계에 쓰는 것" 이다.
class CreateDomains < ActiveRecord::Migration[8.1]
  def change
    create_table :domains do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.references :parent, null: true, foreign_key: { to_table: :domains }
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :domains, :slug, unique: true
    add_index :domains, [ :parent_id, :position ]
  end
end
