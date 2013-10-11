class CreateUserProjectMemberships < ActiveRecord::Migration
  def change
    create_table :user_project_memberships do |t|
      t.references :user
      t.references :project

      t.timestamps
    end
    add_index :user_project_memberships, :user_id
    add_index :user_project_memberships, :project_id
  end
end
