class AddLobbyCodesAndGameState < ActiveRecord::Migration[7.2]
  def change
    add_column :lobbies, :code, :string
    add_column :games, :last_move, :string
    add_column :games, :pgn, :text
    add_column :games, :version, :integer, null: false, default: 0

    add_index :lobbies, :code, unique: true
  end
end
