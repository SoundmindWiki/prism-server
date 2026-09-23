# 한글 제목도 살려 두는 슬러그 생성기.
# ActiveSupport 의 parameterize 는 한글을 통째로 날려 버리기 때문에 직접 만든다.
module Slug
  module_function

  def generate(text, fallback: "untitled")
    base = text.to_s.strip.downcase
               .gsub(/[^\p{Hangul}\p{Alnum}\s_-]/, "")
               .gsub(/[\s_]+/, "-")
               .gsub(/-{2,}/, "-")
               .delete_prefix("-")
               .delete_suffix("-")

    base.presence || fallback
  end

  # scope 안에서 겹치지 않는 슬러그를 찾을 때까지 -2, -3 을 붙인다.
  def unique_for(text, scope:, column: :slug, fallback: "untitled")
    base = generate(text, fallback: fallback)
    candidate = base
    suffix = 1

    while scope.exists?(column => candidate)
      suffix += 1
      candidate = "#{base}-#{suffix}"
    end

    candidate
  end
end
