class SiteMapping < ActiveRecord::Base
  attr_accessible :mfl_hierarchy, :mfl_site_id, :name, :site_id, :source_list_id

  belongs_to :source_list

  validates_presence_of :source_list_id, :name
end
