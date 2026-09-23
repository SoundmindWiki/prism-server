module Api
  module V1
    module Admin
      class CategoriesController < TaxonomyController
        private

        def model = Category
        def resource_key = "category"
        def permitted_attributes = super + %i[color]

        # 백오피스에서는 초안·보관 문서까지 센다.
        def tree_rows
          CategorySerializer.tree(Category.all.to_a, direct_counts: Prompt.group(:category_id).count)
        end

        # 카테고리는 문서마다 반드시 하나 있어야 해서, 문서가 남아 있으면 지울 수 없다.
        def destroy_blocker(category)
          return unless category.prompts.exists?

          {
            error: "문서가 남아 있는 카테고리는 지울 수 없습니다.",
            detail: "문서 #{category.prompts.count}개를 다른 카테고리로 옮긴 뒤 다시 시도해 주세요."
          }
        end
      end
    end
  end
end
