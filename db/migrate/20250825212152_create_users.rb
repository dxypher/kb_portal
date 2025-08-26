class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email
      t.string :password_digest
      t.string :name
      t.datetime :last_sign_in_at

      t.timestamps
    end
    add_index :users, [ :email ], unique: true
  end
end
