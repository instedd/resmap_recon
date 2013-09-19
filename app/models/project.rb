class Project < ActiveRecord::Base
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
  config_property :source_collection_ids

  def master_collection
    Collection.new(master_collection_id)
  end

  def source_collections
    source_collection_ids.map { |id| Collection.new(id) }
  end
end
