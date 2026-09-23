# 상위·하위를 갖는 분류(카테고리, 도메인)가 함께 쓰는 트리 동작.
#
# 분류는 많아야 수십 개라 재귀 쿼리 대신 한 번에 다 읽어 메모리에서 트리를 만든다.
# 수천 개가 되면 재귀 CTE 로 바꿀 자리가 여기 한 곳이다.
module Treeable
  extend ActiveSupport::Concern

  # 대분류 → 중분류 → 소분류. 더 깊으면 사이드바에서 찾기 어려워진다.
  MAX_DEPTH = 3

  included do
    belongs_to :parent, class_name: name, optional: true, inverse_of: :children
    has_many :children, -> { order(:position, :name) }, class_name: name,
             foreign_key: :parent_id, inverse_of: :parent, dependent: :restrict_with_error

    scope :roots, -> { where(parent_id: nil) }

    validate :parent_must_not_form_a_cycle
    validate :depth_must_stay_within_limit
  end

  class_methods do
    # 부모 다음에 자식, 형제끼리는 position 순으로 편 목록. [[node, depth], ...]
    def in_tree_order(nodes = all.to_a)
      by_parent = group_children(nodes)
      rows = []
      walk = lambda do |parent_id, depth|
        by_parent.fetch(parent_id, []).each do |node|
          rows << [ node, depth ]
          walk.call(node.id, depth + 1)
        end
      end
      walk.call(nil, 0)
      rows
    end

    # 고른 분류와 그 아래 전부의 id. 상위를 고르면 하위 문서까지 보이게 하려고 쓴다.
    def subtree_ids_for(slug)
      nodes = all.to_a
      root = nodes.find { |node| node.slug == slug.to_s }
      root ? collect_subtree_ids(root.id, group_children(nodes)) : []
    end

    def group_children(nodes)
      nodes.group_by(&:parent_id).transform_values { |list| list.sort_by { |node| [ node.position, node.name ] } }
    end

    def collect_subtree_ids(id, by_parent)
      [ id ] + by_parent.fetch(id, []).flat_map { |child| collect_subtree_ids(child.id, by_parent) }
    end
  end

  # 맨 위부터 바로 위까지. 순환이 있더라도 멈추도록 이미 본 것은 건너뛴다.
  def ancestors
    chain = []
    seen = Set[id]
    node = parent
    while node && seen.add?(node.id)
      chain.unshift(node)
      node = node.parent
    end
    chain
  end

  def path_names
    (ancestors + [ self ]).map(&:name)
  end

  def depth
    ancestors.size
  end

  def descendant_ids
    return [] unless persisted?

    self.class.collect_subtree_ids(id, self.class.group_children(self.class.all.to_a)) - [ id ]
  end

  private

  def parent_must_not_form_a_cycle
    return if parent_id.nil? || !persisted?
    return unless parent_id == id || descendant_ids.include?(parent_id)

    errors.add(:base, "자기 자신이나 자기 아래 항목을 상위로 고를 수 없습니다.")
  end

  def depth_must_stay_within_limit
    return if parent.nil?

    # 새 자리의 깊이에, 내 아래로 딸린 단계까지 더해 본다. 통째로 옮기는 경우 때문이다.
    if parent.depth + 1 + height_below >= MAX_DEPTH
      errors.add(:base, "#{MAX_DEPTH}단계까지만 둘 수 있습니다. 더 위에 두거나 아래 항목을 먼저 옮겨 주세요.")
    end
  end

  def height_below
    return 0 unless persisted?

    by_parent = self.class.group_children(self.class.all.to_a)
    measure = ->(node_id) { by_parent.fetch(node_id, []).map { |child| 1 + measure.(child.id) }.max || 0 }
    measure.(id)
  end
end
