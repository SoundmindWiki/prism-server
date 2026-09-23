source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.3", ">= 8.1.3.1"
# PostgreSQL
gem "pg", "~> 1.5"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# 로그인 비밀번호 해싱 (has_secure_password)
gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem "rack-cors"
# Ruby 4.0 에 기본 포함된 json 3.x 는 JSON.parse 가 키워드 인자만 받는데,
# ActiveSupport 8.1 은 아직 위치 인자로 넘긴다. 둘을 같이 쓰면 json 컬럼과
# JSON 요청 본문 파싱이 통째로 깨지므로 2.x 로 고정한다.
# (ActiveSupport 가 고쳐지면 이 핀은 걷어내도 된다.)
gem "json", "~> 2.9"

# 유효성 검사 메시지를 한국어로 돌려주기 위한 기본 번역
gem "rails-i18n"


group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false
end
