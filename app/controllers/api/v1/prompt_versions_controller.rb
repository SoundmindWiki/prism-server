module Api
  module V1
    class PromptVersionsController < ApplicationController
      before_action :set_prompt

      def index
        versions = @prompt.versions.includes(:editor).newest_first.to_a
        # 오래된 것부터 짝지어야 "이번에 뭐가 바뀌었는지" 를 한 번의 조회로 계산할 수 있다.
        previous_by_number = versions.index_by(&:version_number)

        render json: {
          prompt: { slug: @prompt.slug, title: @prompt.title },
          versions: versions.map do |version|
            PromptVersionSerializer.call(version, previous: previous_by_number[version.version_number - 1])
          end
        }
      end

      def show
        version = @prompt.versions.includes(:editor).find_by!(version_number: params[:number])

        render json: {
          version: PromptVersionSerializer.call(
            version,
            previous: @prompt.versions.find_by(version_number: version.version_number - 1),
            include_body: true
          )
        }
      end

      def restore
        version = @prompt.versions.find_by!(version_number: params[:number])
        @prompt.restore_version!(version, editor: current_user)
        track_activity("prompt.restored", target: @prompt,
                       details: { "from_version" => version.version_number, "version" => @prompt.latest_version_number })

        render json: { prompt: PromptSerializer.detail(@prompt.reload) }
      rescue ActiveRecord::RecordInvalid => error
        render_invalid(error.record)
      end

      private

      def set_prompt
        @prompt = Prompt.find_by!(slug: params[:prompt_slug])
      end
    end
  end
end
