require "test_helper"

class Api::V1::Admin::AuditLogsControllerTest < ActionDispatch::IntegrationTest
  setup { @headers = auth_headers(users(:boss)) }

  test "최근 것부터 보여 주고 사람이 읽을 이름을 붙인다" do
    AuditLog.record!(actor: users(:boss), action: "user.created", target: users(:jiwon))

    get api_v1_admin_audit_logs_url, headers: @headers

    assert_response :success
    first = json_body["logs"].first
    assert_equal "구성원 추가", first["label"]
    assert_equal "관리자", first["actor_name"]
    assert_equal "김지원", first["target_label"]
  end

  test "종류로 거른다" do
    AuditLog.record!(actor: users(:boss), action: "user.created", target: users(:jiwon))
    AuditLog.record!(actor: users(:boss), action: "tag.destroyed", target_label: "옛태그")

    get api_v1_admin_audit_logs_url, params: { action_type: "tag.destroyed" }, headers: @headers

    assert_equal [ "태그 삭제" ], json_body["logs"].map { |log| log["label"] }
  end

  test "남긴 사람이 사라져도 기록은 남는다" do
    temp = User.create!(name: "임시관리자", email: "temp@example.com", password: TEST_PASSWORD, role: :admin)
    AuditLog.record!(actor: temp, action: "tag.destroyed", target_label: "옛태그")
    temp.destroy!

    get api_v1_admin_audit_logs_url, headers: @headers

    log = json_body["logs"].find { |row| row["target_label"] == "옛태그" }
    assert_equal "임시관리자", log["actor_name"]
  end

  # ---- 구성원 활동 ----

  test "갈래로 거른다" do
    AuditLog.track(actor: users(:jiwon), action: "session.signed_in")
    AuditLog.track(actor: users(:jiwon), action: "prompt.copied", target: prompts(:code_review))
    AuditLog.record!(actor: users(:boss), action: "tag.destroyed", target_label: "옛태그")

    get api_v1_admin_audit_logs_url, params: { group: "usage" }, headers: @headers

    assert_equal [ "프롬프트 복사" ], json_body["logs"].map { |log| log["label"] }
    assert_equal "usage", json_body["logs"].first["group"]
    assert_equal prompts(:code_review).slug, json_body["logs"].first["slug"]
  end

  test "갈래를 고르면 종류 선택지도 그 갈래 것만 준다" do
    get api_v1_admin_audit_logs_url, params: { group: "auth" }, headers: @headers

    assert_equal %w[session.signed_in session.signed_out session.failed].sort,
                 json_body["actions"].map { |action| action["value"] }.sort
    assert_includes json_body["groups"].map { |group| group["label"] }, "로그인"
  end

  test "사람으로 거른다" do
    AuditLog.track(actor: users(:jiwon), action: "session.signed_in")
    AuditLog.track(actor: users(:haneul), action: "session.signed_in")

    get api_v1_admin_audit_logs_url, params: { user_id: users(:haneul).id }, headers: @headers

    assert_equal [ "이하늘" ], json_body["logs"].map { |log| log["actor_name"] }.uniq
  end

  test "기간으로 거른다" do
    old = AuditLog.track(actor: users(:jiwon), action: "session.signed_in")
    old.update_columns(created_at: 10.days.ago)
    AuditLog.track(actor: users(:jiwon), action: "prompt.copied", target: prompts(:code_review))

    get api_v1_admin_audit_logs_url, params: { days: 7 }, headers: @headers

    assert_equal [ "프롬프트 복사" ], json_body["logs"].map { |log| log["label"] }
  end

  test "구성원별 현황에 아무것도 안 한 사람도 빠지지 않는다" do
    3.times { AuditLog.track(actor: users(:jiwon), action: "prompt.copied", target: prompts(:code_review)) }
    AuditLog.track(actor: users(:jiwon), action: "session.signed_in")

    get summary_api_v1_admin_audit_logs_url, headers: @headers

    assert_response :success
    rows = json_body["members"].index_by { |row| row.dig("user", "name") }
    assert_equal User.count, json_body["members"].size
    assert_equal 3, rows["김지원"].dig("counts", "copied")
    assert_equal 1, rows["김지원"].dig("counts", "signed_in")
    assert rows["김지원"]["last_activity_at"].present?
    assert_equal 0, rows["이하늘"].dig("counts", "copied")
    assert_nil rows["이하늘"]["last_activity_at"]
  end

  test "현황 합계에는 없는 이메일로 두드린 실패도 들어간다" do
    AuditLog.track(actor: users(:jiwon), action: "session.failed")
    AuditLog.track(actor: nil, actor_name: "intruder@example.com", action: "session.failed")
    AuditLog.track(actor: users(:jiwon), action: "session.signed_in")

    get summary_api_v1_admin_audit_logs_url, headers: @headers

    assert_equal 2, json_body.dig("totals", "failed")
    assert_equal 1, json_body.dig("totals", "active_members")
  end

  test "기간을 벗어난 활동은 현황에서 세지 않는다" do
    old = AuditLog.track(actor: users(:jiwon), action: "prompt.copied", target: prompts(:code_review))
    old.update_columns(created_at: 10.days.ago)

    get summary_api_v1_admin_audit_logs_url, params: { days: 7 }, headers: @headers

    row = json_body["members"].find { |member| member.dig("user", "name") == "김지원" }
    assert_equal 0, row.dig("counts", "copied")
    # 마지막 활동 시각은 기간과 상관없이 보여 준다
    assert row["last_activity_at"].present?
  end

  test "일반 구성원은 현황을 볼 수 없다" do
    get summary_api_v1_admin_audit_logs_url, headers: auth_headers(users(:jiwon))

    assert_response :forbidden
  end
end
