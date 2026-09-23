module Api
  module V1
    module Admin
      class UsersController < BaseController
        before_action :set_user, only: %i[update destroy reactivate reset_password]

        def index
          scope = User.search(params[:q])
          scope = scope.where(role: params[:role]) if User.roles.key?(params[:role].to_s)
          scope = scope.where(active: params[:active] != "false") if params[:active].present?

          page, per_page = pagination
          total = scope.count
          counts = Prompt.group(:author_id).count

          users = scope.ordered.limit(per_page).offset((page - 1) * per_page)

          render json: {
            users: users.map { |user| UserSerializer.admin(user, prompts_count: counts.fetch(user.id, 0)) },
            meta: meta_for(total, page, per_page)
          }
        end

        def create
          user = User.new(user_params)
          password = params.dig(:user, :password).presence || SecureRandom.alphanumeric(12)
          user.password = password

          return render_invalid(user) unless user.save

          audit!("user.created", target: user, details: { email: user.email, role: user.role })
          # 만들어 준 비밀번호는 이때 한 번만 보여 준다. 저장해 두지 않는다.
          render json: {
            user: UserSerializer.admin(user, prompts_count: 0),
            initial_password: params.dig(:user, :password).present? ? nil : password
          }.compact, status: :created
        end

        def update
          previous_role = @user.role
          attributes = user_params

          # 마지막 관리자의 권한을 내리면 아무도 백오피스에 못 들어간다.
          if attributes[:role].present? && attributes[:role] != "admin" && @user.last_active_admin?
            return render json: { error: "마지막 관리자의 권한은 내릴 수 없습니다." }, status: :unprocessable_entity
          end

          return render_invalid(@user) unless @user.update(attributes)

          audit!("user.updated", target: @user, details: { email: @user.email })
          if previous_role != @user.role
            audit!("user.role_changed", target: @user, details: { from: previous_role, to: @user.role })
          end

          render json: { user: UserSerializer.admin(@user) }
        end

        # 지우지 않고 비활성화한다. 작성한 문서와 히스토리가 남아야 하기 때문.
        def destroy
          if @user == current_user
            return render json: { error: "자기 계정은 중지할 수 없습니다." }, status: :unprocessable_entity
          end

          if @user.last_active_admin?
            return render json: { error: "마지막 관리자는 중지할 수 없습니다." }, status: :unprocessable_entity
          end

          @user.update!(active: false)
          @user.sessions.destroy_all
          audit!("user.deactivated", target: @user, details: { email: @user.email })

          render json: { user: UserSerializer.admin(@user) }
        end

        def reactivate
          @user.update!(active: true)
          audit!("user.reactivated", target: @user, details: { email: @user.email })

          render json: { user: UserSerializer.admin(@user) }
        end

        def reset_password
          password = params[:password].presence || SecureRandom.alphanumeric(12)
          @user.password = password

          return render_invalid(@user) unless @user.save

          # 비밀번호가 바뀌면 쓰던 기기는 전부 로그아웃시킨다.
          @user.sessions.destroy_all
          audit!("user.password_reset", target: @user, details: { email: @user.email })

          render json: { user: UserSerializer.admin(@user), initial_password: params[:password].present? ? nil : password }.compact
        end

        private

        def set_user
          @user = User.find(params[:id])
        end

        def user_params
          params.require(:user).permit(:name, :email, :department, :job_rank, :job_title, :role)
        end
      end
    end
  end
end
