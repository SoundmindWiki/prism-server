require "test_helper"

# 구성원이 위키에서 한 일이 활동 기록에 남는지.
class Api::V1::ActivityTrackingTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:jiwon)
    @headers = auth_headers(@user)
  end

  def last_log
    AuditLog.order(:id).last
  end

  def browser
    { "User-Agent" => "Mozilla/5.0 (Macintosh) Chrome/120" }
  end

  # 기록 테이블에 쓰지 못하는 상황을 흉내 낸다.
  # minitest 6 에서 stub 이 빠져서, 잠깐 create! 를 덮어썼다가 되돌린다.
  def while_audit_log_is_broken
    AuditLog.define_singleton_method(:create!) { |*| raise ActiveRecord::StatementInvalid, "기록 테이블이 잠김" }
    yield
  ensure
    AuditLog.singleton_class.send(:remove_method, :create!)
  end

  # ---- 로그인 ----

  test "로그인하면 어디서 들어왔는지까지 남는다" do
    post api_v1_session_url,
         params: { session: { email: @user.email, password: TEST_PASSWORD } },
         headers: browser,
         as: :json

    assert_equal "session.signed_in", last_log.action
    assert_equal @user, last_log.user
    assert_equal "Chrome · Mac", last_log.details["device"]
    assert last_log.details["ip"].present?
    assert_equal "auth", last_log.group
  end

  test "비밀번호를 틀리면 그 사람 이름으로 실패가 남는다" do
    post api_v1_session_url, params: { session: { email: @user.email, password: "틀림" } }, as: :json

    assert_equal "session.failed", last_log.action
    assert_equal @user, last_log.user
    assert_equal "wrong_password", last_log.details["reason"]
  end

  test "없는 이메일로 두드리면 적어 넣은 주소가 남는다" do
    post api_v1_session_url, params: { session: { email: "Intruder@Example.com", password: "x" } }, as: :json

    assert_equal "session.failed", last_log.action
    assert_nil last_log.user
    assert_equal "intruder@example.com", last_log.actor_name
    assert_equal "unknown_email", last_log.details["reason"]
  end

  test "중지된 계정으로 들어오려 하면 그것도 남는다" do
    post api_v1_session_url, params: { session: { email: users(:retired).email, password: TEST_PASSWORD } }, as: :json

    assert_equal "session.failed", last_log.action
    assert_equal "deactivated", last_log.details["reason"]
  end

  test "로그아웃도 남는다" do
    delete api_v1_session_url, headers: @headers

    assert_equal "session.signed_out", last_log.action
    assert_equal @user, last_log.user
  end

  # ---- 문서 ----

  test "문서를 만들면 바로 열어 볼 수 있게 주소까지 남는다" do
    post api_v1_prompts_url,
         params: { prompt: { title: "새 문서", body: "본문", category_slug: "dev" } },
         headers: @headers,
         as: :json

    assert_equal "prompt.created", last_log.action
    assert_equal "새 문서", last_log.target_label
    assert_equal "새-문서", last_log.details["slug"]
    assert_equal "개발", last_log.details["category"]
    assert_equal "content", last_log.group
  end

  test "고치면 몇 번째 버전인지 남는다" do
    prompt = prompts(:code_review)

    patch api_v1_prompt_url(prompt.slug),
          params: { prompt: { body: "바뀐 본문", change_note: "정리" } },
          headers: @headers,
          as: :json

    assert_equal "prompt.updated", last_log.action
    assert_equal 2, last_log.details["version"]
    assert_equal "정리", last_log.details["note"]
  end

  test "내용이 그대로여도 수정했다는 것은 남긴다. 버전 번호만 없다" do
    prompt = prompts(:code_review)

    patch api_v1_prompt_url(prompt.slug), params: { prompt: { title: prompt.title } }, headers: @headers, as: :json

    assert_equal "prompt.updated", last_log.action
    assert_nil last_log.details["version"]
  end

  test "보관·복사·내려받기도 남는다" do
    slug = prompts(:code_review).slug

    post copy_api_v1_prompt_url(slug), headers: @headers
    assert_equal [ "prompt.copied", "usage" ], [ last_log.action, last_log.group ]

    get markdown_api_v1_prompt_url(slug), headers: @headers
    assert_equal "prompt.downloaded", last_log.action

    post archive_api_v1_prompt_url(slug), headers: @headers
    assert_equal "prompt.archived", last_log.action
  end

  test "되돌리면 어느 버전에서 되돌렸는지 남는다" do
    prompt = prompts(:code_review)
    prompt.update!(body: "두 번째")
    prompt.record_version!(editor: @user)

    post restore_api_v1_prompt_version_url(prompt.slug, 1), headers: @headers

    assert_equal "prompt.restored", last_log.action
    assert_equal 1, last_log.details["from_version"]
    assert_equal 3, last_log.details["version"]
  end

  # ---- 마이페이지 ----

  test "내 정보를 고치면 무엇을 바꿨는지 남는다" do
    patch api_v1_profile_url, params: { user: { department: "AX팀" } }, headers: @headers, as: :json

    assert_equal "profile.updated", last_log.action
    assert_equal [ "department" ], last_log.details["changed"]
    assert_equal "account", last_log.group
  end

  test "비밀번호를 바꾸면 남는다. 비밀번호 자체는 남기지 않는다" do
    patch password_api_v1_profile_url,
          params: { current_password: TEST_PASSWORD, password: "newpassword123" },
          headers: @headers,
          as: :json

    assert_equal "profile.password_changed", last_log.action
    assert_not_includes last_log.details.to_json, "newpassword123"
    assert_not_includes last_log.details.to_json, TEST_PASSWORD
  end

  test "다른 기기를 내보내면 남는다. 내보낼 게 없으면 안 남긴다" do
    assert_no_difference -> { AuditLog.count } do
      delete sessions_api_v1_profile_url, headers: @headers
    end

    @user.sessions.create!
    delete sessions_api_v1_profile_url, headers: @headers

    assert_equal "profile.sessions_revoked", last_log.action
    assert_equal 1, last_log.details["count"]
  end

  # ---- 기록이 실패해도 ----

  test "기록을 남기지 못해도 복사는 된다" do
    prompt = prompts(:code_review)

    while_audit_log_is_broken do
      assert_difference -> { prompt.reload.copy_count }, 1 do
        post copy_api_v1_prompt_url(prompt.slug), headers: @headers
      end
    end

    assert_response :success
  end

  test "관리 기록은 남기지 못하면 조용히 넘어가지 않고 오류로 끝난다" do
    admin_headers = auth_headers(users(:boss))

    while_audit_log_is_broken do
      assert_raises(ActiveRecord::StatementInvalid) do
        post api_v1_admin_categories_url, params: { category: { name: "기록안됨" } }, headers: admin_headers, as: :json
      end
    end
  end
end
