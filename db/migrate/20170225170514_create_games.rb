class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.integer :status, null: false, default: 0
      t.integer :player_id

      t.timestamps null: false
    end
  end
end
