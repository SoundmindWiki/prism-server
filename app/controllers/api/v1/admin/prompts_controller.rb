module Api
  module V1
    module Admin
      # 백오피스의 문서 관리. 위키 화면과 달리 초안·보관까지 전부 보인다.
      class PromptsController < BaseController
        before_action :set_prompt, only: %i[update destroy]

        def index
          scope = Prompt.search(params[:q]).in_category(params[:category])
          scope = scope.where(status: params[:status]) if Prompt.statuses.key?(params[:status].to_s)

          page, per_page = pagination(default_per_page: 25)
          total = scope.distinct.count(:id)

          prompts = scope.with_associations.sorted_by(params[:sort]).limit(per_page).offset((page - 1) * per_page)

          render json: {
            prompts: prompts.map { |prompt| PromptSerializer.summary(prompt).merge(version_count: prompt.latest_version_number) },
            meta: meta_for(total, page, per_page)
          }
        end

        def update
          status = params.require(:prompt).permit(:status)[:status]
          return render json: { error: "알 수 없는 상태입니다." }, status: :unprocessable_entity unless Prompt.statuses.key?(status.to_s)

          previous = @prompt.status
          @prompt.update!(status: status, last_editor: current_user)
          audit!("prompt.status_changed", target: @prompt, details: { from: previous, to: status })

          render json: { prompt: PromptSerializer.summary(@prompt) }
        end

        # 여기서만 진짜로 지울 수 있다. 히스토리까지 함께 사라진다.
        def destroy
          title = @prompt.title
          versions = @prompt.versions.count
          @prompt.destroy!
          audit!("prompt.destroyed", target_label: title, details: { versions: versions })

          head :no_content
        end

        private

        def set_prompt
          @prompt = Prompt.find_by!(slug: params[:slug])
        end
      end
    end
  end
end
