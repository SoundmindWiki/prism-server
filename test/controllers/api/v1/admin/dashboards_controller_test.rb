require "test_helper"

class Api::V1::Admin::DashboardsControllerTest < ActionDispatch::IntegrationTest
  setup { @headers = auth_headers(users(:boss)) }

  test "구성원·문서·세션 현황을 한 번에 준다" do
    get api_v1_admin_dashboard_url, headers: @headers

    assert_response :success
    assert_equal 5, json_body.dig("members", "total")
    assert_equal 4, json_body.dig("members", "active")
    assert_equal 2, json_body.dig("members", "admins")
    assert_equal 2, json_body.dig("content", "published")
    assert_equal 1, json_body.dig("content", "archived")
    assert_operator json_body.dig("sessions", "live"), :>=, 1
  end

  test "많이 고친 사람을 세어 준다" do
    get api_v1_admin_dashboard_url, headers: @headers

    names = json_body["top_contributors"].map { |row| row.dig("user", "name") }
    assert_includes names, "김지원"
  end

  test "오래 손대지 않은 문서를 찾아 준다" do
    prompts(:code_review).update_columns(updated_at: 5.months.ago)

    get api_v1_admin_dashboard_url, headers: @headers

    assert_equal [ prompts(:code_review).slug ], json_body["stale_prompts"].map { |prompt| prompt["slug"] }
  end

  test "일반 구성원은 볼 수 없다" do
    get api_v1_admin_dashboard_url, headers: auth_headers(users(:jiwon))

    assert_response :forbidden
  end

  test "최근 관리 활동에는 구성원이 복사한 기록 같은 건 섞이지 않는다" do
    AuditLog.record!(actor: users(:boss), action: "tag.destroyed", target_label: "옛태그")
    5.times { AuditLog.track(actor: users(:jiwon), action: "prompt.copied", target: prompts(:code_review)) }

    get api_v1_admin_dashboard_url, headers: @headers

    assert_equal [ "태그 삭제" ], json_body["recent_activity"].map { |log| log["label"] }
  end
end
