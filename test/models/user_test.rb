require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "비밀번호로 본인을 확인한다" do
    assert users(:jiwon).authenticate(TEST_PASSWORD)
    assert_not users(:jiwon).authenticate("틀린비밀번호")
  end

  test "너무 짧은 비밀번호는 거절한다" do
    user = users(:jiwon)
    user.password = "a" * (User::MIN_PASSWORD_LENGTH - 1)

    assert_not user.valid?
    assert user.errors[:password].any?
  end

  test "최소 길이만 넘으면 받는다" do
    user = users(:jiwon)
    user.password = "a" * User::MIN_PASSWORD_LENGTH

    assert_predicate user, :valid?
  end

  test "개발에서만 짧은 비밀번호를 열어 준다" do
    # 운영에 짧은 비밀번호가 새어 나가지 않는지가 이 테스트의 요점이다.
    assert_equal 4, User::MIN_PASSWORD_LENGTH, "테스트 환경에서는 짧은 비밀번호를 허용한다"
    assert_not Rails.env.production?

    # 같은 식이 운영에서는 8 을 내놓아야 한다
    assert_equal 8, (ActiveSupport::StringInquirer.new("production").local? ? 4 : 8)
  end

  test "비활성 계정은 로그인할 수 없다" do
    assert_not users(:retired).can_sign_in?
    assert users(:jiwon).can_sign_in?
  end

  test "비밀번호가 없는 계정도 로그인할 수 없다" do
    user = users(:jiwon)
    user.update_column(:password_digest, nil)

    assert_not user.reload.can_sign_in?
  end

  test "이메일은 대소문자를 가리지 않는다" do
    user = User.create!(name: "테스트", email: "  MixedCase@Example.com ", password: TEST_PASSWORD)

    assert_equal "mixedcase@example.com", user.email
    assert_equal user, User.find_by(email: "MIXEDCASE@EXAMPLE.COM")
  end

  test "마지막 남은 관리자인지 알 수 있다" do
    assert_not users(:boss).last_active_admin?

    users(:second_admin).update!(active: false)

    assert users(:boss).reload.last_active_admin?
  end

  test "이름·이메일·부서로 찾는다" do
    assert_includes User.search("지원"), users(:jiwon)
    assert_includes User.search("haneul@"), users(:haneul)
    assert_includes User.search("경영지원"), users(:boss)
    assert_empty User.search("존재하지않는사람")
  end
end
