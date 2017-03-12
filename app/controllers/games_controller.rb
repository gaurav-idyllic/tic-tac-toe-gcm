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
    move = params[:move].split('_')
    x_position = move[1]
    y_position = move[2]
    cells = @game.cells
    cell = cells.where(x_position: x_position, y_position: y_position, value: nil)
    unless cell.present?
      return render json: {
        success: false,
        errors: ['move already taken.']
      }
    end
    user_win = false
    system_win = false
    tie = false
    cell.first.update_attributes(value: current_user.id)
    game_service = GameService.new(current_user, @game)
    system_move = game_service.calculate_system_move(move)
    if cells.where('value is not NULL').count > 4
      user_win = game_service.check_win_of_player
      system_win = game_service.check_win_of_system unless user_win
    end
    tie = true unless cells.where(value: nil).present?
    render json: {
      success: true,
      errors: [],
      system_move: system_move,
      user_win: user_win,
      system_win: system_win,
      tie: tie
    }
  end

  private

  def load_game
    @game = Game.includes(:cells).find_by(id: params[:game_id])
  end


end
