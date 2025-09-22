class RenameDocIdToDocumentIdInSummaries < ActiveRecord::Migration[8.0]
  def up
    # Drop the old FK and index tied to doc_id
    remove_foreign_key :summaries, column: :doc_id
    remove_index :summaries, :doc_id if index_exists?(:summaries, :doc_id)

    # Rename the column
    rename_column :summaries, :doc_id, :document_id

    # Recreate index and FK on the new column
    add_index :summaries, :document_id
    add_foreign_key :summaries, :documents, column: :document_id
  end

  def down
    remove_foreign_key :summaries, column: :document_id
    remove_index :summaries, :document_id if index_exists?(:summaries, :document_id)
    rename_column :summaries, :document_id, :doc_id
    add_index :summaries, :doc_id
    add_foreign_key :summaries, :documents, column: :doc_id
  end
end
