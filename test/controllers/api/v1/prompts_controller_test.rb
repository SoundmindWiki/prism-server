require "test_helper"

class Api::V1::PromptsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @author = users(:jiwon)
    @headers = auth_headers(@author)
  end

  test "로그인하지 않으면 목록도 볼 수 없다" do
    get api_v1_prompts_url

    assert_response :unauthorized
  end

  test "목록은 보관된 문서를 빼고 돌려준다" do
    get api_v1_prompts_url, headers: @headers

    assert_response :success
    slugs = json_body["prompts"].map { |prompt| prompt["slug"] }
    assert_includes slugs, prompts(:code_review).slug
    assert_not_includes slugs, prompts(:retired).slug
    assert_equal 2, json_body.dig("meta", "total")
  end

  test "목록 카드에는 본문을 통째로 싣지 않는다" do
    get api_v1_prompts_url, headers: @headers

    assert_nil json_body["prompts"].first["body"]
    assert json_body["prompts"].first["excerpt"].present?
  end

  test "검색어로 거른다" do
    get api_v1_prompts_url, params: { q: "녹취록" }, headers: @headers

    assert_equal [ prompts(:meeting_notes).slug ], json_body["prompts"].map { |prompt| prompt["slug"] }
  end

  test "카테고리와 태그로 거른다" do
    get api_v1_prompts_url, params: { category: "office" }, headers: @headers
    assert_equal [ prompts(:meeting_notes).slug ], json_body["prompts"].map { |prompt| prompt["slug"] }

    get api_v1_prompts_url, params: { tag: "코드리뷰" }, headers: @headers
    assert_equal [ prompts(:code_review).slug ], json_body["prompts"].map { |prompt| prompt["slug"] }
  end

  test "인기순은 복사 횟수를 따른다" do
    get api_v1_prompts_url, params: { sort: "popular" }, headers: @headers

    assert_equal [ prompts(:meeting_notes).slug, prompts(:code_review).slug ],
                 json_body["prompts"].map { |prompt| prompt["slug"] }
  end

  test "페이지를 나눈다" do
    get api_v1_prompts_url, params: { per_page: 1, page: 2 }, headers: @headers

    assert_equal 1, json_body["prompts"].size
    assert_equal 2, json_body.dig("meta", "total_pages")
  end

  test "상세는 본문과 변수를 함께 준다" do
    prompt = prompts(:code_review)

    get api_v1_prompt_url(prompt.slug), headers: @headers

    assert_response :success
    assert_equal prompt.body, json_body.dig("prompt", "body")
    assert_equal %w[언어 코드], json_body.dig("prompt", "variables").map { |variable| variable["name"] }
    assert_equal 1, json_body.dig("prompt", "version_count")
  end

  test "상세를 열면 조회수만 오르고 수정 시각은 그대로다" do
    prompt = prompts(:code_review)
    updated_at = prompt.updated_at

    assert_difference -> { prompt.reload.view_count }, 1 do
      get api_v1_prompt_url(prompt.slug), headers: @headers
    end

    assert_equal updated_at.to_i, prompt.reload.updated_at.to_i
  end

  test "없는 슬러그는 404" do
    get api_v1_prompt_url("없는-문서"), headers: @headers

    assert_response :not_found
  end

  test "로그인하지 않으면 만들 수 없다" do
    assert_no_difference -> { Prompt.count } do
      post api_v1_prompts_url, params: { prompt: { title: "무단 작성", body: "본문" } }, as: :json
    end

    assert_response :unauthorized
  end

  test "문서를 만들면 첫 버전이 함께 남는다" do
    assert_difference -> { Prompt.count }, 1 do
      post api_v1_prompts_url,
           params: {
             prompt: {
               title: "장애 회고 작성",
               category_slug: "dev",
               body: "{{타임라인}} 을 정리해 주세요.",
               tag_names: [ "회고" ]
             }
           },
           headers: @headers,
           as: :json
    end

    assert_response :created
    prompt = Prompt.find_by(slug: "장애-회고-작성")
    assert_equal @author, prompt.author
    assert_equal categories(:dev), prompt.category
    assert_equal [ "회고" ], prompt.tag_names
    assert_equal 1, prompt.latest_version_number
    assert_equal "최초 작성", prompt.versions.first.change_note
  end

  test "빈 제목은 한국어 메시지로 거절한다" do
    post api_v1_prompts_url,
         params: { prompt: { title: "", body: "", category_slug: "dev" } },
         headers: @headers,
         as: :json

    assert_response :unprocessable_entity
    assert_equal "내용을 입력해 주세요", json_body.dig("details", "title").first
  end

  test "수정하면 버전이 쌓이고 마지막 편집자가 바뀐다" do
    prompt = prompts(:code_review)

    assert_difference -> { prompt.versions.count }, 1 do
      patch api_v1_prompt_url(prompt.slug),
            params: { prompt: { body: "새 본문 {{대상}}", change_note: "본문 정리" } },
            headers: auth_headers(users(:haneul)),
            as: :json
    end

    assert_response :success
    assert_equal users(:haneul), prompt.reload.last_editor
    assert_equal "본문 정리", prompt.versions.first.change_note
    assert_equal [ "대상" ], prompt.variables.map { |variable| variable["name"] }
  end

  test "내용이 그대로면 버전을 만들지 않는다" do
    prompt = prompts(:code_review)

    assert_no_difference -> { prompt.versions.count } do
      patch api_v1_prompt_url(prompt.slug),
            params: { prompt: { title: prompt.title, body: prompt.body } },
            headers: @headers,
            as: :json
    end

    assert_response :success
  end

  test "보관하면 목록에서 내려가지만 주소는 살아 있다" do
    prompt = prompts(:code_review)

    post archive_api_v1_prompt_url(prompt.slug), headers: @headers

    assert_response :success
    assert_predicate prompt.reload, :archived?

    get api_v1_prompt_url(prompt.slug), headers: @headers
    assert_response :success
  end

  test "위키 화면에서는 문서를 지울 수 없다" do
    # 되돌릴 수 없는 삭제는 백오피스에만 둔다. 경로 자체가 없어야 한다.
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/api/v1/prompts/some-slug", method: :delete)
    end

    # 백오피스 경로는 살아 있다
    assert_equal(
      { controller: "api/v1/admin/prompts", action: "destroy", slug: "some-slug" },
      Rails.application.routes.recognize_path("/api/v1/admin/prompts/some-slug", method: :delete)
    )
  end

  test "복사 횟수는 로그인한 사람이면 올릴 수 있다" do
    prompt = prompts(:code_review)

    assert_difference -> { prompt.reload.copy_count }, 1 do
      post copy_api_v1_prompt_url(prompt.slug), headers: @headers
    end

    assert_equal prompt.reload.copy_count, json_body["copy_count"]
  end

  # ---- 마크다운 ----

  test "문서를 .md 파일로 내려준다" do
    get markdown_api_v1_prompt_url(prompts(:code_review).slug), headers: @headers

    assert_response :success
    assert_equal "text/markdown; charset=utf-8", response.media_type + "; charset=" + response.charset
    assert_match(/attachment/, response.headers["Content-Disposition"])
    assert_match(/%EC%BD%94%EB%93%9C-%EB%A6%AC%EB%B7%B0-%EC%9A%94%EC%B2%AD\.md/, response.headers["Content-Disposition"])
    assert response.body.start_with?("---\n")
    assert_includes response.body, prompts(:code_review).body
  end

  test "로그인하지 않으면 내려받을 수 없다" do
    get markdown_api_v1_prompt_url(prompts(:code_review).slug)

    assert_response :unauthorized
  end

  test "올린 .md 를 폼에 채울 값으로 바꿔 준다. 저장은 하지 않는다" do
    assert_no_difference -> { Prompt.count } do
      post parse_markdown_api_v1_prompts_url,
           params: { markdown: "---\ntitle: 새 프롬프트\ncategory: dev\n---\n{{대상}} 을 정리해 주세요.", filename: "x.md" },
           headers: @headers,
           as: :json
    end

    assert_response :success
    assert_equal "새 프롬프트", json_body.dig("prompt", "title")
    assert_equal "dev", json_body.dig("prompt", "category_slug")
    assert_equal "{{대상}} 을 정리해 주세요.", json_body.dig("prompt", "body")
    assert_equal [], json_body["warnings"]
  end

  test "빈 파일은 거절한다" do
    post parse_markdown_api_v1_prompts_url, params: { markdown: "  \n " }, headers: @headers, as: :json

    assert_response :unprocessable_entity
    assert_equal "빈 파일입니다.", json_body["error"]
  end

  test "너무 큰 파일은 거절한다" do
    post parse_markdown_api_v1_prompts_url,
         params: { markdown: "가" * (PromptMarkdown::MAX_BYTES / 3 + 10) },
         headers: @headers,
         as: :json

    assert_response 413
  end

  test "내려받아 다시 올려 새로 만들면 본문이 한 글자도 다르지 않다" do
    original = prompts(:code_review)
    original.update!(body: "첫 줄\n\n---\n\n```\n코드\n```\n\n{{변수}} 끝", usage_notes: "여러\n줄")

    get markdown_api_v1_prompt_url(original.slug), headers: @headers
    post parse_markdown_api_v1_prompts_url, params: { markdown: response.body }, headers: @headers, as: :json
    parsed = json_body["prompt"].merge("title" => "복제본")

    post api_v1_prompts_url, params: { prompt: parsed }, headers: @headers, as: :json

    assert_response :created
    copy = Prompt.find_by!(title: "복제본")
    assert_equal original.body, copy.body
    assert_equal original.usage_notes, copy.usage_notes
    assert_equal original.category, copy.category
    assert_equal original.tag_names, copy.tag_names
  end

  # ---- 도메인 ----
  test "도메인으로 거르면 하위 도메인 문서까지 나온다" do
    get api_v1_prompts_url, params: { domain: "finance" }, headers: @headers
    assert_equal [ prompts(:meeting_notes).slug ], json_body["prompts"].map { |prompt| prompt["slug"] }

    get api_v1_prompts_url, params: { domain: "insurance" }, headers: @headers
    assert_empty json_body["prompts"]
  end

  test "상위 카테고리로 거르면 하위 카테고리 문서까지 나온다" do
    child = Category.create!(name: "회의", slug: "meeting", parent: categories(:office))
    prompts(:code_review).update!(category: child)

    get api_v1_prompts_url, params: { category: "office" }, headers: @headers

    assert_equal [ prompts(:code_review).slug, prompts(:meeting_notes).slug ].sort,
                 json_body["prompts"].map { |prompt| prompt["slug"] }.sort
  end

  test "목록 카드에 도메인과 카테고리 경로가 실린다" do
    get api_v1_prompts_url, params: { domain: "banking" }, headers: @headers

    card = json_body["prompts"].first
    assert_equal [ %w[금융/보험 은행] ], card["domains"].map { |domain| domain["path"] }
    assert_equal [ "공통 사무" ], card.dig("category", "path")
  end

  test "도메인을 여러 개 달아 만들 수 있다" do
    post api_v1_prompts_url,
         params: { prompt: { title: "대출 상담 요약", body: "본문", category_slug: "office", domain_slugs: %w[banking public] } },
         headers: @headers,
         as: :json

    assert_response :created
    assert_equal %w[banking public], json_body.dig("prompt", "domains").map { |domain| domain["slug"] }.sort
  end

  test "도메인을 빈 목록으로 보내면 범용이 된다. 안 보내면 그대로 둔다" do
    prompt = prompts(:meeting_notes)

    patch api_v1_prompt_url(prompt.slug), params: { prompt: { title: "제목만 바꿈" } }, headers: @headers, as: :json
    assert_equal %w[banking], prompt.reload.domain_slugs

    patch api_v1_prompt_url(prompt.slug), params: { prompt: { domain_slugs: [] } }, headers: @headers, as: :json
    assert_response :success
    assert_empty prompt.reload.domains
  end

  test "도메인도 .md 로 내려받았다가 다시 올리면 돌아온다" do
    get markdown_api_v1_prompt_url(prompts(:meeting_notes).slug), headers: @headers
    assert_includes response.body, "domains:\n- banking"

    post parse_markdown_api_v1_prompts_url, params: { markdown: response.body }, headers: @headers, as: :json
    assert_equal %w[banking], json_body.dig("prompt", "domain_slugs")
  end

  # ---- 폴더 옮기기 ----

  test "문서를 다른 폴더로 옮긴다. 내용이 그대로라 새 버전은 안 생긴다" do
    prompt = prompts(:code_review)

    assert_no_difference -> { prompt.versions.count } do
      post move_api_v1_prompt_url(prompt.slug), params: { category_slug: "office" }, headers: @headers, as: :json
    end

    assert_response :success
    assert_equal categories(:office), prompt.reload.category
    assert_equal @author, prompt.last_editor

    log = AuditLog.order(:id).last
    assert_equal [ "prompt.moved", "개발", "공통 사무" ], [ log.action, log.details["from"], log.details["to"] ]
  end

  test "있던 폴더에 그대로 놓으면 아무 일도 없다" do
    prompt = prompts(:code_review)

    assert_no_difference -> { AuditLog.count } do
      post move_api_v1_prompt_url(prompt.slug), params: { category_slug: "dev" }, headers: @headers, as: :json
    end

    assert_response :success
  end

  test "없는 폴더로는 못 옮긴다" do
    post move_api_v1_prompt_url(prompts(:code_review).slug), params: { category_slug: "없는폴더" }, headers: @headers, as: :json

    assert_response :not_found
  end

  test "로그인하지 않으면 옮길 수 없다" do
    post move_api_v1_prompt_url(prompts(:code_review).slug), params: { category_slug: "office" }, as: :json

    assert_response :unauthorized
  end
end
