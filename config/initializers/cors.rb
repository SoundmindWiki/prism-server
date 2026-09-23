# Nuxt 개발 서버와 사내 배포 주소에서 오는 요청을 허용한다.
# 운영에서는 PRISM_ALLOWED_ORIGINS 에 쉼표로 구분해 넣으면 된다.
# 예: PRISM_ALLOWED_ORIGINS="https://prism.example.internal"
allowed_origins = ENV.fetch("PRISM_ALLOWED_ORIGINS", "http://localhost:3000,http://127.0.0.1:3000")
                     .split(",")
                     .map(&:strip)
                     .reject(&:blank?)

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed_origins)

    resource "/api/*",
      headers: :any,
      expose: %w[X-Wiki-User-Email],
      methods: %i[get post patch put delete options head]
  end
end
