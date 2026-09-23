# 프롬프트가 저장될 때마다 남는 스냅샷. 위키의 "역사" 탭에 해당한다.
class PromptVersion < ApplicationRecord
  SNAPSHOT_COLUMNS = %w[title body summary usage_notes model_hint variables].freeze

  belongs_to :prompt
  belongs_to :editor, class_name: "User", optional: true

  validates :version_number, presence: true, uniqueness: { scope: :prompt_id }
  validates :title, :body, presence: true

  scope :newest_first, -> { order(version_number: :desc) }

  def initial?
    version_number == 1
  end

  # 바로 앞 버전과 비교해 어떤 항목이 바뀌었는지 알려 준다.
  # 목록에서 N+1 을 만들지 않도록 앞 버전은 호출하는 쪽에서 넘겨 준다.
  def changed_fields(previous = :lookup)
    previous = prompt.versions.find_by(version_number: version_number - 1) if previous == :lookup
    return [] if previous.nil?

    SNAPSHOT_COLUMNS.select { |column| self[column] != previous[column] }
  end
end
