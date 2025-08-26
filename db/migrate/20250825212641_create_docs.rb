class CreateDocs < ActiveRecord::Migration[8.0]
  def change
    create_table :docs do |t|
      t.integer :team_id
      t.string :title
      t.string :source_type
      t.text :body
      t.integer :tokens
      t.string :visibility

      t.timestamps
    end
    add_index :docs, [ :team_id, :title ]
  end
end
