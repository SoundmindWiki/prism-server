require "test_helper"

class Api::V1::ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:jiwon)
    @session = @user.sessions.create!(user_agent: "Mozilla/5.0 (Macintosh) Chrome/120", ip_address: "10.0.0.1")
    @headers = { "Authorization" => "Bearer #{@session.token}" }
  end

  test "로그인하지 않으면 볼 수 없다" do
    get api_v1_profile_url

    assert_response :unauthorized
  end

  test "내 정보와 활동 요약을 준다" do
    get api_v1_profile_url, headers: @headers

    assert_response :success
    assert_equal "김지원", json_body.dig("user", "name")
    assert_equal 2, json_body.dig("stats", "authored")
    assert_equal 1, json_body.dig("stats", "edits")
  end

  test "내가 쓴 문서와 고친 문서를 함께 준다" do
    get api_v1_profile_url, headers: @headers

    assert_equal [ prompts(:code_review).slug ], json_body["edited"].map { |prompt| prompt["slug"] }
    assert_includes json_body["authored"].map { |prompt| prompt["slug"] }, prompts(:code_review).slug
  end

  test "보관된 문서는 활동 목록에서 빠진다" do
    get api_v1_profile_url, headers: @headers

    assert_not_includes json_body["authored"].map { |prompt| prompt["slug"] }, prompts(:retired).slug
  end

  test "이름과 소속을 스스로 고칠 수 있다" do
    patch api_v1_profile_url,
          params: { user: { name: "김지원", department: "AX팀", job_title: "AI 리드" } },
          headers: @headers,
          as: :json

    assert_response :success
    assert_equal "AX팀", @user.reload.department
    assert_equal "AI 리드", @user.job_title
  end

  test "이메일과 권한은 스스로 바꿀 수 없다" do
    patch api_v1_profile_url,
          params: { user: { email: "hacker@example.com", role: "admin" } },
          headers: @headers,
          as: :json

    assert_response :success
    assert_equal "jiwon@example.com", @user.reload.email
    assert_predicate @user, :member?
  end

  test "빈 이름은 거절한다" do
    patch api_v1_profile_url, params: { user: { name: "" } }, headers: @headers, as: :json

    assert_response :unprocessable_entity
  end

  # ---- 비밀번호 ----

  test "지금 비밀번호를 맞게 넣어야 바꿀 수 있다" do
    patch password_api_v1_profile_url,
          params: { current_password: "틀린비밀번호", password: "newpassword123" },
          headers: @headers,
          as: :json

    # 401 이 아니라 422 다. 로그인은 되어 있고 적어 넣은 값만 틀렸기 때문이다.
    assert_response :unprocessable_entity
    assert_nil json_body["code"]
    assert @user.reload.authenticate(TEST_PASSWORD)
  end

  test "비밀번호를 바꾸면 새 비밀번호로 로그인된다" do
    patch password_api_v1_profile_url,
          params: { current_password: TEST_PASSWORD, password: "newpassword123" },
          headers: @headers,
          as: :json

    assert_response :success
    assert @user.reload.authenticate("newpassword123")

    post api_v1_session_url,
         params: { session: { email: @user.email, password: "newpassword123" } },
         as: :json
    assert_response :created
  end

  test "비밀번호를 바꾸면 다른 기기는 나가고 지금 창은 남는다" do
    other = @user.sessions.create!(user_agent: "Mozilla/5.0 (iPhone) Safari")
    another = @user.sessions.create!

    patch password_api_v1_profile_url,
          params: { current_password: TEST_PASSWORD, password: "newpassword123" },
          headers: @headers,
          as: :json

    assert_response :success
    assert_equal 2, json_body["signed_out_devices"]
    assert_not Session.exists?(other.id)
    assert_not Session.exists?(another.id)
    assert Session.exists?(@session.id)

    # 지금 창은 그대로 쓸 수 있어야 한다
    get api_v1_profile_url, headers: @headers
    assert_response :success
  end

  test "너무 짧은 비밀번호는 거절한다" do
    patch password_api_v1_profile_url,
          params: { current_password: TEST_PASSWORD, password: "a" * (User::MIN_PASSWORD_LENGTH - 1) },
          headers: @headers,
          as: :json

    assert_response :unprocessable_entity
    assert @user.reload.authenticate(TEST_PASSWORD)
  end

  # ---- 로그인 중인 기기 ----

  test "로그인 중인 기기를 보여 주고 지금 창을 표시한다" do
    @user.sessions.create!(user_agent: "Mozilla/5.0 (iPhone) Safari/605")

    get api_v1_profile_url, headers: @headers

    sessions = json_body["sessions"]
    assert_equal 2, sessions.size
    current = sessions.find { |s| s["current"] }
    assert_equal "Chrome · Mac", current["device"]
    assert_equal "10.0.0.1", current["ip_address"]
    assert_includes sessions.map { |s| s["device"] }, "Safari · iPhone"
  end

  test "만료된 기기는 목록에 나오지 않는다" do
    stale = @user.sessions.create!
    stale.update_columns(expires_at: 1.minute.ago)

    get api_v1_profile_url, headers: @headers

    assert_not_includes json_body["sessions"].map { |s| s["id"] }, stale.id
  end

  test "다른 기기 하나를 내보낼 수 있다" do
    other = @user.sessions.create!

    assert_difference -> { @user.sessions.count }, -1 do
      delete session_api_v1_profile_url(id: other.id), headers: @headers
    end

    assert_response :no_content
  end

  test "지금 쓰는 기기는 여기서 내보낼 수 없다" do
    delete session_api_v1_profile_url(id: @session.id), headers: @headers

    assert_response :unprocessable_entity
    assert Session.exists?(@session.id)
  end

  test "남의 기기는 건드릴 수 없다" do
    stranger = users(:haneul).sessions.create!

    delete session_api_v1_profile_url(id: stranger.id), headers: @headers

    assert_response :not_found
    assert Session.exists?(stranger.id)
  end

  test "다른 기기를 한 번에 모두 내보낸다" do
    2.times { @user.sessions.create! }

    delete sessions_api_v1_profile_url, headers: @headers

    assert_response :success
    assert_equal 2, json_body["revoked"]
    assert_equal [ @session.id ], @user.sessions.pluck(:id)
  end

  test "직급도 내가 고칠 수 있다" do
    patch api_v1_profile_url, params: { user: { job_rank: "팀장" } }, headers: @headers, as: :json

    assert_response :success
    assert_equal "팀장", @user.reload.job_rank
    assert_equal "팀장", json_body.dig("user", "job_rank")
  end
end
