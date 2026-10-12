class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :username, null: false
      t.string :email, null: false
      t.string :password_digest, null: false

      t.timestamps
    end

    add_index :users, "LOWER(username)", unique: true, name: "index_users_on_lower_username"
    add_index :users, "LOWER(email)", unique: true, name: "index_users_on_lower_email"
  end
end
