class FixSourceListsConfigName < ActiveRecord::Migration
  def change
    rename_column :source_lists, :mappings, :config
  end
end
