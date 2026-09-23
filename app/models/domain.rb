# 문서를 "어느 업계에 쓰는 것" 으로 나눈다. 제조 · 금융/보험 · 공공 같은 산업 분야다.
# 카테고리와 달리 한 문서가 여러 도메인에 걸칠 수 있고, 아무 도메인도 없을 수 있다(범용).
class Domain < ApplicationRecord
  include Treeable

  has_many :prompt_domains, dependent: :destroy
  has_many :prompts, through: :prompt_domains

  normalizes :slug, with: ->(slug) { slug.to_s.strip.downcase }
  normalizes :name, with: ->(name) { name.to_s.strip }

  validates :name, presence: true, length: { maximum: 40 }
  validates :slug, presence: true, uniqueness: true

  scope :ordered, -> { order(:position, :name) }
end
