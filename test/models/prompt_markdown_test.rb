require "test_helper"

class PromptMarkdownTest < ActiveSupport::TestCase
  setup do
    @prompt = prompts(:code_review)
  end

  def parse(text, filename: nil)
    PromptMarkdown.parse(text, filename: filename)
  end

  # ---- 내려받기 ----

  test "앞부분에 정보를 모으고 그 아래 본문을 그대로 둔다" do
    text = PromptMarkdown.dump(@prompt)

    assert text.start_with?("---\n")
    assert_includes text, "title: 코드 리뷰 요청"
    assert_includes text, "category: dev"
    assert_includes text, "- 코드리뷰"
    assert_includes text, "model: Claude Opus 5"
    assert text.end_with?("#{@prompt.body}\n")
  end

  test "설명 없는 변수는 적지 않는다. 본문에서 다시 찾으면 되니까" do
    text = PromptMarkdown.dump(@prompt)

    assert_not_includes text, "variables:"
  end

  test "설명이 있는 변수만 적는다" do
    @prompt.update!(variables: [ { "name" => "언어", "description" => "Ruby, TS 등" }, { "name" => "코드" } ])

    text = PromptMarkdown.dump(@prompt)

    assert_includes text, "name: 언어"
    assert_includes text, "description: Ruby, TS 등"
    assert_not_includes text, "name: 코드"
  end

  test "파일 이름은 주소를 따른다" do
    assert_equal "코드-리뷰-요청.md", PromptMarkdown.filename(@prompt)
  end

  # ---- 내려받은 걸 다시 올리기 ----

  test "내려받은 파일을 다시 올리면 똑같이 돌아온다" do
    @prompt.update!(variables: [ { "name" => "언어", "description" => "언어 이름", "example" => "Ruby" } ])

    result = parse(PromptMarkdown.dump(@prompt))
    attributes = result.attributes

    assert_empty result.warnings
    assert_equal @prompt.title, attributes["title"]
    assert_equal "dev", attributes["category_slug"]
    assert_equal @prompt.summary, attributes["summary"]
    assert_equal @prompt.body, attributes["body"]
    assert_equal @prompt.usage_notes, attributes["usage_notes"]
    assert_equal @prompt.model_hint, attributes["model_hint"]
    assert_equal @prompt.tag_names, attributes["tag_names"]
    assert_equal [ { "name" => "언어", "description" => "언어 이름", "example" => "Ruby" } ], attributes["variables"]
  end

  test "본문 안의 가로줄(---) 이나 코드 블록은 건드리지 않는다" do
    body = "앞 문단\n\n---\n\n```yaml\ntitle: 가짜\n---\n```\n\n뒤 문단"
    @prompt.update!(body: body)

    result = parse(PromptMarkdown.dump(@prompt))

    assert_equal body, result.attributes["body"]
    assert_equal "코드 리뷰 요청", result.attributes["title"]
  end

  test "따옴표와 콜론이 든 제목도 온전히 돌아온다" do
    @prompt.update!(title: '리뷰: "꼼꼼하게" 봐 주세요')

    assert_equal '리뷰: "꼼꼼하게" 봐 주세요', parse(PromptMarkdown.dump(@prompt)).attributes["title"]
  end

  test "여러 줄짜리 사용 팁도 온전히 돌아온다" do
    @prompt.update!(usage_notes: "첫 줄\n\n셋째 줄")

    assert_equal "첫 줄\n\n셋째 줄", parse(PromptMarkdown.dump(@prompt)).attributes["usage_notes"]
  end

  # ---- 손으로 쓴 파일 ----

  test "앞부분이 없으면 첫 # 제목을 제목으로 쓰고 본문에서 뺀다" do
    result = parse("# 회의록 정리\n\n아래 회의를 정리해 주세요.\n\n{{녹취록}}")

    assert_equal "회의록 정리", result.attributes["title"]
    assert_equal "아래 회의를 정리해 주세요.\n\n{{녹취록}}", result.attributes["body"]
    assert_nil result.attributes["category_slug"]
  end

  test "제목이 어디에도 없으면 파일 이름을 쓴다" do
    result = parse("그냥 본문만 있는 파일", filename: "weekly_report-draft.md")

    assert_equal "weekly report draft", result.attributes["title"]
  end

  test "제목을 끝내 못 찾으면 알려 준다" do
    result = parse("본문만 있다")

    assert_equal "", result.attributes["title"]
    assert_includes result.warnings, "제목을 찾지 못했습니다. 직접 적어 주세요."
  end

  test "한글로 쓴 항목 이름도 알아듣는다" do
    text = <<~MD
      ---
      제목: 채용 공고 초안
      카테고리: 공통 사무
      태그: 채용, 문서화
      모델: Claude Sonnet 5
      요약: 직무 정보를 주면 공고를 써 줍니다
      사용팁: 연봉은 확정된 것만
      ---
      본문
    MD

    attributes = parse(text).attributes

    assert_equal "채용 공고 초안", attributes["title"]
    assert_equal "office", attributes["category_slug"]
    assert_equal %w[채용 문서화], attributes["tag_names"]
    assert_equal "Claude Sonnet 5", attributes["model_hint"]
    assert_equal "직무 정보를 주면 공고를 써 줍니다", attributes["summary"]
    assert_equal "연봉은 확정된 것만", attributes["usage_notes"]
  end

  test "카테고리는 주소로도 이름으로도 찾는다" do
    assert_equal "dev", parse("---\ncategory: DEV\n---\n본문").attributes["category_slug"]
    assert_equal "dev", parse("---\ncategory: 개발\n---\n본문").attributes["category_slug"]
  end

  test "없는 카테고리는 비워 두고 알려 준다" do
    result = parse("---\ncategory: 마케팅\n---\n본문")

    assert_nil result.attributes["category_slug"]
    assert_includes result.warnings, "카테고리 \"마케팅\" 를 찾지 못했습니다. 직접 골라 주세요."
  end

  test "변수는 이름: 설명 형식으로 적어도 된다" do
    result = parse("---\nvariables:\n  고객사: 회사 이름\n  기한: 마감일\n---\n{{고객사}} {{기한}}")

    assert_equal [
      { "name" => "고객사", "description" => "회사 이름", "example" => "" },
      { "name" => "기한", "description" => "마감일", "example" => "" }
    ], result.attributes["variables"]
  end

  test "태그는 쉼표로 적어도 되고 # 은 떼고 열 개까지만 받는다" do
    tags = (1..12).map { |n| "#태그#{n}" }.join(", ")

    result = parse("---\ntags: #{tags.inspect}\n---\n본문")

    assert_equal 10, result.attributes["tag_names"].size
    assert_equal "태그1", result.attributes["tag_names"].first
  end

  test "모르는 항목은 무시하고 알려 준다" do
    result = parse("---\ntitle: 제목\nauthor: 누군가\nlicense: MIT\n---\n본문")

    assert_includes result.warnings, "모르는 항목은 무시했습니다: author, license"
  end

  test "앞부분이 깨져 있어도 본문은 살린다" do
    result = parse("---\ntitle: [닫히지 않은 괄호\n---\n본문은 멀쩡하다", filename: "broken.md")

    assert_equal "본문은 멀쩡하다", result.attributes["body"]
    assert_equal "broken", result.attributes["title"]
    assert result.warnings.any? { |warning| warning.start_with?("앞부분(--- 사이)을 읽지 못해") }
  end

  test "윈도우 줄바꿈과 BOM 이 섞여 있어도 읽는다" do
    result = parse("﻿---\r\ntitle: 윈도우에서 쓴 파일\r\n---\r\n첫 줄\r\n둘째 줄")

    assert_equal "윈도우에서 쓴 파일", result.attributes["title"]
    assert_equal "첫 줄\n둘째 줄", result.attributes["body"]
  end

  test "날짜가 들어 있어도 거절하지 않는다" do
    result = parse("---\ntitle: 제목\nupdated: 2026-09-22\n---\n본문")

    assert_equal "제목", result.attributes["title"]
    assert_includes result.warnings, "모르는 항목은 무시했습니다: updated"
  end

  test "저장할 수 없는 길이면 미리 알려 준다" do
    result = parse("---\ntitle: #{'가' * 121}\n---\n#{'나' * 20_001}")

    assert_includes result.warnings, "제목이 120자를 넘습니다. 줄여야 저장됩니다."
    assert_includes result.warnings, "본문이 20,000자를 넘습니다. 줄여야 저장됩니다."
  end

  test "도메인은 주소로도 이름으로도 찾고, 모르는 것만 알려 준다" do
    result = parse("---\ntitle: 제목\n도메인: [banking, 공공, 우주항공]\n---\n본문")

    assert_equal %w[banking public], result.attributes["domain_slugs"]
    assert_includes result.warnings, "도메인 \"우주항공\" 을 찾지 못했습니다. 직접 골라 주세요."
  end

  test "도메인이 없는 문서는 앞부분에 도메인 줄을 쓰지 않는다" do
    assert_not_includes PromptMarkdown.dump(prompts(:retired)), "domains"
  end
end
