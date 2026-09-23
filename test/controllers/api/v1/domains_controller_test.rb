require "test_helper"

class Api::V1::DomainsControllerTest < ActionDispatch::IntegrationTest
  test "위키에서 보이는 문서만 센다" do
    # 보관된 문서에 공공을 달아도 위키 쪽 숫자는 그대로여야 한다.
    PromptDomain.create!(prompt: prompts(:retired), domain: domains(:public))

    get api_v1_domains_url, headers: auth_headers(users(:jiwon))

    assert_response :success
    public_row = json_body["domains"].find { |row| row["slug"] == "public" }
    assert_equal 1, public_row["prompts_count"]
    assert_equal %w[finance banking insurance public], json_body["domains"].map { |row| row["slug"] }
  end

  test "로그인하지 않으면 볼 수 없다" do
    get api_v1_domains_url

    assert_response :unauthorized
  end

  test "하위 두 곳에 같이 달린 문서는 상위 합계에서 한 번만 센다" do
    PromptDomain.create!(prompt: prompts(:meeting_notes), domain: domains(:insurance))

    get api_v1_domains_url, headers: auth_headers(users(:jiwon))

    finance = json_body["domains"].find { |row| row["slug"] == "finance" }
    assert_equal 1, finance["total_count"]
  end
end
