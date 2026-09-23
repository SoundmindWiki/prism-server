require "test_helper"

# 트리 동작은 카테고리와 도메인이 같이 쓴다. 여기서는 도메인으로 본다.
class TreeableTest < ActiveSupport::TestCase
  setup do
    @finance = domains(:finance)
    @bank = domains(:bank)
  end

  test "트리 순서는 부모 다음에 자식, 형제끼리는 정한 순서" do
    order = Domain.in_tree_order.map { |node, depth| [ node.slug, depth ] }

    assert_equal [ [ "finance", 0 ], [ "banking", 1 ], [ "insurance", 1 ], [ "public", 0 ] ], order
  end

  test "상위를 고르면 하위까지 함께 잡힌다" do
    assert_equal [ @finance.id, @bank.id, domains(:insurance).id ].sort, Domain.subtree_ids_for("finance").sort
    assert_equal [ @bank.id ], Domain.subtree_ids_for("banking")
    assert_equal [], Domain.subtree_ids_for("없는분야")
  end

  test "경로와 깊이" do
    assert_equal %w[금융/보험 은행], @bank.path_names
    assert_equal 1, @bank.depth
    assert_equal 0, @finance.depth
  end

  test "자기 자신을 상위로 둘 수 없다" do
    @finance.parent = @finance

    assert_not @finance.valid?
    assert_includes @finance.errors[:base].join, "자기 자신"
  end

  test "자기 아래 항목을 상위로 둘 수 없다" do
    @finance.parent = @bank

    assert_not @finance.valid?
    assert_includes @finance.errors[:base].join, "자기 아래"
  end

  test "3단계까지는 된다" do
    third = Domain.new(name: "시중은행", slug: "commercial-bank", parent: @bank)

    assert third.valid?, third.errors.full_messages.to_sentence
  end

  test "4단계는 막는다" do
    Domain.create!(name: "시중은행", slug: "commercial-bank", parent: @bank)
    fourth = Domain.new(name: "너무 깊음", slug: "too-deep", parent: Domain.find_by!(slug: "commercial-bank"))

    assert_not fourth.valid?
    assert_includes fourth.errors[:base].join, "3단계"
  end

  test "하위를 거느린 채로 옮길 때는 딸린 단계까지 따진다" do
    # 금융/보험(2단계짜리 가지)을 공공 아래로 옮기면 은행이 3단계가 된다. 여기까지는 된다.
    @finance.parent = domains(:public)
    assert @finance.valid?, @finance.errors.full_messages.to_sentence

    # 은행 아래에 하나 더 있으면 옮긴 뒤 4단계가 되므로 막는다.
    Domain.create!(name: "시중은행", slug: "commercial-bank", parent: @bank)
    @finance.parent = domains(:public)
    assert_not @finance.valid?
  end

  test "하위가 있으면 바로 지워지지 않는다" do
    assert_not @finance.destroy
    assert Domain.exists?(@finance.id)
  end

  test "카테고리도 같은 트리 규칙을 따른다" do
    child = Category.create!(name: "프론트엔드", slug: "frontend", parent: categories(:dev))

    assert_equal %w[개발 프론트엔드], child.path_names
    assert_equal [ categories(:dev).id, child.id ].sort, Category.subtree_ids_for("dev").sort

    categories(:dev).parent = child
    assert_not categories(:dev).valid?
  end
end
