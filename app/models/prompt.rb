class Prompt < ApplicationRecord
  # 본문 안의 {{고객사명}} 같은 자리표시자.
  VARIABLE_PATTERN = /\{\{\s*([^{}\n]{1,40}?)\s*\}\}/
  SORTS = {
    "recent" => { updated_at: :desc },
    "created" => { created_at: :desc },
    "popular" => { copy_count: :desc, view_count: :desc },
    "title" => { title: :asc }
  }.freeze
  DEFAULT_SORT = "recent"

  belongs_to :category
  belongs_to :author, class_name: "User"
  belongs_to :last_editor, class_name: "User", optional: true

  has_many :prompt_tags, dependent: :destroy
  has_many :tags, through: :prompt_tags
  has_many :prompt_domains, dependent: :destroy
  has_many :domains, through: :prompt_domains
  has_many :versions, -> { newest_first }, class_name: "PromptVersion",
           inverse_of: :prompt, dependent: :destroy

  enum :status, { draft: "draft", published: "published", archived: "archived" }, validate: true

  validates :title, presence: true, length: { maximum: 120 }
  validates :body, presence: true, length: { maximum: 20_000 }
  validates :summary, length: { maximum: 300 }
  validates :slug, presence: true, uniqueness: true

  before_validation :assign_slug, on: :create
  before_save :sync_variables

  scope :listable, -> { where(status: %w[published draft]) }
  # 상위 카테고리를 고르면 하위 카테고리 문서까지 함께 보인다.
  scope :in_category, ->(slug) { slug.present? ? where(category_id: Category.subtree_ids_for(slug)) : all }
  # 도메인도 마찬가지. 조인 대신 하위 질의로 걸러 한 문서가 여러 번 나오지 않게 한다.
  scope :in_domain, lambda { |slug|
    slug.present? ? where(id: PromptDomain.where(domain_id: Domain.subtree_ids_for(slug)).select(:prompt_id)) : all
  }
  scope :with_tag, ->(slug) { slug.present? ? joins(:tags).where(tags: { slug: slug }) : all }
  # 경로(상위 이름들)를 그릴 때 부모를 하나씩 읽지 않도록 세 단계까지 미리 읽어 둔다.
  scope :with_associations, lambda {
    includes({ category: { parent: :parent } }, { domains: { parent: :parent } }, :author, :last_editor, :tags)
  }

  # SQLite 기준 LIKE 검색. 제목·요약·본문·태그를 한 번에 훑는다.
  # 규모가 커지면 FTS5 나 Postgres 전문검색으로 갈아타면 된다.
  def self.search(query)
    term = query.to_s.strip
    return all if term.blank?

    pattern = "%#{sanitize_sql_like(term)}%"
    matching_ids = left_joins(:tags)
      .where(
        "prompts.title LIKE :q OR prompts.summary LIKE :q OR prompts.body LIKE :q OR tags.name LIKE :q",
        q: pattern
      )
      .select(:id)

    where(id: matching_ids)
  end

  def self.sorted_by(key)
    order(SORTS.fetch(key.to_s, SORTS[DEFAULT_SORT]))
  end

  # 본문에서 실제로 쓰이는 자리표시자 이름.
  def detected_variables
    body.to_s.scan(VARIABLE_PATTERN).flatten.map(&:strip).reject(&:blank?).uniq
  end

  def tag_names
    tags.map(&:name)
  end

  def domain_slugs
    domains.map(&:slug)
  end

  # 주소로도 이름으로도 받는다. 모르는 값은 조용히 버린다 (폼에서는 고른 것만 넘어온다).
  def domain_slugs=(values)
    keys = Array(values).map { |value| value.to_s.strip }.reject(&:empty?).uniq
    self.domains = keys.empty? ? [] : Domain.where(slug: keys.map(&:downcase)).or(Domain.where(name: keys)).to_a
  end

  def tag_names=(names)
    self.tags = Tag.resolve(names)
  end

  def latest_version_number
    versions.maximum(:version_number) || 0
  end

  # 저장된 현재 상태를 새 버전으로 박제한다.
  def record_version!(editor:, change_note: nil)
    snapshot = PromptVersion::SNAPSHOT_COLUMNS.index_with { |column| self[column] }

    versions.create!(
      snapshot.merge(
        "version_number" => latest_version_number + 1,
        "editor" => editor,
        "change_note" => change_note.presence
      )
    )
  end

  # 내용이 실제로 달라졌을 때만 기록해서 히스토리가 지저분해지지 않게 한다.
  def record_version_if_changed!(editor:, change_note: nil)
    return nil if (saved_changes.keys & PromptVersion::SNAPSHOT_COLUMNS).empty?

    record_version!(editor: editor, change_note: change_note)
  end

  # 되돌리기도 지우지 않고 새 버전으로 쌓는다. 위키니까.
  def restore_version!(version, editor:)
    transaction do
      assign_attributes(PromptVersion::SNAPSHOT_COLUMNS.index_with { |column| version[column] })
      self.last_editor = editor
      save!
      record_version!(editor: editor, change_note: "v#{version.version_number} 내용으로 되돌림")
    end
  end

  private

  def assign_slug
    self.slug = Slug.unique_for(title, scope: Prompt.all, fallback: "prompt") if slug.blank?
  end

  # 본문에서 찾은 자리표시자와 사용자가 적어 둔 설명을 합친다.
  # 본문에서 사라진 변수는 설명도 같이 정리된다.
  def sync_variables
    described = Array(variables).filter_map { |entry| entry.is_a?(Hash) ? entry.with_indifferent_access : nil }
                                .index_by { |entry| entry[:name].to_s }

    self.variables = detected_variables.map do |name|
      entry = described[name] || {}
      {
        "name" => name,
        "description" => entry[:description].to_s,
        "example" => entry[:example].to_s
      }
    end
  end
end
