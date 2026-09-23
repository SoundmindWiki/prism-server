# 문서를 "어느 팀 것" 으로 나눈다. 상위·하위를 둘 수 있다 (예: WX → 접근성).
class Category < ApplicationRecord
  include Treeable

  has_many :prompts, dependent: :restrict_with_error

  normalizes :slug, with: ->(slug) { slug.to_s.strip.downcase }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :color, presence: true

  scope :ordered, -> { order(:position, :name) }
end
