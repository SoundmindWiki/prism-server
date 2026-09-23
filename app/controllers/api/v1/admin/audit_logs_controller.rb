module Api
  module V1
    module Admin
      class AuditLogsController < BaseController
        # 현황에서 셀 활동. 나머지는 목록에서 보면 된다.
        SUMMARY_ACTIONS = %w[
          session.signed_in session.failed
          prompt.created prompt.updated prompt.copied prompt.downloaded
        ].freeze
        PERIODS = { "1" => 1.day, "7" => 7.days, "30" => 30.days }.freeze

        def index
          scope = filtered_scope
          page, per_page = pagination(default_per_page: 30)
          total = scope.count

          render json: {
            logs: scope.recent_first.limit(per_page).offset((page - 1) * per_page).map { |log| AuditLogSerializer.call(log) },
            groups: AuditLog::GROUPS.map { |key, group| { value: key, label: group[:label] } },
            actions: action_options,
            meta: meta_for(total, page, per_page)
          }
        end

        # 구성원별 현황. "누가 요즘 이걸 쓰고 있나" 를 한 표로 본다.
        # 아무것도 안 한 사람도 빠뜨리지 않고 넣는다 — 안 쓰는 사람을 찾는 게 이 표의 절반이다.
        def summary
          since = PERIODS.fetch(params[:days].to_s, 7.days).ago
          period_logs = AuditLog.where(created_at: since.., action: SUMMARY_ACTIONS).where.not(user_id: nil)

          counts = period_logs.group(:user_id, :action).count
          last_activity = AuditLog.where.not(user_id: nil).group(:user_id).maximum(:created_at)

          members = User.order(active: :desc, name: :asc).map do |user|
            count_for = ->(action) { counts.fetch([ user.id, action ], 0) }

            {
              user: UserSerializer.call(user),
              last_activity_at: last_activity[user.id],
              last_signed_in_at: user.last_signed_in_at,
              counts: {
                signed_in: count_for.("session.signed_in"),
                failed: count_for.("session.failed"),
                created: count_for.("prompt.created"),
                updated: count_for.("prompt.updated"),
                copied: count_for.("prompt.copied"),
                downloaded: count_for.("prompt.downloaded")
              }
            }
          end

          active_ids = counts.keys.map(&:first).uniq
          render json: {
            since: since,
            totals: {
              members: User.enabled.count,
              active_members: User.enabled.where(id: active_ids).count,
              signed_in: period_logs.where(action: "session.signed_in").count,
              failed: period_logs.where(action: "session.failed").count +
                      AuditLog.where(created_at: since.., action: "session.failed", user_id: nil).count,
              created: period_logs.where(action: "prompt.created").count,
              updated: period_logs.where(action: "prompt.updated").count,
              copied: period_logs.where(action: "prompt.copied").count
            },
            members: members
          }
        end

        private

        def filtered_scope
          scope = AuditLog.all
          scope = scope.in_group(params[:group]) if params[:group].present?
          scope = scope.where(action: params[:action_type]) if params[:action_type].present?
          scope = scope.where(user_id: params[:user_id]) if params[:user_id].present?
          scope = scope.where(created_at: PERIODS[params[:days].to_s].ago..) if PERIODS.key?(params[:days].to_s)
          scope
        end

        # 갈래를 골랐으면 그 갈래의 종류만 보여 준다.
        def action_options
          actions = params[:group].present? && AuditLog::GROUPS.key?(params[:group]) ?
                      AuditLog::GROUPS[params[:group]][:actions] :
                      AuditLog::ACTION_LABELS
          actions.map { |value, label| { value: value, label: label } }
        end
      end
    end
  end
end
