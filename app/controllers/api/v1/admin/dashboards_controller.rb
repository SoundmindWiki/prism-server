module Api
  module V1
    module Admin
      class DashboardsController < BaseController
        def show
          render json: {
            members: {
              total: User.count,
              active: User.enabled.count,
              admins: User.enabled.admin.count,
              never_signed_in: User.enabled.where(last_signed_in_at: nil).count,
              signed_in_this_week: User.where(last_signed_in_at: 1.week.ago..).count
            },
            content: {
              published: Prompt.published.count,
              draft: Prompt.draft.count,
              archived: Prompt.archived.count,
              categories: Category.count,
              tags: Tag.count,
              orphan_tags: Tag.where.missing(:prompt_tags).count,
              edits: PromptVersion.count,
              copies: Prompt.sum(:copy_count)
            },
            sessions: {
              live: Session.live.count,
              devices: Session.live.distinct.count(:user_id)
            },
            top_contributors: top_contributors,
            stale_prompts: stale_prompts,
            recent_activity: AuditLog.in_group("admin").recent_first.limit(8).map { |log| AuditLogSerializer.call(log) }
          }
        end

        private

        # 문서를 많이 쓴 사람이 아니라, 많이 "고친" 사람을 센다.
        # 위키를 굴리는 건 대개 고치는 쪽이다.
        def top_contributors
          counts = PromptVersion.group(:editor_id).count
          User.where(id: counts.keys.compact).map do |user|
            { user: UserSerializer.call(user), edits: counts[user.id] }
          end.sort_by { |row| -row[:edits] }.first(5)
        end

        # 오래 손대지 않은 문서. 위키가 썩는 건 여기서 시작된다.
        def stale_prompts
          Prompt.published
                .where(updated_at: ..3.months.ago)
                .with_associations
                .order(:updated_at)
                .limit(5)
                .map { |prompt| PromptSerializer.summary(prompt) }
        end
      end
    end
  end
end
