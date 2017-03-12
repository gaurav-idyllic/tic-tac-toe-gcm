class Cell < ActiveRecord::Base
  belongs_to :game
  default_scope { order(order: :asc) }
end
