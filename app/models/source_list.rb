class SourceList < ActiveRecord::Base
  belongs_to :project
  attr_accessible :collection_id, :config
  serialize :config, Hash

  delegate :name, to: :as_collection

  def as_collection
    Collection.new collection_id
  end

  def self.config_property(name)
    define_method(name) {
      config["#{name}"]
    }
    define_method("#{name}=".to_sym) { |value|
      config["#{name}"] = value
    }
  end

  config_property :mapping_property

  def mapping
    config['mapping'] ||= {}

    config['mapping'].tap do |m|
      source_values.each do |v|
        puts m, v
        m[v] = nil unless m.has_key?(v)
      end
    end
  end

  def source_values
    as_collection.uniq_values(mapping_property)
  end

end
