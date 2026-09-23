# Postgres 에서는 json 보다 jsonb 가 낫다. 색인도 되고 비교도 된다.
class ChangeVariablesToJsonb < ActiveRecord::Migration[8.1]
  def up
    change_column :prompts, :variables, :jsonb, using: "variables::jsonb", default: [], null: false
    change_column :prompt_versions, :variables, :jsonb, using: "variables::jsonb", default: [], null: false
  end

  def down
    change_column :prompts, :variables, :json, using: "variables::json", default: [], null: false
    change_column :prompt_versions, :variables, :json, using: "variables::json", default: [], null: false
  end
end
