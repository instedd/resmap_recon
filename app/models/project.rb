class Project < ActiveRecord::Base
  has_many :source_lists
  attr_accessible :config, :name
  serialize :config, Hash


  def self.config_property(name)
    define_method(name) {
      config["#{name}"]
    }
    define_method("#{name}=".to_sym) { |value|
      config["#{name}"] = value
    }
  end

  config_property :master_collection_id

  def master_collection
    Collection.new(master_collection_id)
  end

  def source_collections
    source_lists.map &:as_collection
  end

  def source_collection_by_id(id)
    source_collections.detect { |c| c.id == id }
  end
end
