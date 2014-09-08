class AddProjectIdToSiteMappings < ActiveRecord::Migration
  def change
    add_column :site_mappings, :project_id, :integer
    add_index :site_mappings, :project_id    
  end
end
