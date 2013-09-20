class MappingEntry < ActiveRecord::Base
  belongs_to :source_list

  attr_accessible :source_property, :source_value, :target_value

  scope :with_property, lambda { |prop| where(:source_property, prop) }
end
