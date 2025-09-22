class RenameDocsToDocuments < ActiveRecord::Migration[8.0]
  def change
    rename_table :docs, :documents
  end
end
