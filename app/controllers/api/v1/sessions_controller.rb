module Api
  module V1
    class SessionsController < ApplicationController
      skip_before_action :authenticate!, only: :create

      # 로그인. 실패 이유를 구체적으로 알려 주지 않는 편이 안전하지만,
      # 사내 도구에서는 "계정이 잠겼다" 정도는 알려 주는 편이 문의가 줄어든다.
      def create
        credentials = params.require(:session).permit(:email, :password)
        email = credentials[:email].to_s.strip.downcase
        user = User.find_by(email: email)

        unless user&.authenticate(credentials[:password].to_s)
          # 실패도 남긴다. 누가 남의 계정으로 계속 두드리는지 관리자가 알아야 한다.
          # 없는 이메일이면 구성원과 이어 붙일 수 없으니 적어 넣은 주소를 그대로 이름 자리에 둔다.
          track_activity("session.failed", actor: user, actor_name: user&.name || email.presence || "(빈 이메일)",
                         details: request_origin.merge("email" => email, "reason" => user ? "wrong_password" : "unknown_email"))
          return render json: { error: "이메일 또는 비밀번호가 맞지 않습니다." }, status: :unauthorized
        end

        unless user.can_sign_in?
          track_activity("session.failed", actor: user, details: request_origin.merge("email" => email, "reason" => "deactivated"))
          return render json: { error: "사용이 중지된 계정입니다. 관리자에게 문의해 주세요." }, status: :forbidden
        end

        session = user.sessions.create!(
          ip_address: request.remote_ip,
          user_agent: request.user_agent
        )
        user.update_column(:last_signed_in_at, Time.current)
        track_activity("session.signed_in", actor: user, details: request_origin)

        render json: {
          token: session.token,
          expires_at: session.expires_at,
          user: UserSerializer.call(user)
        }, status: :created
      end

      def show
        current_session.touch_activity!(ip: request.remote_ip, user_agent: request.user_agent)

        render json: { user: UserSerializer.call(current_user), expires_at: current_session.expires_at }
      end

      def destroy
        track_activity("session.signed_out", details: request_origin)
        current_session.destroy!

        head :no_content
      end
    end
  end
end
