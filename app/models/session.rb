# 로그인 한 번이 세션 한 줄. 토큰을 Authorization 헤더로 들고 다닌다.
# 쿠키 대신 토큰을 쓰는 이유는 프론트가 다른 오리진(3000)에서 돌기 때문이다.
class Session < ApplicationRecord
  LIFETIME = 14.days
  IDLE_TIMEOUT = 12.hours

  belongs_to :user

  has_secure_token :token, length: 36

  before_validation :start_clock, on: :create

  scope :live, -> { where(expires_at: Time.current..) }
  scope :recent_first, -> { order(last_active_at: :desc) }

  def expired?
    expires_at <= Time.current || last_active_at <= IDLE_TIMEOUT.ago
  end

  # 쓰고 있는 세션은 만료 시각을 뒤로 민다. 매 요청마다 쓰긴 아까우니
  # 1분 넘게 지났을 때만 기록한다.
  def touch_activity!(ip: nil, user_agent: nil)
    return if last_active_at > 1.minute.ago

    update_columns(
      last_active_at: Time.current,
      ip_address: ip.presence || ip_address,
      user_agent: user_agent.presence || self.user_agent,
      updated_at: Time.current
    )
  end

  def self.sweep_expired
    where(expires_at: ..Time.current).delete_all
  end

  private

  def start_clock
    self.last_active_at ||= Time.current
    self.expires_at ||= LIFETIME.from_now
  end
end
