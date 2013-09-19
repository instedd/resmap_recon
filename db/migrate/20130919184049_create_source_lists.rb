class CreateSourceLists < ActiveRecord::Migration
  def change
    create_table :source_lists do |t|
      t.integer :project_id
      t.integer :collection_id
      t.text :mappings

      t.timestamps
    end
  end
end
