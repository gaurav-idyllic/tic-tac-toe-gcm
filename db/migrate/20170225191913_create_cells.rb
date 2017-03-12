class CreateCells < ActiveRecord::Migration
  def change
    create_table :cells do |t|
      t.integer :value
      t.integer :game_id
      t.integer :x_position
      t.integer :y_position
      t.integer :order

      t.timestamps null: false
    end
  end
end
