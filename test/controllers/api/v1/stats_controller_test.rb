require "test_helper"

class Api::V1::StatsControllerTest < ActionDispatch::IntegrationTest
  setup { @headers = auth_headers(users(:jiwon)) }

  test "첫 화면에 쓸 숫자들을 준다" do
    get api_v1_stats_url, headers: @headers

    assert_response :success
    stats = json_body["stats"]
    assert_equal 2, stats["prompts"]
    assert_equal 1, stats["archived"]
    assert_equal 2, stats["contributors"]
    assert_equal 43, stats["copies"]
  end

  test "최근 수정과 많이 복사된 목록을 함께 준다" do
    get api_v1_stats_url, headers: @headers

    assert_equal 2, json_body["recently_updated"].size
    assert_equal prompts(:meeting_notes).slug, json_body["most_copied"].first["slug"]
  end
end
