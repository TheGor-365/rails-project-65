# frozen_string_literal: true

Rails.application.routes.draw do
  get 'up' => 'rails/health#show', as: :rails_health_check
  get 'service-worker' => 'rails/pwa#service_worker', as: :pwa_service_worker
  get 'manifest' => 'rails/pwa#manifest', as: :pwa_manifest

  # Direct uploads are unused; keep Active Storage file-serving routes.
  post '/rails/active_storage/direct_uploads',
       to: 'web/direct_uploads#create'

  scope module: :web do
    resources :bulletins, only: %i[index show new create edit update] do
      member do
        patch :to_moderate
        patch :archive
      end
      resource :favorite, only: %i[create destroy], controller: :favorites
    end
    get 'favorites', to: 'favorites#index', as: :favorites

    resource :profile, only: :show, controller: :profiles, path: 'profile'

    root 'bulletins#index'

    post   'auth/:provider',          to: 'auth#start',     as: :auth_request
    get    'auth/:provider/callback', to: 'auth#callback',  as: :callback_auth
    get 'auth/github/link', to: 'auth#link_form', as: :github_link_form
    post 'auth/github/link', to: 'auth#prepare_link', as: :prepare_github_link

    delete 'signout',                 to: 'auth#destroy',   as: :signout

    namespace :admin, module: :admin, as: :admin do
      resources :categories
      resources :bulletins, only: %i[index show edit update destroy] do
        member do
          patch :publish
          patch :reject
          patch :archive
        end
      end
    end
  end
end
