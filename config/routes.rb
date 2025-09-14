Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  root "bulletins#index"
  post 'auth/:provider', to: 'web/auth#request', as: :auth_request
  get  'auth/:provider/callback', to: 'web/auth#callback', as: :callback_auth
  delete 'signout', to: 'web/auth#destroy', as: :signout
end
