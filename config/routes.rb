Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # 로그인 / 로그아웃 / 내 정보
      resource :session, only: %i[show create destroy]

      # ---- 마이페이지 ----
      resource :profile, only: %i[show update], controller: "profiles" do
        patch :password, on: :member
        delete "sessions/:id", to: "profiles#revoke_session", on: :member, as: :session
        delete "sessions", to: "profiles#revoke_sessions", on: :member
      end

      # ---- 위키 (로그인한 구성원 누구나) ----
      resource :stats, only: :show
      resources :tags, only: :index
      resources :categories, only: %i[index create]
      resources :domains, only: :index

      resources :prompts, only: %i[index show create update], param: :slug do
        post :parse_markdown, on: :collection

        member do
          post :copy
          post :move
          post :archive
          get :markdown
        end

        resources :versions, only: %i[index show], param: :number, controller: "prompt_versions" do
          post :restore, on: :member
        end
      end

      # ---- 백오피스 (관리자만) ----
      namespace :admin do
        resource :dashboard, only: :show
        resources :audit_logs, only: :index do
          get :summary, on: :collection
        end

        resources :users, only: %i[index create update destroy] do
          member do
            post :reactivate
            post :reset_password
          end
        end

        resources :categories, only: %i[index create update destroy], param: :slug do
          post :reorder, on: :collection
        end

        resources :domains, only: %i[index create update destroy], param: :slug do
          post :reorder, on: :collection
        end

        resources :tags, only: %i[index update destroy], param: :slug do
          post :merge, on: :member
        end

        resources :prompts, only: %i[index update destroy], param: :slug
      end
    end
  end
end
