class SourceList < ActiveRecord::Base
  belongs_to :project
  attr_accessible :collection_id, :config
  serialize :config, Hash
  has_many :mapping_entries

  delegate :name, to: :as_collection

  def as_collection
    @collection ||= Collection.new(collection_id)
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
      res[e.source_value] = {
        source_value: e.source_value,
        source_count: 0,
        target_value: e.target_value
      }
    end

    source_values.each do |k,v|
      if !res.has_key?(k)
        res[k] = {
          source_value: k,
          source_count: v,
          target_value: nil
        }
      else
        res[k][:source_count] = v
      end
    end

    # TODO: could clean unused mapping_entries

    res.values
  end

  def update_mapping_entry!(entry_params)
    entry = self.mapping_entries.find_or_initialize_by_source_property_and_source_value(entry_params[:source_property], entry_params[:source_value])
    entry.target_value = entry_params[:target_value]
    entry.save!
  end

  def source_values
    mapping_property.uniq_values
  end

  def prepare
    layer = as_collection.find_or_create_layer_by_name(SourceList.app_layer_name)

    layer.ensure_fields [
      { name: SourceList.app_seen_field_name, kind: 'yes_no', config: { auto_reset: true } },
      { name: SourceList.app_master_site_id, kind: 'numeric' }
    ]
  end

  def pending_changes(node_id)
    values = mapping_entries
      .with_property(mapping_property_id)
      .with_target(node_id)
      .pluck(:source_value)

    res = []

    unless values.empty?
      as_collection.sites_where(
        SourceList.app_seen_field_name => false,
        mapping_property.code => values).each do |site|
        site['source_list'] = { id: id, name: name }
        res << site
      end
    end

    res
  end

  def dismiss_site(site_id)
    as_collection
      .sites_find(site_id)
      .update_property(SourceList.app_seen_field_name, true)
  end

  def consolidate_with(site_id, master_site_id)
    site = as_collection.sites_find(site_id)

    site.update_property(SourceList.app_master_site_id, master_site_id)
    site.update_property(SourceList.app_seen_field_name, true)
  end

  protected

  def self.app_layer_name
    "_recon_tool_#{Settings.system_id}_"
  end

  def self.app_seen_field_name
    "_seen_#{Settings.system_id}_"
  end

  def self.app_master_site_id
    "_master_site_id_#{Settings.system_id}_"
  end
end
