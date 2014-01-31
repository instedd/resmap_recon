class CreateSiteMappings < ActiveRecord::Migration
  def change
    create_table :site_mappings do |t|
      t.integer :source_list_id
      t.string :site_id
      t.string :name
      t.string :mfl_hierarchy
      t.string :mfl_site_id

      t.timestamps
    end
  end
end
