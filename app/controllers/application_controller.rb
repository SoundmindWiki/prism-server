class ApplicationController < ActionController::API
  # 사내 도구지만 ERP 처럼 로그인 뒤에서만 돈다.
  # 토큰은 Authorization: Bearer <token> 으로 받는다.
  before_action :authenticate!

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_bad_request

  private

  def current_session
    return @current_session if defined?(@current_session)

    token = request.authorization.to_s[/\Abearer\s+(.+)\z/i, 1]&.strip
    session = token.present? ? Session.live.includes(:user).find_by(token: token) : nil

    @current_session = session&.expired? ? nil : session
  end

  def current_user
    return @current_user if defined?(@current_user)

    user = current_session&.user
    @current_user = user&.can_sign_in? ? user : nil
  end

  def authenticate!
    return true if current_user

    render json: { error: "로그인이 필요합니다.", code: "unauthenticated" }, status: :unauthorized
    false
  end

  def require_admin!
    return false unless current_user
    return true if current_user.admin?

    render json: { error: "관리자만 할 수 있습니다.", code: "forbidden" }, status: :forbidden
    false
  end

  def render_not_found(error = nil)
    render json: { error: "찾을 수 없습니다.", detail: error&.message }, status: :not_found
  end

  def render_bad_request(error = nil)
    render json: { error: "요청 형식이 올바르지 않습니다.", detail: error&.message }, status: :bad_request
  end

  def render_invalid(record)
    render json: {
      error: "저장하지 못했습니다.",
      details: record.errors.to_hash(true).transform_values { |messages| Array(messages) }
    }, status: :unprocessable_entity
  end

  def pagination(default_per_page: 20, max_per_page: 100)
    page = [ params[:page].to_i, 1 ].max
    per_page = params[:per_page].presence&.to_i || default_per_page
    [ page, per_page.clamp(1, max_per_page) ]
  end

  def meta_for(total, page, per_page)
    { total: total, page: page, per_page: per_page, total_pages: (total / per_page.to_f).ceil }
  end

  # 관리 기록. 남기지 못하면 요청을 오류로 끝낸다 (작업은 이미 저장됐을 수 있다).
  def audit!(action, target: nil, target_label: nil, details: {})
    AuditLog.record!(actor: current_user, action: action, target: target, target_label: target_label, details: details)
  end

  # 구성원 활동 기록. 실패해도 하던 일은 그대로 진행한다.
  def track_activity(action, target: nil, target_label: nil, details: {}, actor: current_user, actor_name: nil)
    AuditLog.track(actor: actor, action: action, target: target, target_label: target_label,
                   details: details, actor_name: actor_name)
  end

  # 로그인 기록에 남길 "어디서" 정보.
  def request_origin
    { "ip" => request.remote_ip, "device" => SessionSerializer.describe(request.user_agent) }
  end
end
