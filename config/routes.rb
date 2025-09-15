Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  scope module: :web do
    resources :bulletins, only: %i[index new create]
    root "bulletins#index"
    post   'auth/:provider',          to: 'auth#request',   as: :auth_request
    get    'auth/:provider/callback', to: 'auth#callback',  as: :callback_auth
    delete 'signout',                 to: 'auth#destroy',   as: :signout

    namespace :admin, module: :admin, as: :admin do
      resources :categories
      resources :bulletins
    end
  end
end
