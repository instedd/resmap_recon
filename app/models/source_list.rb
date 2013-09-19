class SourceList < ActiveRecord::Base
  belongs_to :project
  attr_accessible :collection_id, :mappings

  delegate :name, to: :as_collection

  def as_collection
    Collection.new collection_id
  end
end
