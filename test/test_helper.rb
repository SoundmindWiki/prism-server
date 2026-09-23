ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    fixtures :all

    # 픽스처 비밀번호. 테스트에서는 해싱 비용을 낮춰 둔다.
    TEST_PASSWORD = "password123".freeze

    # 로그인한 것처럼 보이게 하는 헤더. 실제 로그인 흐름은
    # SessionsControllerTest 에서 따로 검증한다.
    def auth_headers(user)
      { "Authorization" => "Bearer #{user.sessions.create!.token}" }
    end

    def json_body
      # ActiveSupport::TestCase 안이라 JSON 이 ActiveSupport::JSON 으로 잡힌다. 최상위로 못 박는다.
      ::JSON.parse(response.body)
    end
  end
end
