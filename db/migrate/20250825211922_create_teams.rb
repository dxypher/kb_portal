class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams do |t|
      t.string :name
      t.string :plan
      t.integer :quota_daily
      t.datetime :quota_reset_at

      t.timestamps
    end
  end
end
