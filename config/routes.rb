Rails.application.routes.draw do
  devise_for :users
  root to: 'games#play'
  resources :games do
    put 'move_by_player'
  end
end
