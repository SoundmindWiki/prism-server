# 문서 하나가 여러 도메인에 걸칠 수 있다. "장애 고객 공지" 는 금융에도 공공에도 쓴다.
class CreatePromptDomains < ActiveRecord::Migration[8.1]
  def change
    create_table :prompt_domains do |t|
      t.references :prompt, null: false, foreign_key: true
      t.references :domain, null: false, foreign_key: true

      t.timestamps
    end

    add_index :prompt_domains, [ :prompt_id, :domain_id ], unique: true
  end
end
