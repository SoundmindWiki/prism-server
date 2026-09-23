module Api
  module V1
    module Admin
      class TagsController < BaseController
        before_action :set_tag, only: %i[update destroy merge]

        def index
          counts = Tag.joins(:prompts).group("tags.id").count

          tags = Tag.ordered.map { |tag| TagSerializer.call(tag, prompts_count: counts.fetch(tag.id, 0)) }
          tags = tags.select { |tag| tag[:prompts_count].zero? } if params[:orphan].to_s == "true"

          render json: { tags: tags }
        end

        def update
          previous = @tag.name
          # 이름이 바뀌면 슬러그도 따라가야 태그 주소가 이름과 맞는다.
          @tag.assign_attributes(name: params.require(:tag).permit(:name)[:name], slug: nil)

          return render_invalid(@tag) unless @tag.save

          audit!("tag.renamed", target: @tag, details: { from: previous, to: @tag.name })
          render json: { tag: TagSerializer.call(@tag) }
        end

        # 같은 뜻인데 따로 생긴 태그를 하나로 합친다. 위키에서 금방 생기는 일.
        def merge
          target = Tag.find_by!(slug: params.require(:into))
          return render json: { error: "같은 태그끼리는 합칠 수 없습니다." }, status: :unprocessable_entity if target == @tag

          moved = 0
          Tag.transaction do
            @tag.prompt_tags.find_each do |prompt_tag|
              if PromptTag.exists?(prompt_id: prompt_tag.prompt_id, tag_id: target.id)
                prompt_tag.destroy!
              else
                prompt_tag.update!(tag: target)
                moved += 1
              end
            end
            @tag.reload.destroy!
          end

          audit!("tag.merged", target: target, details: { from: @tag.name, into: target.name, moved: moved })
          render json: { tag: TagSerializer.call(target), moved: moved }
        end

        def destroy
          name = @tag.name
          @tag.destroy!
          audit!("tag.destroyed", target_label: name)

          head :no_content
        end

        private

        def set_tag
          @tag = Tag.find_by!(slug: params[:slug])
        end
      end
    end
  end
end
