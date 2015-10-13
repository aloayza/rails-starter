Rails.application.routes.draw do
  root 'static_pages#home'
  get 'help'				=> 'static_pages#help'
  get 'about'				=> 'static_pages#about'
  get 'signup'				=> 'users#new'
  get 'login'				=> 'sessions#new'
  post 'login'				=> 'sessions#create'
  delete 'logout'			=> 'sessions#destroy'
  resources :users
  resources :password_resets, only: [:new, :create, :edit, :update]
end
