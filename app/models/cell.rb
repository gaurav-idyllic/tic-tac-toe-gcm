class Cell < ActiveRecord::Base
  belongs_to :game
  default_scope { order(order: :asc) }

  def update_value(value)
    update_attributes(value: value)
  end
end
