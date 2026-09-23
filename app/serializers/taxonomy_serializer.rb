# 트리 분류(카테고리, 도메인)를 화면에 넘길 때 쓰는 공통 모양.
#
# 중첩된 JSON 대신 "트리 순서로 편 목록" 에 깊이와 상위 id 를 붙여 넘긴다.
# 사이드바는 이걸로 트리를 다시 짜고, 백오피스는 들여쓴 표로 그대로 그린다.
module TaxonomySerializer
  module_function

  # 문서 수는 둘 중 하나로 받는다.
  #   direct_counts: { 분류 id => 바로 달린 문서 수 }. 문서마다 분류가 하나뿐일 때(카테고리) 쓴다.
  #   prompt_ids:    { 분류 id => 바로 달린 문서 id 목록 }. 한 문서가 여러 분류에 걸칠 때(도메인) 쓴다.
  #                  하위 두 곳에 같이 달린 문서를 상위 합계에서 두 번 세지 않으려는 것이다.
  def rows(model, nodes, direct_counts: {}, prompt_ids: nil)
    by_id = nodes.index_by(&:id)
    by_parent = model.group_children(nodes)

    if prompt_ids
      direct_counts = prompt_ids.transform_values { |ids| ids.uniq.size }
      subtree_ids = Hash.new do |memo, id|
        memo[id] = by_parent.fetch(id, []).reduce(Set.new(prompt_ids.fetch(id, []))) { |set, child| set | memo[child.id] }
      end
      total = Hash.new { |memo, id| memo[id] = subtree_ids[id].size }
    else
      total = Hash.new do |memo, id|
        memo[id] = direct_counts.fetch(id, 0) + by_parent.fetch(id, []).sum { |child| memo[child.id] }
      end
    end

    model.in_tree_order(nodes).map do |node, depth|
      path = []
      cursor = node
      while cursor
        path.unshift(cursor.name)
        cursor = by_id[cursor.parent_id]
      end

      {
        id: node.id,
        name: node.name,
        slug: node.slug,
        description: node.description,
        position: node.position,
        parent_id: node.parent_id,
        parent_slug: by_id[node.parent_id]&.slug,
        depth: depth,
        path: path,
        has_children: by_parent.key?(node.id),
        # 바로 달린 문서 수와, 아래 분류까지 합친 문서 수를 둘 다 준다.
        prompts_count: direct_counts.fetch(node.id, 0),
        total_count: total[node.id]
      }.merge(block_given? ? yield(node).to_h : {})
    end
  end
end
