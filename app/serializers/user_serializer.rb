module UserSerializer
  module_function

  def call(user)
    return nil if user.nil?

    {
      id: user.id,
      name: user.name,
      email: user.email,
      department: user.department,
      job_rank: user.job_rank,
      job_title: user.job_title,
      initials: user.initials,
      role: user.role,
      active: user.active
    }
  end

  # 백오피스 목록에서만 쓰는 추가 정보.
  def admin(user, prompts_count: nil)
    call(user).merge(
      last_signed_in_at: user.last_signed_in_at,
      created_at: user.created_at,
      prompts_count: prompts_count,
      has_password: user.password_digest.present?
    )
  end
end
