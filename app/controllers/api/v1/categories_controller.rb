module Api
  module V1
    # 위키 화면에서 쓰는 조회와, 사이드바에서 폴더를 만드는 일까지.
    # 이름 바꾸기·옮기기·삭제와 맨 위 팀 폴더 만들기는 백오피스(관리자)에서 한다.
    class CategoriesController < ApplicationController
      def index
        counts = Prompt.listable.group(:category_id).count

        render json: { categories: CategorySerializer.tree(Category.all.to_a, direct_counts: counts) }
      end

      # 팀 폴더 아래 하위 폴더. 팀원이 자기 팀 자료를 직접 정리할 수 있게 열어 뒀다.
      def create
        parent = Category.find_by(slug: folder_params[:parent_slug].to_s.strip)
        unless parent
          return render json: {
            error: "어느 폴더 안에 만들지 골라 주세요.",
            detail: "맨 위 팀 폴더는 백오피스에서만 만들 수 있습니다."
          }, status: :unprocessable_entity
        end

        category = Category.new(name: folder_params[:name].to_s.strip, parent: parent)
        # 색과 자리는 알아서 정한다. 폴더 하나 만들자고 물어볼 것이 많으면 안 만들게 된다.
        category.color = parent.color
        category.slug = Slug.unique_for(category.name, scope: Category.all, fallback: "folder")
        category.position = (Category.where(parent_id: parent.id).maximum(:position) || 0) + 1

        return render_invalid(category) unless category.save

        track_activity("folder.created", target: category, target_label: category.name,
                       details: { "parent" => parent.name })
        render json: { category: CategorySerializer.call(category, prompts_count: 0) }, status: :created
      end

      private

      def folder_params
        params.require(:category).permit(:name, :parent_slug)
      end
    end
  end
end
