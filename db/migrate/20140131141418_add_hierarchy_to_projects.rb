class AddHierarchyToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :hierarchy, :binary
  end
end
