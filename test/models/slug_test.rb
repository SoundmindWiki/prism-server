require "test_helper"

class SlugTest < ActiveSupport::TestCase
  test "한글을 그대로 남긴다" do
    assert_equal "회의록-정리", Slug.generate("회의록 정리")
  end

  test "특수문자를 걷어내고 공백을 하이픈으로 바꾼다" do
    assert_equal "pr-설명-초안", Slug.generate("  PR 설명 (초안)!  ")
  end

  test "남는 글자가 없으면 기본값을 쓴다" do
    assert_equal "prompt", Slug.generate("!!! ???", fallback: "prompt")
  end

  test "이미 쓰는 슬러그면 번호를 붙인다" do
    assert_equal "코드-리뷰-요청-2", Slug.unique_for("코드 리뷰 요청", scope: Prompt.all)
  end
end
