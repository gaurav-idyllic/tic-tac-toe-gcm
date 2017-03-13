class GamesController < ApplicationController

  before_action :load_game, only: [:receive_move_by_player]

  # def new
  #   if params[:game_id].present?
  #     game = Game.find_by(id: params[:game_id])
  #   else
  #     game = Game.create!(player: @player )
  #   end
  #   redirect_to '/games/play'
  # end

  def play
    @player = current_user
    @game = Game.create!(player: @player )
    @game.create_cells
    # @system = User.find_by(email: 'system@gmail.com')
  end

  def receive_move_by_player
    render json: {
      success: false,
      errors: ['Game already finished.']
    } and return if @game.finished?
    game_service = GameService.new(current_user, @game)
    response = game_service.receive_move_by_player(params)
    render json: {
      success: response[:errors].blank?,
      errors: response[:errors],
      system_move: response[:system_move],
      user_win: response[:user_win],
      system_win: response[:system_win],
      tie: response[:tie]
    }
  end

  private

  def load_game
    @game = Game.includes(:cells).find_by(id: params[:game_id])
  end


end
