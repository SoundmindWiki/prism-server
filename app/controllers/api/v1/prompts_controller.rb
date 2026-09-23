module Api
  module V1
    class PromptsController < ApplicationController
      before_action :set_prompt, only: %i[show update move archive copy markdown]

      def index
        scope = filtered_scope
        page, per_page = pagination
        total = scope.distinct.count(:id)

        prompts = scope.with_associations
                       .sorted_by(params[:sort])
                       .limit(per_page)
                       .offset((page - 1) * per_page)

        render json: {
          prompts: prompts.map { |prompt| PromptSerializer.summary(prompt) },
          meta: {
            total: total,
            page: page,
            per_page: per_page,
            total_pages: (total / per_page.to_f).ceil
          }
        }
      end

      def show
        # 조회수는 updated_at 을 건드리지 않는다. 읽기만 해도 "최근 수정" 순서가 흔들리면 곤란하다.
        @prompt.increment!(:view_count)

        render json: { prompt: PromptSerializer.detail(@prompt) }
      end

      def create
        prompt = Prompt.new(prompt_params.except(:category_slug, :change_note))
        prompt.category = resolved_category || prompt.category
        prompt.author = current_user
        prompt.last_editor = current_user

        return render_invalid(prompt) unless prompt.save

        prompt.record_version!(editor: current_user, change_note: prompt_params[:change_note].presence || "최초 작성")
        track_activity("prompt.created", target: prompt, details: { "category" => prompt.category.name })
        render json: { prompt: PromptSerializer.detail(prompt) }, status: :created
      end

      def update
        @prompt.assign_attributes(prompt_params.except(:category_slug, :change_note))
        @prompt.category = resolved_category if resolved_category
        @prompt.last_editor = current_user

        return render_invalid(@prompt) unless @prompt.save

        version = @prompt.record_version_if_changed!(editor: current_user, change_note: prompt_params[:change_note])
        # 내용이 그대로면 버전이 안 생긴다. 그래도 태그나 카테고리를 바꿨을 수 있으니 수정 자체는 남긴다.
        track_activity("prompt.updated", target: @prompt,
                       details: { "version" => version&.version_number, "note" => prompt_params[:change_note].presence }.compact)
        render json: { prompt: PromptSerializer.detail(@prompt.reload) }
      end

      # 폴더만 바꾼다. 내용이 그대로라 새 버전은 만들지 않는다.
      def move
        category = Category.find_by!(slug: params[:category_slug])
        previous = @prompt.category

        if previous.id != category.id
          @prompt.update!(category: category, last_editor: current_user)
          track_activity("prompt.moved", target: @prompt,
                         details: { "from" => previous.name, "to" => category.name })
        end

        render json: { prompt: PromptSerializer.detail(@prompt.reload) }
      end

      # 보관: 목록에서 내려가지만 링크와 히스토리는 그대로 남는다. 위키에서 기본으로 권하는 정리 방법.
      def archive
        @prompt.update!(status: :archived, last_editor: current_user)
        track_activity("prompt.archived", target: @prompt)

        render json: { prompt: PromptSerializer.detail(@prompt) }
      end

      # "복사" 버튼이 실제로 얼마나 눌렸는지가 이 위키에서 가장 정직한 인기 지표다.
      def copy
        @prompt.increment!(:copy_count)
        track_activity("prompt.copied", target: @prompt)

        render json: { slug: @prompt.slug, copy_count: @prompt.copy_count }
      end

      # 문서 하나를 .md 파일로 내려준다. 형식은 PromptMarkdown 에 적어 두었다.
      def markdown
        track_activity("prompt.downloaded", target: @prompt)
        send_data PromptMarkdown.dump(@prompt),
                  filename: PromptMarkdown.filename(@prompt),
                  type: "text/markdown; charset=utf-8",
                  disposition: "attachment"
      end

      # .md 파일 내용을 읽어 "새 문서" 폼에 채울 값으로 돌려준다. 저장은 하지 않는다.
      # 올린 사람이 한 번 훑어보고 카테고리 같은 걸 고친 뒤 저장하게 하려는 것이다.
      def parse_markdown
        text = params[:markdown].to_s

        if text.strip.empty?
          return render json: { error: "빈 파일입니다." }, status: :unprocessable_entity
        end

        if text.bytesize > PromptMarkdown::MAX_BYTES
          return render json: { error: "파일이 너무 큽니다. 256KB 까지만 불러올 수 있습니다." }, status: 413
        end

        result = PromptMarkdown.parse(text, filename: params[:filename])
        render json: { prompt: result.attributes, warnings: result.warnings }
      end

      private

      def set_prompt
        @prompt = Prompt.with_associations.find_by!(slug: params[:slug])
      end

      def filtered_scope
        scope = Prompt.search(params[:q])
                      .in_category(params[:category])
                      .in_domain(params[:domain])
                      .with_tag(params[:tag])

        status = params[:status].to_s
        return scope.where(status: status) if Prompt.statuses.key?(status)
        return scope if status == "all"

        scope.listable
      end

      def resolved_category
        return @resolved_category if defined?(@resolved_category)

        slug = prompt_params[:category_slug]
        @resolved_category = slug.present? ? Category.find_by!(slug: slug) : nil
      end

      def prompt_params
        @prompt_params ||= params.require(:prompt).permit(
          :title, :summary, :body, :usage_notes, :model_hint, :status,
          :category_id, :category_slug, :change_note,
          tag_names: [],
          domain_slugs: [],
          variables: [ :name, :description, :example ]
        ).to_h
      end
    end
  end
end
