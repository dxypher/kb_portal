class CreateMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :memberships do |t|
      t.integer :team_id
      t.integer :user_id
      t.string :role

      t.timestamps
    end

    add_index :memberships, [ :team_id, :user_id ], unique: true
  end
end
