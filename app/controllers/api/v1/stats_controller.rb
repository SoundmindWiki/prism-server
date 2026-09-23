module Api
  module V1
    # 첫 화면 상단에 얹을 숫자들.
    class StatsController < ApplicationController
      def show
        listable = Prompt.listable

        render json: {
          stats: {
            prompts: listable.count,
            drafts: Prompt.draft.count,
            archived: Prompt.archived.count,
            contributors: User.where(id: Prompt.select(:author_id)).count,
            tags: Tag.count,
            copies: Prompt.sum(:copy_count),
            edits: PromptVersion.count,
            updated_this_week: listable.where(updated_at: 1.week.ago..).count
          },
          recently_updated: listable.with_associations.sorted_by("recent").limit(5).map { |prompt| PromptSerializer.summary(prompt) },
          most_copied: listable.with_associations.sorted_by("popular").limit(5).map { |prompt| PromptSerializer.summary(prompt) }
        }
      end
    end
  end
end
