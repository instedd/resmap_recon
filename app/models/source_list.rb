class SourceList < ActiveRecord::Base
  extend Memoist

  belongs_to :project
  attr_accessible :collection_id, :config
  serialize :config, Hash
  has_many :mapping_entries

  delegate :name, to: :as_collection

  delegate :app_layer_name, :app_seen_field_name, :app_master_site_id, to: :project

  before_create :prepare

  def as_collection
    AppContext.resmap_api.collections.find(collection_id)
  end
  memoize :as_collection

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
    return {} if mapping_property_id.nil?
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
    layer = as_collection.find_or_create_layer_by_name(app_layer_name)

    layer.ensure_fields [
      { name: app_seen_field_name, kind: 'yes_no', config: { auto_reset: true } },
      { name: app_master_site_id, kind: 'numeric' }
    ]

    true
  end

  def pending_changes(node_id)
    values = mapping_entries
      .with_property(mapping_property_id)
      .with_target(node_id)
      .pluck(:source_value)

    res = []

    unless values.empty?
      res.concat(as_collection.sites
        .where(
          app_seen_field_name => false,
          mapping_property.code => values)
        .map { |s| site_to_hash(s) })
    end

    res
  end

  def sites_not_curated
    as_collection.sites.where(app_master_site_id => '=')
  end

  def unmapped_sites_csv
    collection = as_collection
    properties = collection.fields.select{|f| !f.name.starts_with?("_")}
    remaining_fields = ['id', 'name', 'lat', 'long']
    csv_string = CSV.generate do |csv|
      csv << remaining_fields + properties.map(&:name)
      sites_not_curated.each do |site|
        data = site.data
        row = []
        remaining_fields.each do |code|
          row << data[code]
        end
        properties.map(&:code).each do |prop|
          row << data['properties'][prop]
        end
        csv << row
      end
    end
    csv_string
  end

  def dismiss_site(site_id)
    as_collection
      .sites.find(site_id)
      .update_property(app_seen_field_name, true)
  end

  def consolidate_with(site_id, master_site_id)
    site = as_collection.sites.find(site_id)

    site.update_property(app_master_site_id, master_site_id)
    site.update_property(app_seen_field_name, true)
  end

  def consolidated_with(master_site_id)
    as_collection.sites
      .where(app_master_site_id => master_site_id)
      .map { |s| site_to_hash(s) }
  end

  def site_to_hash(site)
    h = Hash[site.to_hash]
    h['source_list'] = {
      id: id,
      name: name
    }
    #TODO create properties for seen/master_site_id
    #     and hide "private" fields

    h
  end

  def curation_progress
    if as_collection.sites.all.count != 0
      "#{100 - (sites_not_curated.count * 100 / as_collection.sites.all.count)}%"
    else
      "0%"
    end
  end
end
