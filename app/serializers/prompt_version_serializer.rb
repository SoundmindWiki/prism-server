module PromptVersionSerializer
  module_function

  def call(version, previous: :lookup, include_body: false)
    payload = {
      version_number: version.version_number,
      title: version.title,
      summary: version.summary,
      model_hint: version.model_hint,
      change_note: version.change_note,
      changed_fields: version.changed_fields(previous),
      editor: UserSerializer.call(version.editor),
      created_at: version.created_at
    }

    include_body ? payload.merge(body: version.body, usage_notes: version.usage_notes) : payload
  end
end
