module PromptSerializer
  module_function

  # 목록 카드에 필요한 만큼만. 본문은 통째로 싣지 않는다.
  def summary(prompt)
    {
      id: prompt.id,
      slug: prompt.slug,
      title: prompt.title,
      summary: prompt.summary,
      excerpt: prompt.body.to_s.truncate(180),
      status: prompt.status,
      model_hint: prompt.model_hint,
      copy_count: prompt.copy_count,
      view_count: prompt.view_count,
      variable_count: Array(prompt.variables).size,
      category: CategorySerializer.call(prompt.category),
      domains: prompt.domains.sort_by(&:name).map { |domain| DomainSerializer.call(domain) },
      author: UserSerializer.call(prompt.author),
      last_editor: UserSerializer.call(prompt.last_editor),
      tags: prompt.tags.map { |tag| TagSerializer.call(tag) },
      created_at: prompt.created_at,
      updated_at: prompt.updated_at
    }
  end

  def detail(prompt)
    summary(prompt).merge(
      body: prompt.body,
      usage_notes: prompt.usage_notes,
      variables: Array(prompt.variables),
      version_count: prompt.latest_version_number
    )
  end
end
