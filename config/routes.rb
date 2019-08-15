Rails.application.routes.draw do
  get 'sessions/new'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :users do
    resources :posts
  end

  get '/logout', to: 'sessions#destroy'
  get '/login', to: 'sessions#new'
  post '/login' => 'sessions#create'
end
