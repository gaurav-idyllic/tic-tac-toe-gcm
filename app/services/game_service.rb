class GameService < BaseService
  attr_reader :user, :game, :cells

  def initialize(user, game)
    @user = user
    @game = game
    @cells = @game.cells
  end

  WINNING_POSITIONS = [
                        [[0, 0], [1, 1], [2, 2]],
                        [[0, 0], [0, 1], [0, 2]],
                        [[1, 0], [1, 1], [1, 2]],
                        [[2, 0], [2, 1], [2, 2]],
                        [[2, 0], [1, 1], [0, 2]],
                        [[0, 0], [1, 0], [2, 0]],
                        [[0, 1], [1, 1], [2, 1]],
                        [[0, 2], [1, 2], [2, 2]]
                     ]
  CORNER_POSITIONS = [[0, 0], [0, 2], [2, 2], [2, 0]]
  CENTER_POSITION = [1, 1]

  def receive_move_by_player(params)
    tie = false
    user_win = false
    system_win = false
    move = params[:move].split('_')
    x_position = move[1]
    y_position = move[2]
    cell = cells.where(x_position: x_position, y_position: y_position, value: nil)
    unless cell.present?
      return {
        success: false,
        errors: ['move already taken.'],
        system_move: [],
        user_win: user_win,
        system_win: system_win,
        tie: tie
      }
    end
    cell.first.update_attributes(value: user.id)
    system_move = calculate_system_move(move)
    if cells.where('value is not NULL').count > 4
      user_win = check_win_of_player
      system_win = check_win_of_system unless user_win
    end
    tie = true unless cells.where(value: nil).present?
    {
      success: true,
      errors: [],
      system_move: system_move,
      user_win: user_win,
      system_win: system_win,
      tie: tie
    }
  end

  private

  def calculate_system_move(move)
    current_move = [move[1].to_i, move[2].to_i]
    filled_cells = cells.where('value is not NULL')
    system_cells = cells.where(value: 0)
    user_cells = cells.where(value: user.id)
    if filled_cells.one?
      if(CENTER_POSITION == current_move)
        system_cell_vals = CORNER_POSITIONS.first
        system_cell = cells.find_by(x_position: system_cell_vals[0], y_position: system_cell_vals[1])
      else
        system_cell = cells.find_by(x_position: CENTER_POSITION[0], y_position: CENTER_POSITION[1])
      end
    else # TODO UPDATE
      filled_positions_by_system = system_cells.map { |cell| [cell.x_position, cell.y_position] }
      if filled_positions_by_system.one?
        filled_positions_by_user = user_cells.map { |cell| [cell.x_position, cell.y_position] }
        all_corners = true
        filled_positions_by_user.each do |position|
          all_corners = all_corners && CORNER_POSITIONS.include?(position)
        end
        if all_corners
          WINNING_POSITIONS.each do |win_position_array|
            temp = win_position_array.clone
            filled_positions_by_user.each do |position|
              temp.delete(position)
            end
            if temp.one?
              system_cell = cells.find_by(x_position: temp.first[0], y_position: temp.first[1], value: nil)
              break if system_cell
            end
          end
          unless system_cell
            system_cell = cells.find_by(x_position: 1, y_position: 0, value: nil)
          end
        end
      end

      unless system_cell
        WINNING_POSITIONS.each do |win_position_array|
          temp = win_position_array.clone
          filled_positions_by_system.each do |position|
            temp.delete(position)
          end
          if temp.one?
            system_cell = cells.find_by(x_position: temp.first[0], y_position: temp.first[1], value: nil)
            break if system_cell
          end
        end
      end

      unless system_cell
        filled_positions_by_user = user_cells.map { |cell| [cell.x_position, cell.y_position] }
        WINNING_POSITIONS.each do |win_position_array|
          temp = win_position_array.clone
          filled_positions_by_user.each do |position|
            temp.delete(position)
          end
          if temp.one?
            system_cell = cells.find_by(x_position: temp.first[0], y_position: temp.first[1], value: nil)
            break if system_cell
          else
            filled_positions_by_user.each do |position|
              if CORNER_POSITIONS.include?(position)
                system_cell_vals = CORNER_POSITIONS[CORNER_POSITIONS.index(position) + 1]
                system_cell_vals = CORNER_POSITIONS.first if system_cell_vals.nil?
                system_cell = cells.find_by(x_position: system_cell_vals[0], y_position: system_cell_vals[1], value: nil)
                break if system_cell
              end
            end
          end
        end
      end
    end
    unless system_cell
      system_cell = cells.where(value: nil).first
    end
    if system_cell.present?
      system_cell.update_attributes(value: 0)
    end
    game.finished! unless cells.where(value: nil).present?
    system_cell.present? ? [system_cell.x_position, system_cell.y_position] : []
  end

  def check_win_of_player
    check_win(user.id)
  end

  def check_win_of_system
    check_win(0)
  end

  def check_win(user_id)
    filled_cells = cells.where(value: user_id)
    selected_positions = filled_cells.map { |x| [x.x_position, x.y_position] }
    WINNING_POSITIONS.each do |win_position_array|
      win = true
      win_position_array.each do |location|
        win = win && selected_positions.include?(location)
      end
      if win
        game.finished!
        return true
      end
    end
    return false
  end
end



# system_cell_vals = CORNER_POSITIONS[CORNER_POSITIONS.index(current_move) + 1]
        # system_cell_vals = CORNER_POSITIONS.first if system_cell_vals.nil?
        # system_cell = cells.find_by(x_position: system_cell_vals[0], y_position: system_cell_vals[1])
