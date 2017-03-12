class Game < ActiveRecord::Base
  has_many :cells, class_name: 'Cell', dependent: :destroy
  belongs_to :player, class_name: 'User'

  enum status: { current: 0, finished: 1 }

  LENGTH = 3

  def create_cells
    if cells.blank?
      Array.new(LENGTH) { |outer_index|
        Array.new(LENGTH) { |inner_index|
          cells.create(
            x_position: outer_index,
            y_position: inner_index,
            order: (outer_index+inner_index))
        }
      }
    else
      cells
    end
  end
end

