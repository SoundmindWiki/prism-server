require "test_helper"

class Api::V1::Admin::DomainsControllerTest < ActionDispatch::IntegrationTest
  setup { @headers = auth_headers(users(:boss)) }

  def slugs_in(rows)
    rows.map { |row| row["slug"] }
  end

  test "트리 순서로 펴서 깊이·경로·문서 수와 함께 준다" do
    get api_v1_admin_domains_url, headers: @headers

    assert_response :success
    rows = json_body["domains"]
    assert_equal %w[finance banking insurance public], slugs_in(rows)

    bank = rows.find { |row| row["slug"] == "banking" }
    assert_equal 1, bank["depth"]
    assert_equal "finance", bank["parent_slug"]
    assert_equal %w[금융/보험 은행], bank["path"]

    finance = rows.find { |row| row["slug"] == "finance" }
    assert finance["has_children"]
    assert_equal 0, finance["prompts_count"]
    assert_equal 1, finance["total_count"], "하위(은행)에 달린 문서까지 합친다"
  end

  test "맨 위에 추가하면 맨 뒤에 붙고 기록이 남는다" do
    post api_v1_admin_domains_url, params: { domain: { name: "제조", slug: "manufacturing" } }, headers: @headers, as: :json

    assert_response :created
    assert_equal 0, json_body.dig("domain", "depth")
    assert_equal 3, json_body.dig("domain", "position")
    assert_equal "domain.created", AuditLog.order(:id).last.action
  end

  test "상위를 골라 추가하면 그 아래 맨 뒤에 붙는다" do
    post api_v1_admin_domains_url,
         params: { domain: { name: "증권", parent_slug: "finance" } },
         headers: @headers,
         as: :json

    assert_response :created
    assert_equal "finance", json_body.dig("domain", "parent_slug")
    assert_equal 3, json_body.dig("domain", "position")
    assert_equal "금융/보험", AuditLog.order(:id).last.details["parent"]
  end

  test "없는 상위를 고르면 찾을 수 없다고 한다" do
    post api_v1_admin_domains_url, params: { domain: { name: "증권", parent_slug: "nope" } }, headers: @headers, as: :json

    assert_response :not_found
  end

  test "상위를 바꾸면 새 자리 맨 뒤로 가고 옮긴 기록이 남는다" do
    patch api_v1_admin_domain_url("banking"), params: { domain: { parent_slug: "public" } }, headers: @headers, as: :json

    assert_response :success
    assert_equal domains(:public), domains(:bank).reload.parent
    assert_equal 1, domains(:bank).position
    assert_equal [ "금융/보험", "공공" ], AuditLog.order(:id).last.details["moved"]
  end

  test "상위를 비우면 맨 위로 올라간다" do
    patch api_v1_admin_domain_url("banking"), params: { domain: { parent_slug: "" } }, headers: @headers, as: :json

    assert_response :success
    assert_nil domains(:bank).reload.parent
    assert_equal 3, domains(:bank).position
  end

  test "이름만 고치면 자리는 그대로다" do
    patch api_v1_admin_domain_url("banking"), params: { domain: { name: "은행·저축은행" } }, headers: @headers, as: :json

    assert_response :success
    assert_equal domains(:finance), domains(:bank).reload.parent
    assert_equal 1, domains(:bank).position
    assert_nil AuditLog.order(:id).last.details["moved"]
  end

  test "자기 아래로는 옮길 수 없다" do
    patch api_v1_admin_domain_url("finance"), params: { domain: { parent_slug: "banking" } }, headers: @headers, as: :json

    assert_response :unprocessable_entity
    assert_nil domains(:finance).reload.parent
  end

  test "하위가 있으면 지우지 못한다" do
    delete api_v1_admin_domain_url("finance"), headers: @headers

    assert_response :unprocessable_entity
    assert_includes json_body["error"], "하위 항목"
  end

  test "지우면 문서에서 떨어지기만 하고 문서는 남는다" do
    prompt = prompts(:meeting_notes)

    assert_difference -> { PromptDomain.count }, -1 do
      delete api_v1_admin_domain_url("banking"), headers: @headers
    end

    assert_response :no_content
    assert Prompt.exists?(prompt.id)
    assert_empty prompt.reload.domains
    assert_equal 1, AuditLog.order(:id).last.details["detached"]
  end

  test "같은 상위 아래끼리 순서를 바꾼다" do
    post reorder_api_v1_admin_domains_url, params: { slugs: %w[insurance banking] }, headers: @headers, as: :json

    assert_response :success
    assert_equal %w[finance insurance banking public], slugs_in(json_body["domains"])
  end

  test "상위가 다른 것끼리는 순서를 섞을 수 없다" do
    post reorder_api_v1_admin_domains_url, params: { slugs: %w[banking public] }, headers: @headers, as: :json

    assert_response :unprocessable_entity
  end

  test "관리자가 아니면 손댈 수 없다" do
    post api_v1_admin_domains_url, params: { domain: { name: "제조" } }, headers: auth_headers(users(:jiwon)), as: :json

    assert_response :forbidden
  end
end
