module DomainSerializer
  module_function

  def call(domain)
    { id: domain.id, name: domain.name, slug: domain.slug, path: domain.path_names }
  end

  # memberships: PromptDomain 스코프. 어느 문서까지 셀지는 부르는 쪽이 정한다.
  def tree(nodes, memberships:)
    prompt_ids = memberships.pluck(:domain_id, :prompt_id).group_by(&:first).transform_values { |pairs| pairs.map(&:last) }
    TaxonomySerializer.rows(Domain, nodes, prompt_ids: prompt_ids)
  end
end
