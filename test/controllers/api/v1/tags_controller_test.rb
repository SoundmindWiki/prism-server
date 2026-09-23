require "test_helper"

class Api::V1::TagsControllerTest < ActionDispatch::IntegrationTest
  setup { @headers = auth_headers(users(:jiwon)) }

  test "태그 목록은 사용 중인 문서 수를 함께 준다" do
    get api_v1_tags_url, headers: @headers

    assert_response :success
    counts = json_body["tags"].to_h { |tag| [ tag["name"], tag["prompts_count"] ] }
    assert_equal 1, counts["코드리뷰"]
  end

  test "used=true 면 아무도 안 쓰는 태그는 뺀다" do
    Tag.create!(name: "안쓰는태그")

    get api_v1_tags_url, params: { used: true }, headers: @headers

    assert_not_includes json_body["tags"].map { |tag| tag["name"] }, "안쓰는태그"
  end
end
