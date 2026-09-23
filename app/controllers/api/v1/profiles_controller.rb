module Api
  module V1
    # 마이페이지. 관리자를 거치지 않고 스스로 할 수 있는 일들을 모아 둔다.
    class ProfilesController < ApplicationController
      RECENT_LIMIT = 5

      def show
        render json: {
          user: UserSerializer.call(current_user),
          stats: stats,
          authored: serialize(authored_scope.limit(RECENT_LIMIT)),
          edited: serialize(edited_scope.limit(RECENT_LIMIT)),
          sessions: sessions_payload
        }
      end

      # 이메일은 로그인 식별자라 본인이 바꾸지 못하게 한다. 바꿔야 하면 관리자가 한다.
      def update
        return render_invalid(current_user) unless current_user.update(profile_params)

        track_activity("profile.updated", details: { "changed" => current_user.saved_changes.keys - %w[updated_at] })
        render json: { user: UserSerializer.call(current_user) }
      end

      def password
        # 401 로 답하면 프론트가 세션 만료로 오해해 로그아웃시킨다.
        # 로그인은 되어 있고 적어 넣은 값만 틀린 것이므로 422 가 맞다.
        unless current_user.authenticate(params[:current_password].to_s)
          return render json: { error: "지금 쓰는 비밀번호가 맞지 않습니다." }, status: :unprocessable_entity
        end

        current_user.password = params[:password].to_s
        return render_invalid(current_user) unless current_user.save

        # 비밀번호가 바뀌면 다른 기기는 모두 내보낸다. 지금 보고 있는 창은 남긴다.
        signed_out = current_user.sessions.where.not(id: current_session.id).destroy_all.size
        track_activity("profile.password_changed", details: { "signed_out_devices" => signed_out })

        render json: { user: UserSerializer.call(current_user), signed_out_devices: signed_out }
      end

      def revoke_session
        session = current_user.sessions.find(params[:id])

        if session.id == current_session.id
          return render json: {
            error: "지금 쓰고 있는 기기는 여기서 내보낼 수 없습니다.",
            detail: "왼쪽 아래 로그아웃 버튼을 눌러 주세요."
          }, status: :unprocessable_entity
        end

        session.destroy!
        track_activity("profile.sessions_revoked", details: { "count" => 1 })
        head :no_content
      end

      def revoke_sessions
        revoked = current_user.sessions.where.not(id: current_session.id).destroy_all.size
        track_activity("profile.sessions_revoked", details: { "count" => revoked }) if revoked.positive?

        render json: { revoked: revoked }
      end

      private

      def stats
        {
          authored: current_user.authored_prompts.count,
          edited: edited_scope.count,
          edits: my_versions.count,
          copies: current_user.authored_prompts.sum(:copy_count)
        }
      end

      def authored_scope
        current_user.authored_prompts.listable.with_associations.sorted_by("recent")
      end

      # 내가 고친 문서. 내가 만든 것도 포함되지만, 손댄 흔적이 있는 문서라는 뜻이다.
      def edited_scope
        Prompt.listable.where(id: my_versions.select(:prompt_id)).with_associations.sorted_by("recent")
      end

      def my_versions
        PromptVersion.where(editor_id: current_user.id)
      end

      def serialize(scope)
        scope.map { |prompt| PromptSerializer.summary(prompt) }
      end

      def sessions_payload
        current_user.sessions.live.recent_first.map do |session|
          SessionSerializer.call(session, current: session.id == current_session.id)
        end
      end

      def profile_params
        params.require(:user).permit(:name, :department, :job_rank, :job_title)
      end
    end
  end
end
