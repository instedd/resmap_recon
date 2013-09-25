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

  config_property :mapping_property_id

  def mapping_property
    as_collection.field_by_id(mapping_property_id)
  end

  def mapping
    entries = mapping_entries.with_property(mapping_property_id).all

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
    as_collection.field_by_id(mapping_property_id).uniq_values
  end

  def prepare
    recon_layer_name =
    layer = as_collection.find_or_create_layer_by_name(app_layer_name)

    layer.ensure_fields [
      { name: app_seen_field_name, kind: 'yes_no', config: { auto_reset: true } }
    ]
  end

  protected

  def app_layer_name
    "_recon_tool_#{Settings.system_id}_"
  end

  def app_seen_field_name
    "_seen_#{Settings.system_id}_"
  end
end
