require "test_helper"

class Api::V1::PromptVersionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @prompt = prompts(:code_review)
    @headers = auth_headers(users(:haneul))
    @reader = auth_headers(users(:jiwon))
  end


  test "히스토리는 최신 버전부터 보여 준다" do
    @prompt.update!(body: "두 번째 본문")
    @prompt.record_version!(editor: users(:haneul), change_note: "본문 교체")

    get api_v1_prompt_versions_url(@prompt.slug), headers: @reader

    assert_response :success
    assert_equal [ 2, 1 ], json_body["versions"].map { |version| version["version_number"] }
    assert_equal [ "body", "variables" ], json_body["versions"].first["changed_fields"]
    assert_equal [], json_body["versions"].last["changed_fields"]
  end

  test "히스토리 목록에는 본문을 싣지 않는다" do
    get api_v1_prompt_versions_url(@prompt.slug), headers: @reader

    assert_nil json_body["versions"].first["body"]
  end

  test "버전 하나를 열면 본문까지 준다" do
    get api_v1_prompt_version_url(@prompt.slug, 1), headers: @reader

    assert_response :success
    assert_equal @prompt.body, json_body.dig("version", "body")
  end

  test "되돌리기는 새 버전으로 쌓인다" do
    original_body = @prompt.body
    @prompt.update!(body: "엉뚱한 본문")
    @prompt.record_version!(editor: users(:jiwon))

    assert_difference -> { @prompt.versions.count }, 1 do
      post restore_api_v1_prompt_version_url(@prompt.slug, 1), headers: @headers
    end

    assert_response :success
    assert_equal original_body, @prompt.reload.body
    assert_equal 3, @prompt.latest_version_number
    assert_equal users(:haneul), @prompt.last_editor
  end

  test "로그인하지 않으면 되돌릴 수 없다" do
    post restore_api_v1_prompt_version_url(@prompt.slug, 1)

    assert_response :unauthorized
  end

  test "없는 버전은 404" do
    get api_v1_prompt_version_url(@prompt.slug, 99), headers: @reader

    assert_response :not_found
  end
end
