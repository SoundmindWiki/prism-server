require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "만들면 토큰과 만료 시각이 생긴다" do
    session = users(:jiwon).sessions.create!

    assert session.token.present?
    assert session.expires_at > Time.current
    assert_not session.expired?
  end

  test "토큰은 겹치지 않는다" do
    tokens = 5.times.map { users(:jiwon).sessions.create!.token }

    assert_equal 5, tokens.uniq.size
  end

  test "기한이 지나면 만료다" do
    session = users(:jiwon).sessions.create!
    session.update_columns(expires_at: 1.minute.ago)

    assert session.reload.expired?
  end

  test "오래 안 쓰면 만료로 친다" do
    session = users(:jiwon).sessions.create!
    session.update_columns(last_active_at: (Session::IDLE_TIMEOUT + 1.hour).ago)

    assert session.reload.expired?
  end

  test "활동 기록은 1분에 한 번만 남긴다" do
    session = users(:jiwon).sessions.create!
    first = session.last_active_at

    session.touch_activity!(ip: "10.0.0.1")
    assert_equal first.to_i, session.reload.last_active_at.to_i

    session.update_columns(last_active_at: 5.minutes.ago)
    session.touch_activity!(ip: "10.0.0.1")

    assert session.reload.last_active_at > 1.minute.ago
    assert_equal "10.0.0.1", session.ip_address
  end

  test "구성원을 지우면 세션도 함께 사라진다" do
    user = User.create!(name: "임시", email: "temp@example.com", password: TEST_PASSWORD)
    user.sessions.create!

    assert_difference -> { Session.count }, -1 do
      user.destroy!
    end
  end
end
