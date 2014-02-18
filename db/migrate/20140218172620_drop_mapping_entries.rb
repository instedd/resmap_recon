class DropMappingEntries < ActiveRecord::Migration
  def up
    drop_table :mapping_entries
  end

  def down
    create_table :mapping_entries do |t|
      t.integer :source_list_id
      t.string :source_property
      t.string :source_value
      t.string :target_value

      t.timestamps
    end

    add_index :mapping_entries, [:source_list_id, :source_property, :source_value], :unique => true, :name => 'by_source_value'
    add_index :mapping_entries, [:source_list_id, :source_property, :target_value], :name => 'by_target_value'
  end
end
