Rails.application.routes.draw do

  devise_for :users

  root to: 'games#play'

  # get 'games/play' => 'games#play'
  resources :games do
    put 'receive_move_by_player'
  end
end
