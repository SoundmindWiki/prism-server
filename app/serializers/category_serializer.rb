module CategorySerializer
  module_function

  # 문서 안에 붙여 보낼 때 쓴다. 경로는 미리 읽어 둔 부모에서 뽑는다.
  def call(category, prompts_count: nil)
    row = {
      id: category.id,
      name: category.name,
      slug: category.slug,
      description: category.description,
      color: category.color,
      position: category.position,
      parent_id: category.parent_id,
      path: category.path_names
    }
    prompts_count.nil? ? row : row.merge(prompts_count: prompts_count)
  end

  def tree(nodes, direct_counts: {})
    TaxonomySerializer.rows(Category, nodes, direct_counts: direct_counts) { |node| { color: node.color } }
  end
end
