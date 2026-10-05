class CreateGames < ActiveRecord::Migration[7.2]
  def change
    create_table :games do |t|
      t.references :user, null: false, foreign_key: true
      t.references :lobby, foreign_key: true
      t.references :white_player, null: false, foreign_key: { to_table: :users }
      t.references :black_player, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "waiting"
      t.string :turn, null: false, default: "white"
      t.string :result
      t.jsonb :board_state, null: false, default: {}
      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps
    end

    add_index :games, :status
    add_index :games, :turn
  end
end
