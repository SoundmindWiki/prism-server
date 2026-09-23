# 누가 언제 무엇을 했는지 남기는 활동 기록.
#
# 처음엔 백오피스에서 한 일만 적었지만, 이제 구성원이 위키에서 한 일도 적는다.
# 관리자가 "누가 요즘 이걸 얼마나 쓰고 있나" 를 볼 수 있어야 해서다.
#
# 문서 내용이 어떻게 바뀌었는지는 PromptVersion 이 따로 갖고 있다.
# 여기에는 "누가 언제 몇 번째 버전을 만들었다" 까지만 적는다.
class AuditLog < ApplicationRecord
  belongs_to :user, optional: true

  validates :actor_name, :action, presence: true

  scope :recent_first, -> { order(created_at: :desc) }

  # 기록 종류마다 어느 갈래에 속하는지. 백오피스에서 갈래별로 거를 때 쓴다.
  GROUPS = {
    "auth" => {
      label: "로그인",
      actions: {
        "session.signed_in" => "로그인",
        "session.signed_out" => "로그아웃",
        "session.failed" => "로그인 실패"
      }
    },
    "content" => {
      label: "문서",
      actions: {
        "prompt.created" => "문서 작성",
        "prompt.updated" => "문서 수정",
        "prompt.moved" => "문서 옮김",
        "folder.created" => "폴더 추가",
        "prompt.archived" => "문서 보관",
        "prompt.restored" => "이전 버전으로 되돌림"
      }
    },
    "usage" => {
      label: "사용",
      actions: {
        "prompt.copied" => "프롬프트 복사",
        "prompt.downloaded" => "MD 내려받기"
      }
    },
    "account" => {
      label: "계정",
      actions: {
        "profile.updated" => "내 정보 수정",
        "profile.password_changed" => "비밀번호 변경",
        "profile.sessions_revoked" => "다른 기기 로그아웃"
      }
    },
    "admin" => {
      label: "관리",
      actions: {
        "user.created" => "구성원 추가",
        "user.updated" => "구성원 정보 수정",
        "user.deactivated" => "구성원 비활성화",
        "user.reactivated" => "구성원 재활성화",
        "user.password_reset" => "비밀번호 재설정",
        "user.role_changed" => "권한 변경",
        "category.created" => "카테고리 추가",
        "category.updated" => "카테고리 수정",
        "category.destroyed" => "카테고리 삭제",
        "category.reordered" => "카테고리 순서 변경",
        "domain.created" => "도메인 추가",
        "domain.updated" => "도메인 수정",
        "domain.destroyed" => "도메인 삭제",
        "domain.reordered" => "도메인 순서 변경",
        "tag.renamed" => "태그 이름 변경",
        "tag.merged" => "태그 병합",
        "tag.destroyed" => "태그 삭제",
        "prompt.status_changed" => "문서 상태 변경",
        "prompt.destroyed" => "문서 삭제"
      }
    }
  }.freeze

  ACTION_LABELS = GROUPS.values.map { |group| group[:actions] }.reduce(:merge).freeze
  GROUP_OF_ACTION = GROUPS.flat_map { |key, group| group[:actions].keys.map { |action| [ action, key ] } }.to_h.freeze

  scope :in_group, ->(group) { GROUPS.key?(group.to_s) ? where(action: GROUPS[group.to_s][:actions].keys) : all }

  # 관리 기록. 남기지 못하면 요청을 오류로 끝내 관리자가 바로 알아채게 한다.
  # 누가 권한을 바꿨는지 같은 기록이 조용히 빠지면 안 되기 때문이다.
  # 다만 작업은 기록보다 먼저 저장되므로, 오류가 나도 작업 자체는 이미 반영돼 있을 수 있다.
  def self.record!(actor:, action:, target: nil, target_label: nil, details: {}, actor_name: nil)
    create!(build_attributes(actor:, action:, target:, target_label:, details:, actor_name:))
  end

  # 구성원 활동 기록. 복사처럼 자주 일어나는 일이라,
  # 기록이 실패했다고 복사까지 실패하게 두지는 않는다.
  def self.track(actor:, action:, target: nil, target_label: nil, details: {}, actor_name: nil)
    create!(build_attributes(actor:, action:, target:, target_label:, details:, actor_name:))
  rescue StandardError => error
    Rails.logger.warn("[activity] #{action} 기록 실패: #{error.class}: #{error.message}")
    nil
  end

  def self.build_attributes(actor:, action:, target:, target_label:, details:, actor_name:)
    details = details.to_h.stringify_keys
    # 문서에 대한 기록이면 백오피스에서 바로 열어 볼 수 있게 주소를 같이 남긴다.
    details["slug"] ||= target.slug if target.is_a?(Prompt)

    {
      user: actor,
      actor_name: actor_name.presence || actor&.name || "시스템",
      action: action,
      target_type: target&.class&.name,
      target_label: target_label || target.try(:name) || target.try(:title),
      details: details
    }
  end
  private_class_method :build_attributes

  def label
    ACTION_LABELS.fetch(action, action)
  end

  def group
    GROUP_OF_ACTION[action]
  end
end
