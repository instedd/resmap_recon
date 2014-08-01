class AddSiteIdAndSourceListIdIndexToSiteMappings < ActiveRecord::Migration
  def change
  	add_index :site_mappings, [:source_list_id, :site_id]
  end
end
