class CreateSummaries < ActiveRecord::Migration[8.0]
  def change
    create_table :summaries do |t|
      t.references :doc, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.text :content
      t.string :llm_name
      t.integer :tokens_in
      t.integer :tokens_out
      t.integer :latency_ms

      t.timestamps
    end
  end
end
