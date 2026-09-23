module Api
  module V1
    module Admin
      class DomainsController < TaxonomyController
        private

        def model = Domain
        def resource_key = "domain"

        def tree_rows
          DomainSerializer.tree(Domain.all.to_a, memberships: PromptDomain.all)
        end

        # 도메인은 문서에 없어도 되는 꼬리표라, 지우면 문서에서 떨어지기만 한다.
        def destroy_details(domain)
          { "detached" => domain.prompt_domains.count }
        end
      end
    end
  end
end
