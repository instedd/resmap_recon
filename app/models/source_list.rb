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
      res[e.source_value] = e.target_value
    end

    res.tap do |m|
      source_values.each do |v|
        m[v] = nil unless m.has_key?(v)
      end
    end
  end

  def update_mapping_entry!(entry_params)
    entry = self.mapping_entries.find_or_initialize_by_source_property_and_source_value(entry_params[:source_property], entry_params[:source_value])
    entry.target_value = entry_params[:target_value]
    entry.save!
  end

  def source_values
    as_collection.field(mapping_property).uniq_values
  end

end
