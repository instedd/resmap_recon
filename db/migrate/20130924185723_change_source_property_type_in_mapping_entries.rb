class ChangeSourcePropertyTypeInMappingEntries < ActiveRecord::Migration
  def up
    change_column :mapping_entries, :source_property, :integer
  end

  def down
    change_column :mapping_entries, :source_property, :string
  end
end
