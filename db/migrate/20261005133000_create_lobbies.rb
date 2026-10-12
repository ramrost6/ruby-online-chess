class CreateLobbies < ActiveRecord::Migration[7.2]
  def change
    create_table :lobbies do |t|
      t.references :host, null: false, foreign_key: { to_table: :users }
      t.references :guest, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "waiting"
      t.string :time_control, null: false, default: "10+0"

      t.timestamps
    end

    add_index :lobbies, :status
  end
end
