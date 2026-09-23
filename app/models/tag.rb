class Tag < ApplicationRecord
  MAX_PER_PROMPT = 10

  has_many :prompt_tags, dependent: :destroy
  has_many :prompts, through: :prompt_tags

  normalizes :name, with: ->(name) { name.to_s.strip.delete_prefix("#") }

  validates :name, presence: true, uniqueness: true, length: { maximum: 30 }
  validates :slug, presence: true, uniqueness: true

  before_validation :assign_slug

  scope :ordered, -> { order(:name) }

  # 이름 목록을 받아 없는 태그는 만들고 전부 돌려준다.
  def self.resolve(names)
    Array(names)
      .map { |name| name.to_s.strip.delete_prefix("#") }
      .reject(&:blank?)
      .uniq(&:downcase)
      .first(MAX_PER_PROMPT)
      .filter_map { |name| find_or_create_by(name: name).then { |tag| tag.persisted? ? tag : nil } }
  end

  private

  def assign_slug
    self.slug = Slug.unique_for(name, scope: Tag.where.not(id: id), fallback: "tag") if slug.blank? && name.present?
  end
end
