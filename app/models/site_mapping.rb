class SiteMapping < ActiveRecord::Base
  attr_accessible :mfl_hierarchy, :mfl_site_id, :name, :site_id, :source_list_id

  belongs_to :source_list
  belongs_to :project

  validates_presence_of :name, :project_id

  scope :pending, where('mfl_hierarchy IS NULL AND dismissed = FALSE')
  scope :not_curated, where('mfl_hierarchy IS NOT NULL AND mfl_site_id IS NULL AND dismissed = FALSE')
  scope :curated, where('mfl_site_id IS NOT NULL')
  scope :non_source_list, where('source_list_id IS NULL')

  before_validation :set_project_from_source_list

  def pending?
    mfl_hierarchy.nil? && !dismissed
  end

  private

  def set_project_from_source_list
    if source_list && source_list.project
      self.project = source_list.project
    end
  end
end
