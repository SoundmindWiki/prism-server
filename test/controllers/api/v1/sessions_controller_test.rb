require "test_helper"

class Api::V1::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "이메일과 비밀번호로 로그인하면 토큰을 준다" do
    assert_difference -> { Session.count }, 1 do
      post api_v1_session_url,
           params: { session: { email: "JIWON@example.com", password: TEST_PASSWORD } },
           as: :json
    end

    assert_response :created
    assert json_body["token"].present?
    assert_equal "김지원", json_body.dig("user", "name")
    assert users(:jiwon).reload.last_signed_in_at.present?
  end

  test "비밀번호가 틀리면 세션을 만들지 않는다" do
    assert_no_difference -> { Session.count } do
      post api_v1_session_url,
           params: { session: { email: users(:jiwon).email, password: "틀린비밀번호" } },
           as: :json
    end

    assert_response :unauthorized
    assert_equal "이메일 또는 비밀번호가 맞지 않습니다.", json_body["error"]
  end

  test "없는 이메일도 같은 메시지로 돌려준다" do
    post api_v1_session_url,
         params: { session: { email: "nobody@example.com", password: TEST_PASSWORD } },
         as: :json

    assert_response :unauthorized
    assert_equal "이메일 또는 비밀번호가 맞지 않습니다.", json_body["error"]
  end

  test "중지된 계정은 비밀번호가 맞아도 막는다" do
    post api_v1_session_url,
         params: { session: { email: users(:retired).email, password: TEST_PASSWORD } },
         as: :json

    assert_response :forbidden
  end

  test "토큰으로 내 정보를 확인한다" do
    get api_v1_session_url, headers: auth_headers(users(:jiwon))

    assert_response :success
    assert_equal "김지원", json_body.dig("user", "name")
  end

  test "토큰이 없으면 401" do
    get api_v1_session_url

    assert_response :unauthorized
    assert_equal "unauthenticated", json_body["code"]
  end

  test "엉뚱한 토큰도 401" do
    get api_v1_session_url, headers: { "Authorization" => "Bearer 없는토큰입니다" }

    assert_response :unauthorized
  end

  test "만료된 토큰은 401" do
    session = users(:jiwon).sessions.create!
    session.update_columns(expires_at: 1.minute.ago)

    get api_v1_session_url, headers: { "Authorization" => "Bearer #{session.token}" }

    assert_response :unauthorized
  end

  test "로그인 뒤 계정이 중지되면 그 토큰도 통하지 않는다" do
    headers = auth_headers(users(:jiwon))
    users(:jiwon).update!(active: false)

    get api_v1_session_url, headers: headers

    assert_response :unauthorized
  end

  test "로그아웃하면 세션이 사라진다" do
    headers = auth_headers(users(:jiwon))

    assert_difference -> { Session.count }, -1 do
      delete api_v1_session_url, headers: headers
    end

    assert_response :no_content
    get api_v1_session_url, headers: headers
    assert_response :unauthorized
  end
end
