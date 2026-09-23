module Api
  module V1
    class TagsController < ApplicationController
      def index
        counts = Tag.joins(:prompts).merge(Prompt.listable).group("tags.id").count

        tags = Tag.ordered.map { |tag| TagSerializer.call(tag, prompts_count: counts.fetch(tag.id, 0)) }
        tags = tags.reject { |tag| tag[:prompts_count].zero? } if params[:used].to_s == "true"

        render json: { tags: tags }
      end
    end
  end
end
