require "test_helper"

class Api::V1::CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup { @headers = auth_headers(users(:jiwon)) }

  test "카테고리마다 보이는 문서 수를 함께 준다" do
    get api_v1_categories_url, headers: @headers

    assert_response :success
    counts = json_body["categories"].to_h { |category| [ category["slug"], category["prompts_count"] ] }
    assert_equal 1, counts["dev"]
    assert_equal 1, counts["office"]
  end

  test "정해 둔 순서대로 나온다" do
    get api_v1_categories_url, headers: @headers

    assert_equal %w[dev office], json_body["categories"].map { |category| category["slug"] }
  end

  test "로그인하지 않으면 볼 수 없다" do
    get api_v1_categories_url

    assert_response :unauthorized
  end

  test "하위 카테고리는 상위 바로 다음에 깊이·경로와 함께 나오고, 상위 합계에 들어간다" do
    Category.create!(name: "회의", slug: "meeting", parent: categories(:dev), position: 1)
    prompts(:meeting_notes).update!(category: Category.find_by!(slug: "meeting"))

    get api_v1_categories_url, headers: @headers

    rows = json_body["categories"]
    assert_equal %w[dev meeting office], rows.map { |row| row["slug"] }

    meeting = rows.find { |row| row["slug"] == "meeting" }
    assert_equal [ 1, %w[개발 회의], "dev" ], meeting.values_at("depth", "path", "parent_slug")

    dev = rows.find { |row| row["slug"] == "dev" }
    assert_equal [ 1, 2 ], dev.values_at("prompts_count", "total_count")
    assert_equal "indigo", dev["color"]
  end

  # ---- 사이드바에서 폴더 만들기 ----

  test "팀 폴더 아래에 하위 폴더를 만든다. 색과 자리는 알아서 정한다" do
    assert_difference -> { Category.count }, 1 do
      post api_v1_categories_url, params: { category: { name: "접근성", parent_slug: "dev" } }, headers: @headers, as: :json
    end

    assert_response :created
    folder = Category.find_by!(name: "접근성")
    assert_equal categories(:dev), folder.parent
    assert_equal categories(:dev).color, folder.color
    assert_equal "접근성", folder.slug
    assert_equal %w[개발 접근성], json_body.dig("category", "path")
  end

  test "맨 위 폴더는 여기서 못 만든다" do
    assert_no_difference -> { Category.count } do
      post api_v1_categories_url, params: { category: { name: "새 팀" } }, headers: @headers, as: :json
    end

    assert_response :unprocessable_entity
    assert_includes json_body["detail"], "백오피스"
  end

  test "이름이 비면 거절한다" do
    post api_v1_categories_url, params: { category: { name: " ", parent_slug: "dev" } }, headers: @headers, as: :json

    assert_response :unprocessable_entity
  end

  test "4단계는 막는다" do
    second = Category.create!(name: "2단계", slug: "level-2", color: "slate", parent: categories(:dev))
    Category.create!(name: "3단계", slug: "level-3", color: "slate", parent: second)

    post api_v1_categories_url, params: { category: { name: "4단계", parent_slug: "level-3" } }, headers: @headers, as: :json

    assert_response :unprocessable_entity
  end

  test "폴더를 만들면 활동 기록에 남는다" do
    post api_v1_categories_url, params: { category: { name: "접근성", parent_slug: "dev" } }, headers: @headers, as: :json

    log = AuditLog.order(:id).last
    assert_equal [ "folder.created", "content", "접근성", "개발" ], [ log.action, log.group, log.target_label, log.details["parent"] ]
  end

  test "로그인하지 않으면 폴더도 못 만든다" do
    post api_v1_categories_url, params: { category: { name: "접근성", parent_slug: "dev" } }, as: :json

    assert_response :unauthorized
  end
end
