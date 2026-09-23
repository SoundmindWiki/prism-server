require "test_helper"

# 카테고리·태그·문서 관리는 성격이 같아 한곳에서 본다.
class Api::V1::Admin::CatalogControllerTest < ActionDispatch::IntegrationTest
  setup { @headers = auth_headers(users(:boss)) }

  # ---- 카테고리 ----
  test "카테고리를 추가하면 맨 뒤에 붙는다" do
    post api_v1_admin_categories_url,
         params: { category: { name: "마케팅", color: "rose" } },
         headers: @headers,
         as: :json

    assert_response :created
    assert_equal "마케팅", json_body.dig("category", "slug")
    assert_equal 3, json_body.dig("category", "position")
  end

  test "카테고리 이름은 고쳐도 주소는 그대로 둔다" do
    patch api_v1_admin_category_url("dev"),
          params: { category: { name: "엔지니어링", slug: "engineering" } },
          headers: @headers,
          as: :json

    assert_response :success
    assert_equal "엔지니어링", categories(:dev).reload.name
    assert_equal "dev", categories(:dev).slug
  end

  test "문서가 남은 카테고리는 지울 수 없다" do
    delete api_v1_admin_category_url("dev"), headers: @headers

    assert_response :unprocessable_entity
    assert Category.exists?(categories(:dev).id)
  end

  test "빈 카테고리는 지울 수 있다" do
    empty = Category.create!(name: "빈칸", slug: "empty")

    assert_difference -> { Category.count }, -1 do
      delete api_v1_admin_category_url("empty"), headers: @headers
    end

    assert_response :no_content
    assert_not Category.exists?(empty.id)
  end

  test "순서를 통째로 바꾼다" do
    post reorder_api_v1_admin_categories_url,
         params: { slugs: %w[office dev] },
         headers: @headers,
         as: :json

    assert_response :success
    assert_equal %w[office dev], json_body["categories"].map { |category| category["slug"] }
  end

  # ---- 태그 ----
  test "태그 이름을 바꾸면 주소도 따라간다" do
    patch api_v1_admin_tag_url(tags(:review).slug),
          params: { tag: { name: "리뷰" } },
          headers: @headers,
          as: :json

    assert_response :success
    assert_equal "리뷰", tags(:review).reload.name
    assert_equal "리뷰", tags(:review).slug
  end

  test "태그를 합치면 문서가 옮겨 가고 원래 태그는 사라진다" do
    prompt = prompts(:code_review)
    assert_equal [ "코드리뷰" ], prompt.tag_names

    assert_difference -> { Tag.count }, -1 do
      post merge_api_v1_admin_tag_url(tags(:review).slug),
           params: { into: tags(:meeting).slug },
           headers: @headers,
           as: :json
    end

    assert_response :success
    assert_equal 1, json_body["moved"]
    assert_equal [ "회의" ], prompt.reload.tag_names
  end

  test "이미 같은 태그를 단 문서는 중복으로 붙지 않는다" do
    prompts(:code_review).update!(tag_names: %w[코드리뷰 회의])

    post merge_api_v1_admin_tag_url(tags(:review).slug),
         params: { into: tags(:meeting).slug },
         headers: @headers,
         as: :json

    assert_response :success
    assert_equal 0, json_body["moved"]
    assert_equal [ "회의" ], prompts(:code_review).reload.tag_names
  end

  test "자기 자신과는 합칠 수 없다" do
    post merge_api_v1_admin_tag_url(tags(:review).slug),
         params: { into: tags(:review).slug },
         headers: @headers,
         as: :json

    assert_response :unprocessable_entity
  end

  # ---- 문서 ----
  test "백오피스 목록에는 보관된 문서도 나온다" do
    get api_v1_admin_prompts_url, headers: @headers

    slugs = json_body["prompts"].map { |prompt| prompt["slug"] }
    assert_includes slugs, prompts(:retired).slug
    assert_equal 3, json_body.dig("meta", "total")
  end

  test "상태로 거른다" do
    get api_v1_admin_prompts_url, params: { status: "archived" }, headers: @headers

    assert_equal [ prompts(:retired).slug ], json_body["prompts"].map { |prompt| prompt["slug"] }
  end

  test "상태를 바꾸면 기록이 남는다" do
    assert_difference -> { AuditLog.where(action: "prompt.status_changed").count }, 1 do
      patch api_v1_admin_prompt_url(prompts(:code_review).slug),
            params: { prompt: { status: "draft" } },
            headers: @headers,
            as: :json
    end

    assert_response :success
    assert_predicate prompts(:code_review).reload, :draft?
  end

  test "알 수 없는 상태는 거절한다" do
    patch api_v1_admin_prompt_url(prompts(:code_review).slug),
          params: { prompt: { status: "이상한상태" } },
          headers: @headers,
          as: :json

    assert_response :unprocessable_entity
  end

  test "백오피스에서는 문서를 히스토리까지 지울 수 있다" do
    prompt = prompts(:code_review)

    assert_difference -> { PromptVersion.count }, -prompt.versions.count do
      delete api_v1_admin_prompt_url(prompt.slug), headers: @headers
    end

    assert_response :no_content
    assert_not Prompt.exists?(prompt.id)
    assert AuditLog.exists?(action: "prompt.destroyed")
  end

  # ---- 카테고리 트리 ----
  test "카테고리를 다른 카테고리 아래로 옮길 수 있다" do
    patch api_v1_admin_category_url("office"), params: { category: { parent_slug: "dev" } }, headers: @headers, as: :json

    assert_response :success
    assert_equal categories(:dev), categories(:office).reload.parent
    assert_equal [ "개발", "공통 사무" ], json_body.dig("category", "path")
  end

  test "하위 카테고리가 있으면 비어 있어도 지우지 못한다" do
    parent = Category.create!(name: "빈 상위", slug: "empty-parent")
    Category.create!(name: "빈 하위", slug: "empty-child", parent: parent)

    delete api_v1_admin_category_url("empty-parent"), headers: @headers

    assert_response :unprocessable_entity
    assert Category.exists?(parent.id)
  end
end
