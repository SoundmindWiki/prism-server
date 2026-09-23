module Api
  module V1
    # 위키 화면에서 쓰는 조회 전용. 도메인을 만들고 고치는 일은 백오피스에서 한다.
    class DomainsController < ApplicationController
      def index
        visible = PromptDomain.joins(:prompt).merge(Prompt.listable)

        render json: { domains: DomainSerializer.tree(Domain.all.to_a, memberships: visible) }
      end
    end
  end
end
