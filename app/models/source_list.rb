class SourceList < ActiveRecord::Base
  belongs_to :project
  attr_accessible :collection_id, :config
  serialize :config, Hash
  has_many :mapping_entries

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
    entries = mapping_entries.with_property(mapping_property).all

    res = {}

    entries.each do |e|
      res[e.source_value] = [e.target_value]
    end

    res.tap do |m|
      source_values.each do |v|
        puts m, v
        m[v] = nil unless m.has_key?(v)
      end
    end
  end

  def source_values
    as_collection.field(mapping_property).uniq_values
  end

end
