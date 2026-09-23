require "test_helper"

class Api::V1::Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:boss)
    @headers = auth_headers(@admin)
  end

  test "일반 구성원은 백오피스에 들어올 수 없다" do
    get api_v1_admin_users_url, headers: auth_headers(users(:jiwon))

    assert_response :forbidden
    assert_equal "forbidden", json_body["code"]
  end

  test "로그인하지 않으면 401" do
    get api_v1_admin_users_url

    assert_response :unauthorized
  end

  test "구성원 목록에 작성 문서 수가 함께 나온다" do
    get api_v1_admin_users_url, headers: @headers

    assert_response :success
    row = json_body["users"].find { |user| user["email"] == users(:jiwon).email }
    assert_equal 2, row["prompts_count"]
    assert row["has_password"]
  end

  test "이름으로 찾고 권한으로 거른다" do
    get api_v1_admin_users_url, params: { q: "김지원" }, headers: @headers
    assert_equal [ users(:jiwon).email ], json_body["users"].map { |user| user["email"] }

    # 부서로도 걸린다 — "경영지원" 은 관리자 둘의 부서다
    get api_v1_admin_users_url, params: { q: "경영지원" }, headers: @headers
    assert_equal %w[admin@example.com admin2@example.com].sort,
                 json_body["users"].map { |user| user["email"] }.sort

    get api_v1_admin_users_url, params: { role: "admin" }, headers: @headers
    assert_equal %w[admin@example.com admin2@example.com].sort,
                 json_body["users"].map { |user| user["email"] }.sort
  end

  test "구성원을 추가하면 첫 비밀번호를 한 번 알려 준다" do
    assert_difference -> { User.count }, 1 do
      post api_v1_admin_users_url,
           params: { user: { name: "신입", email: "newbie@example.com", department: "프로덕트" } },
           headers: @headers,
           as: :json
    end

    assert_response :created
    password = json_body["initial_password"]
    assert password.present?

    # 알려 준 비밀번호로 실제 로그인이 되어야 한다
    post api_v1_session_url, params: { session: { email: "newbie@example.com", password: password } }, as: :json
    assert_response :created
  end

  test "비밀번호를 직접 정하면 따로 알려 주지 않는다" do
    post api_v1_admin_users_url,
         params: { user: { name: "신입", email: "newbie2@example.com", password: "직접정한비번1234" } },
         headers: @headers,
         as: :json

    assert_response :created
    assert_nil json_body["initial_password"]
  end

  test "권한을 바꾸면 기록이 남는다" do
    assert_difference -> { AuditLog.where(action: "user.role_changed").count }, 1 do
      patch api_v1_admin_user_url(users(:jiwon)),
            params: { user: { role: "admin" } },
            headers: @headers,
            as: :json
    end

    assert_response :success
    assert_predicate users(:jiwon).reload, :admin?
  end

  test "비활성화하면 쓰던 세션이 전부 끊긴다" do
    victim = users(:jiwon)
    victim_headers = auth_headers(victim)

    delete api_v1_admin_user_url(victim), headers: @headers

    assert_response :success
    assert_not victim.reload.active
    assert_empty victim.sessions

    get api_v1_session_url, headers: victim_headers
    assert_response :unauthorized
  end

  test "자기 계정은 중지할 수 없다" do
    delete api_v1_admin_user_url(@admin), headers: @headers

    assert_response :unprocessable_entity
    assert @admin.reload.active
  end

  test "마지막 관리자는 중지할 수 없다" do
    users(:second_admin).update!(active: false)

    delete api_v1_admin_user_url(@admin), headers: auth_headers(users(:boss))

    assert_response :unprocessable_entity
  end

  test "마지막 관리자의 권한은 내릴 수 없다" do
    users(:second_admin).update!(active: false)

    patch api_v1_admin_user_url(@admin), params: { user: { role: "member" } }, headers: @headers, as: :json

    assert_response :unprocessable_entity
    assert_predicate @admin.reload, :admin?
  end

  test "중지한 구성원을 되살릴 수 있다" do
    post reactivate_api_v1_admin_user_url(users(:retired)), headers: @headers

    assert_response :success
    assert users(:retired).reload.active
  end

  test "비밀번호를 재설정하면 기존 세션이 끊긴다" do
    victim = users(:jiwon)
    victim_headers = auth_headers(victim)

    post reset_password_api_v1_admin_user_url(victim), headers: @headers

    assert_response :success
    password = json_body["initial_password"]
    assert_empty victim.reload.sessions

    get api_v1_session_url, headers: victim_headers
    assert_response :unauthorized

    post api_v1_session_url, params: { session: { email: victim.email, password: password } }, as: :json
    assert_response :created
  end

  test "직급을 넣어 구성원을 만들고 고친다" do
    post api_v1_admin_users_url,
         params: { user: { name: "양창열", email: "severo@example.com", department: "UX팀", job_rank: "팀장" } },
         headers: @headers,
         as: :json

    assert_response :created
    assert_equal "팀장", json_body.dig("user", "job_rank")

    patch api_v1_admin_user_url(User.find_by!(email: "severo@example.com")),
          params: { user: { job_rank: "매니저" } },
          headers: @headers,
          as: :json

    assert_response :success
    assert_equal "매니저", json_body.dig("user", "job_rank")
  end

  test "직급으로도 구성원을 찾는다" do
    get api_v1_admin_users_url, params: { q: "팀장" }, headers: @headers

    assert_equal [ users(:haneul).name ], json_body["users"].map { |user| user["name"] }
  end
end
