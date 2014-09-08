class UpdateProjectIdForSiteMappings < ActiveRecord::Migration
  class SourceList < ActiveRecord::Base
    belongs_to :project
  end

  class SiteMapping < ActiveRecord::Base
    belongs_to :source_list
  end
  
  def up
    ActiveRecord::Base.transaction do
      SiteMapping.includes(:source_list).find_each do |m|
        m.project_id = m.source_list.project_id
        m.save!
      end
    end
  end

  def down
    ActiveRecord::Base.transaction do
      SiteMapping.update_all(:project_id => nil)
    end
  end
end
