class AddDismissedToSiteMapping < ActiveRecord::Migration
  def change
    add_column :site_mappings, :dismissed, :boolean, default: false
  end
end
