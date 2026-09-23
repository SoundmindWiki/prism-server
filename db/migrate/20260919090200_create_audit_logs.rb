class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      # 남긴 사람이 지워져도 기록은 남아야 하므로 nullify 를 허용한다.
      t.references :user, null: true, foreign_key: { on_delete: :nullify }
      t.string :actor_name, null: false
      t.string :action, null: false
      t.string :target_type
      t.string :target_label
      t.jsonb :details, null: false, default: {}

      t.timestamps
    end

    add_index :audit_logs, :action
    add_index :audit_logs, :created_at
  end
end
