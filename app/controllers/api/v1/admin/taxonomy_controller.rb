module Api
  module V1
    module Admin
      # 트리 분류(카테고리, 도메인) 관리의 공통 부분.
      # 둘은 "문서가 남았을 때 지울 수 있는가" 와 몇 가지 칸만 다르다.
      class TaxonomyController < BaseController
        before_action :set_node, only: %i[update destroy]

        def index
          render json: { collection_key => tree_rows }
        end

        def create
          node = model.new(node_params.except(:parent_slug))
          node.slug = Slug.unique_for(node.name, scope: model.all, fallback: resource_key) if node.slug.blank?
          node.parent = parent_from_params
          node.position = next_position(node.parent_id)

          return render_invalid(node) unless node.save

          audit!("#{resource_key}.created", target: node, details: { "parent" => node.parent&.name }.compact)
          render json: { resource_key => row_for(node) }, status: :created
        end

        # 슬러그는 주소다. 바뀌면 공유된 링크가 깨지므로 건드리지 않는다.
        # 상위를 바꾸면 새 자리의 맨 뒤로 간다.
        def update
          previous_parent = @node.parent
          @node.assign_attributes(node_params.except(:slug, :parent_slug))

          if node_params.key?(:parent_slug)
            new_parent = parent_from_params
            if new_parent&.id != @node.parent_id
              @node.parent = new_parent
              @node.position = next_position(new_parent&.id)
            end
          end

          return render_invalid(@node) unless @node.save

          details = {}
          if previous_parent&.id != @node.parent_id
            details["moved"] = [ previous_parent&.name || "맨 위", @node.parent&.name || "맨 위" ]
          end
          audit!("#{resource_key}.updated", target: @node, details: details)
          render json: { resource_key => row_for(@node) }
        end

        def destroy
          if @node.children.exists?
            return render json: {
              error: "하위 항목이 있어 지울 수 없습니다.",
              detail: "하위 #{@node.children.count}개를 먼저 다른 곳으로 옮기거나 지워 주세요."
            }, status: :unprocessable_entity
          end

          blocked = destroy_blocker(@node)
          return render json: blocked, status: :unprocessable_entity if blocked

          name = @node.name
          details = destroy_details(@node)
          @node.destroy!
          audit!("#{resource_key}.destroyed", target_label: name, details: details)

          head :no_content
        end

        # 같은 상위 아래 형제들의 순서를 받은 차례대로 매긴다.
        def reorder
          slugs = Array(params[:slugs]).map(&:to_s)
          nodes = model.where(slug: slugs).index_by(&:slug)

          if nodes.values.map(&:parent_id).uniq.size > 1
            return render json: { error: "같은 상위 아래에 있는 항목끼리만 순서를 바꿀 수 있습니다." },
                          status: :unprocessable_entity
          end

          model.transaction do
            slugs.each_with_index { |slug, index| nodes[slug]&.update!(position: index + 1) }
          end

          audit!("#{resource_key}.reordered", details: { "order" => slugs.map { |slug| nodes[slug]&.name }.compact })
          render json: { collection_key => tree_rows }
        end

        private

        # ---- 자식 컨트롤러가 정한다 ----

        def model = raise(NotImplementedError)
        def resource_key = raise(NotImplementedError)
        def permitted_attributes = %i[name slug description parent_slug]
        def tree_rows = raise(NotImplementedError)
        def destroy_blocker(_node) = nil
        def destroy_details(_node) = {}

        # ---- 공통 ----

        def collection_key = resource_key.pluralize

        def set_node
          @node = model.find_by!(slug: params[:slug])
        end

        def node_params
          params.require(resource_key).permit(*permitted_attributes)
        end

        # parent_slug 가 비어 있으면 맨 위(루트)로 둔다.
        def parent_from_params
          slug = node_params[:parent_slug].to_s.strip
          slug.empty? ? nil : model.find_by!(slug: slug)
        end

        def next_position(parent_id)
          (model.where(parent_id: parent_id).maximum(:position) || 0) + 1
        end

        def row_for(node)
          tree_rows.find { |row| row[:id] == node.id }
        end
      end
    end
  end
end
