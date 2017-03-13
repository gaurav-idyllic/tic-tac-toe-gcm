class GameService < BaseService
  attr_reader :user, :game, :cells

  def initialize(user, game)
    @user = user
    @game = game
    @cells = @game.cells
  end

  SYSTEM_CELL_VALUE = 0
  MINIMUM_CELLS_FOR_WIN_CHECK = 6
  CENTER_POSITION = [1, 1]
  CORNER_POSITIONS = [[0, 0], [0, 2], [2, 2], [2, 0]]
  WINNING_POSITIONS = [
    [[0, 0], [0, 1], [0, 2]],
    [[1, 0], [1, 1], [1, 2]],
    [[2, 0], [2, 1], [2, 2]],
    [[0, 0], [1, 1], [2, 2]],
    [[2, 0], [1, 1], [0, 2]],
    [[0, 0], [1, 0], [2, 0]],
    [[0, 1], [1, 1], [2, 1]],
    [[0, 2], [1, 2], [2, 2]]
  ]

  def move_by_player(params)
    tie = false
    user_win = false
    system_win = false
    _, x_position, y_position = params[:move].split('_')
    cell = cells.find_by(x_position: x_position, y_position: y_position, value: nil)
    return {
      success: false,
      errors: ['move already taken.'],
      system_move: [],
      user_win: user_win,
      system_win: system_win,
      tie: tie
    } if cell.nil?
    cell.update_value(user.id)
    system_move = calculate_system_move(x_position, y_position)
    if cells.where('value is not NULL').count >= MINIMUM_CELLS_FOR_WIN_CHECK
      user_win = check_win(user.id)
      system_win = check_win(SYSTEM_CELL_VALUE) unless user_win
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

  def calculate_system_move(x_position, y_position)
    current_move = [x_position.to_i, y_position.to_i]
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
      system_cell.update_value(SYSTEM_CELL_VALUE)
    end
    game.finished! unless cells.where(value: nil).present?
    system_cell.present? ? [system_cell.x_position, system_cell.y_position] : []
  end

  def check_win(user_id)
    filled_cells = cells.where(value: user_id)
    selected_positions = filled_cells.map { |cell| [cell.x_position, cell.y_position] }
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
