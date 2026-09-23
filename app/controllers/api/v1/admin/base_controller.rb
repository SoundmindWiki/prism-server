module Api
  module V1
    module Admin
      # 백오피스 전용. 관리자가 아니면 여기서 막힌다.
      class BaseController < ApplicationController
        before_action :require_admin!
      end
    end
  end
end
