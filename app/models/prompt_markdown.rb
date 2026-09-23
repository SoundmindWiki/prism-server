# 프롬프트 한 편을 마크다운 파일 하나로 주고받는다.
#
#   ---
#   title: 웹 접근성 점검
#   category: wx
#   tags:
#   - 접근성
#   model: Claude Opus 5
#   summary: 마크업을 붙여 넣으면 ...
#   usage_notes: |-
#     여러 줄도 된다
#   variables:
#   - name: 마크업
#     description: 점검할 HTML
#   ---
#
#   여기부터가 프롬프트 본문. 복사 버튼이 복사하는 바로 그 글이다.
#
# 본문은 한 글자도 건드리지 않고 앞부분에만 정보를 모았다.
# 그래서 내려받은 파일을 다시 올리면 똑같이 돌아온다.
module PromptMarkdown
  MAX_BYTES = 256 * 1024

  FRONT_MATTER = /\A---[ \t]*\n(.*?)\n---[ \t]*(?:\n|\z)/m
  FIRST_HEADING = /\A#[ \t]+(.+?)[ \t#]*(?:\n|\z)/

  # 손으로 쓴 파일도 받아 주려고 한글 키와 흔한 별칭을 같은 뜻으로 읽는다.
  KEY_ALIASES = {
    "title" => %w[title 제목],
    "category" => %w[category 카테고리 팀],
    "tags" => %w[tags tag_names 태그],
    "domains" => %w[domains domain 도메인 분야 산업],
    "model" => %w[model model_hint 모델 권장모델 권장_모델],
    "summary" => %w[summary description 요약 설명 한줄설명 한_줄_설명],
    "usage_notes" => %w[usage_notes notes tips 사용팁 사용_팁 팁],
    "variables" => %w[variables 변수]
  }.freeze

  Result = Data.define(:attributes, :warnings)

  module_function

  def dump(prompt)
    meta = {
      "title" => prompt.title,
      "category" => prompt.category.slug,
      "domains" => prompt.domain_slugs.presence,
      "tags" => prompt.tag_names.presence,
      "model" => prompt.model_hint.presence,
      "summary" => prompt.summary.presence,
      "usage_notes" => prompt.usage_notes.presence,
      "variables" => described_variables(prompt).presence
    }.compact

    "#{meta.to_yaml(line_width: -1)}---\n\n#{prompt.body.to_s.strip}\n"
  end

  def filename(prompt)
    "#{prompt.slug}.md"
  end

  # 파일 내용을 읽어 "새 문서" 폼에 채울 값으로 바꾼다. 저장은 하지 않는다.
  # 올린 사람이 한 번 보고 고친 뒤 저장하게 하려는 것이다.
  def parse(text, filename: nil)
    warnings = []
    text = text.to_s.delete_prefix("﻿").gsub("\r\n", "\n")
    meta, body = split_front_matter(text, warnings)

    title = meta.delete("title").to_s.strip.presence
    body = body.strip

    # 앞부분에 제목이 없으면 첫 번째 "# 제목" 을 제목으로 쓰고, 그 줄은 본문에서 뺀다.
    if title.nil? && (heading = FIRST_HEADING.match(body))
      title = heading[1].strip
      body = body[heading.end(0)..].to_s.strip
    end
    title ||= title_from_filename(filename)

    attributes = {
      "title" => title.to_s,
      "category_slug" => resolve_category(meta.delete("category"), warnings)&.slug,
      "summary" => meta.delete("summary").to_s.strip,
      "body" => body,
      "usage_notes" => meta.delete("usage_notes").to_s.strip,
      "model_hint" => meta.delete("model").to_s.strip,
      "domain_slugs" => resolve_domains(meta.delete("domains"), warnings),
      "tag_names" => tag_list(meta.delete("tags")),
      "variables" => variable_list(meta.delete("variables"))
    }

    warnings << "모르는 항목은 무시했습니다: #{meta.keys.join(', ')}" if meta.any?
    check_limits(attributes, warnings)

    Result.new(attributes: attributes, warnings: warnings)
  end

  # ---- 아래는 내부용 ----

  def split_front_matter(text, warnings)
    match = FRONT_MATTER.match(text)
    return [ {}, text ] unless match

    body = text[match.end(0)..].to_s
    loaded = YAML.safe_load(match[1], permitted_classes: [ Date, Time ], aliases: false)

    case loaded
    when Hash then [ normalize_keys(loaded), body ]
    when nil then [ {}, body ]
    else
      warnings << "앞부분(--- 사이)이 \"항목: 값\" 형식이 아니라 무시했습니다."
      [ {}, body ]
    end
  rescue Psych::Exception => error
    warnings << "앞부분(--- 사이)을 읽지 못해 본문만 불러왔습니다. #{error.message.lines.first.to_s.strip}"
    [ {}, text[match.end(0)..].to_s ]
  end

  def normalize_keys(hash)
    hash.each_with_object({}) do |(key, value), normalized|
      name = key.to_s.strip
      canonical = KEY_ALIASES.find { |_, aliases| aliases.include?(name.downcase) || aliases.include?(name) }&.first
      normalized[canonical || name] = value
    end
  end

  def resolve_category(value, warnings)
    key = value.to_s.strip
    return nil if key.empty?

    category = Category.find_by(slug: key.downcase) ||
               Category.where("LOWER(name) = ?", key.downcase).first
    warnings << "카테고리 \"#{key}\" 를 찾지 못했습니다. 직접 골라 주세요." unless category
    category
  end

  # 도메인은 주소로도 이름으로도 받는다. 모르는 것만 골라 알려 준다.
  def resolve_domains(value, warnings)
    keys = (value.is_a?(Array) ? value : value.to_s.split(/[,\n]/)).map { |key| key.to_s.strip }.reject(&:empty?).uniq
    return [] if keys.empty?

    found = keys.to_h do |key|
      [ key, Domain.find_by(slug: key.downcase) || Domain.where("LOWER(name) = ?", key.downcase).first ]
    end
    missing = found.select { |_, domain| domain.nil? }.keys
    warnings << "도메인 #{missing.map { |key| "\"#{key}\"" }.join(', ')} 을 찾지 못했습니다. 직접 골라 주세요." if missing.any?

    found.values.compact.map(&:slug).uniq
  end

  def tag_list(value)
    list = value.is_a?(Array) ? value : value.to_s.split(/[,\n]/)
    list.map { |tag| tag.to_s.strip.delete_prefix("#") }
        .reject(&:empty?)
        .uniq
        .first(Tag::MAX_PER_PROMPT)
  end

  # 목록 형식과 "이름: 설명" 형식을 둘 다 받는다.
  def variable_list(value)
    case value
    when Array
      value.filter_map do |entry|
        next unless entry.is_a?(Hash)

        entry = entry.transform_keys { |key| key.to_s.strip }
        name = (entry["name"] || entry["이름"]).to_s.strip
        next if name.empty?

        {
          "name" => name,
          "description" => (entry["description"] || entry["설명"]).to_s,
          "example" => (entry["example"] || entry["예시"]).to_s
        }
      end
    when Hash
      value.map { |name, description| { "name" => name.to_s.strip, "description" => description.to_s, "example" => "" } }
    else
      []
    end
  end

  # 본문에서 알아서 찾는 변수는 설명이나 예시가 있는 것만 적는다. 나머지는 군더더기다.
  def described_variables(prompt)
    Array(prompt.variables).filter_map do |variable|
      next if variable["description"].blank? && variable["example"].blank?

      variable.slice("name", "description", "example").reject { |_, text| text.blank? }
    end
  end

  def title_from_filename(filename)
    File.basename(filename.to_s, ".*").tr("_-", "  ").squeeze(" ").strip.presence
  end

  def check_limits(attributes, warnings)
    warnings << "제목을 찾지 못했습니다. 직접 적어 주세요." if attributes["title"].empty?
    warnings << "본문이 비어 있습니다." if attributes["body"].empty?
    warnings << "제목이 120자를 넘습니다. 줄여야 저장됩니다." if attributes["title"].length > 120
    warnings << "한 줄 설명이 300자를 넘습니다. 줄여야 저장됩니다." if attributes["summary"].length > 300
    warnings << "본문이 20,000자를 넘습니다. 줄여야 저장됩니다." if attributes["body"].length > 20_000
  end
end
