Rails.application.routes.draw do
  root to: 'users#index'
  resources :users do
    collection do
      get 'search', to: 'users#new_search'
      get 'results', to: 'users#search'
    end
  end
end
