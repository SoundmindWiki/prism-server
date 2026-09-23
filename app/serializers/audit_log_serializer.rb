module AuditLogSerializer
  module_function

  def call(log)
    {
      id: log.id,
      action: log.action,
      label: log.label,
      group: log.group,
      user_id: log.user_id,
      actor_name: log.actor_name,
      target_type: log.target_type,
      target_label: log.target_label,
      # 문서에 대한 기록이면 이걸로 바로 열어 볼 수 있다
      slug: log.details["slug"],
      details: log.details.except("slug"),
      created_at: log.created_at
    }
  end
end
