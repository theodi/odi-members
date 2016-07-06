Rails.application.routes.draw do
  get "errors/not_found"

  get "errors/server_error"

  resources :organisations, :only => [:index, :show, :update] do
    member do
      get :badge, defaults: {format: :js}
    end
  end

  resources :uploads, :only => [:new, :create] do
    collection do
      get :sample, defaults: {format: :csv}
    end
  end

  get '/logos/:level/:size/:colour.svg', defaults: {format: :svg}, to: 'badge#logo'
  get '/logos/:level/:size/:colour.png', defaults: {format: :png}, to: 'badge#badge'

  get '/401', :to => 'errors#unauthorized'
  get '/404', :to => 'errors#not_found'
  get '/500', :to => 'errors#server_error'
end
