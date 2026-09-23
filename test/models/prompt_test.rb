require "test_helper"

class PromptTest < ActiveSupport::TestCase
  setup do
    @author = users(:jiwon)
    @category = categories(:dev)
  end

  def build_prompt(**overrides)
    Prompt.new({
      title: "새 프롬프트",
      body: "본문 {{대상}}",
      category: @category,
      author: @author
    }.merge(overrides))
  end

  test "제목에서 슬러그를 만든다" do
    prompt = build_prompt(title: "장애 회고 작성")
    prompt.save!

    assert_equal "장애-회고-작성", prompt.slug
  end

  test "제목이 겹쳐도 슬러그는 겹치지 않는다" do
    prompt = build_prompt(title: "코드 리뷰 요청")
    prompt.save!

    assert_equal "코드-리뷰-요청-2", prompt.slug
  end

  test "제목을 바꿔도 슬러그는 그대로 둔다" do
    prompt = build_prompt(title: "원래 제목")
    prompt.save!
    original_slug = prompt.slug

    prompt.update!(title: "바뀐 제목")

    assert_equal original_slug, prompt.reload.slug
  end

  test "본문에서 자리표시자를 뽑아낸다" do
    prompt = build_prompt(body: "{{ 언어 }} 로 {{코드}} 를 리뷰해 주세요. {{코드}} 는 두 번 나와도 하나로 센다.")
    prompt.save!

    assert_equal %w[언어 코드], prompt.variables.map { |variable| variable["name"] }
  end

  test "본문에서 사라진 자리표시자는 설명도 함께 정리된다" do
    prompt = build_prompt(
      body: "{{하나}} {{둘}}",
      variables: [ { "name" => "하나", "description" => "첫 번째" }, { "name" => "둘", "description" => "두 번째" } ]
    )
    prompt.save!

    prompt.update!(body: "{{하나}} 만 남긴다")

    assert_equal [ "하나" ], prompt.variables.map { |variable| variable["name"] }
    assert_equal "첫 번째", prompt.variables.first["description"]
  end

  test "태그는 이름으로 붙이고 없으면 새로 만든다" do
    prompt = build_prompt
    prompt.tag_names = [ "코드리뷰", "새태그", "  ", "#해시붙은태그" ]
    prompt.save!

    assert_equal [ "코드리뷰", "새태그", "해시붙은태그" ], prompt.reload.tag_names
    assert_equal tags(:review), prompt.tags.first
  end

  test "버전을 쌓으면 번호가 하나씩 올라간다" do
    prompt = prompts(:code_review)

    version = prompt.record_version!(editor: @author, change_note: "손봄")

    assert_equal 2, version.version_number
    assert_equal prompt.body, version.body
  end

  test "본문이 바뀐 저장만 버전으로 남는다" do
    prompt = prompts(:code_review)

    prompt.update!(view_count: 999)
    assert_nil prompt.record_version_if_changed!(editor: @author)

    prompt.update!(body: "새 본문 {{변수}}")
    assert_equal 2, prompt.record_version_if_changed!(editor: @author).version_number
  end

  test "되돌리기는 지우지 않고 새 버전으로 쌓는다" do
    prompt = prompts(:code_review)
    original_body = prompt.body
    prompt.update!(body: "엉뚱하게 바꾼 본문")
    prompt.record_version!(editor: @author)

    prompt.restore_version!(prompt.versions.find_by(version_number: 1), editor: users(:haneul))

    assert_equal original_body, prompt.reload.body
    assert_equal 3, prompt.latest_version_number
    assert_equal "v1 내용으로 되돌림", prompt.versions.first.change_note
    assert_equal users(:haneul), prompt.last_editor
  end

  test "검색은 제목·본문·태그를 함께 훑는다" do
    assert_includes Prompt.search("리뷰"), prompts(:code_review)
    assert_includes Prompt.search("녹취록"), prompts(:meeting_notes)
    assert_includes Prompt.search("회의"), prompts(:meeting_notes)
    assert_empty Prompt.search("존재하지않는말")
  end

  test "검색어에 든 LIKE 특수문자는 글자 그대로 취급한다" do
    assert_empty Prompt.search("%")
  end

  test "목록에는 보관한 프롬프트가 나오지 않는다" do
    assert_not_includes Prompt.listable, prompts(:retired)
  end

  test "카테고리와 태그로 거를 수 있다" do
    assert_equal [ prompts(:meeting_notes) ], Prompt.listable.in_category("office").to_a
    assert_equal [ prompts(:code_review) ], Prompt.listable.with_tag("코드리뷰").to_a
  end
end
