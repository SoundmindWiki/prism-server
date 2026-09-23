class User < ApplicationRecord
  # 개발·테스트에서는 짧은 비밀번호로 빠르게 드나들 수 있게 열어 두고,
  # 운영에서는 8자 미만을 받지 않는다.
  MIN_PASSWORD_LENGTH = Rails.env.local? ? 4 : 8

  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :audit_logs, dependent: :nullify
  has_many :authored_prompts, class_name: "Prompt", foreign_key: :author_id,
           inverse_of: :author, dependent: :restrict_with_error
  has_many :edited_prompts, class_name: "Prompt", foreign_key: :last_editor_id,
           inverse_of: :last_editor, dependent: :nullify
  has_many :prompt_versions, foreign_key: :editor_id, inverse_of: :editor, dependent: :nullify

  enum :role, { member: "member", admin: "admin" }, validate: true

  normalizes :email, with: ->(email) { email.to_s.strip.downcase }
  normalizes :name, with: ->(name) { name.to_s.strip }

  validates :name, presence: true, length: { maximum: 60 }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: MIN_PASSWORD_LENGTH }, allow_nil: true

  scope :enabled, -> { where(active: true) }
  scope :ordered, -> { order(:name) }

  # 이름·이메일·부서를 한 번에 훑는다. 백오피스 구성원 검색용.
  def self.search(query)
    term = query.to_s.strip
    return all if term.blank?

    pattern = "%#{sanitize_sql_like(term)}%"
    where("users.name ILIKE :q OR users.email ILIKE :q OR users.department ILIKE :q OR users.job_rank ILIKE :q", q: pattern)
  end

  # 로그인할 수 있는가. 퇴사자는 계정을 지우지 않고 비활성으로 돌린다
  # (작성한 문서와 히스토리가 남아야 하므로).
  def can_sign_in?
    active? && password_digest.present?
  end

  def initials
    name.to_s.strip.first(2)
  end

  # 마지막 관리자를 잠그면 아무도 백오피스에 못 들어간다.
  def last_active_admin?
    admin? && active? && User.enabled.admin.where.not(id: id).none?
  end
end
