class SiteMapping < ActiveRecord::Base
  attr_accessible :mfl_hierarchy, :mfl_site_id, :name, :site_id, :source_list_id

  belongs_to :source_list

  validates_presence_of :source_list_id, :name

  scope :pending, where('mfl_hierarchy IS NULL AND dismissed = FALSE')
  scope :not_curated, where('mfl_hierarchy IS NOT NULL AND mfl_site_id IS NULL AND dismissed = FALSE')
  scope :curated, where('mfl_site_id IS NOT NULL')

  def pending?
    mfl_hierarchy.nil? && !dismissed
  end
end
