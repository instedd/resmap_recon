class SourceList < ActiveRecord::Base
  extend Memoist

  belongs_to :project
  attr_accessible :collection_id, :config, :project
  serialize :config, Hash
  has_many :mapping_entries

  delegate :app_layer_name, :app_seen_field_name, :app_master_site_id, to: :project

  before_create :prepare

  def as_collection
    AppContext.resmap_api.collections.find(collection_id)
  end
  memoize :as_collection

  def name
    as_collection.name rescue "error col-id:#{collection_id}"
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

  def pending_changes(node_id, next_page_url = nil)
    res = {sites: []}
    if next_page_url.blank?
      values = mapping_entries
        .with_property(mapping_property_id)
        .with_target(node_id)
        .pluck(:source_value)

      unless values.empty?
        result = as_collection.sites
          .where(
            app_seen_field_name => false,
            mapping_property.code => values)
          .page_size(10).page(1)
      end
    else
      result = as_collection.sites.from_url(next_page_url)
    end
    unless result.nil?
      result.each do |s|
        res[:sites] << site_to_hash(s)
      end
      res[:next_page_url] = result.next_page_url if result.next_page_url
    end

    res
  end

  def sites_pending
    as_collection.sites.where(app_seen_field_name => false)
  end

  def sites_pending_count
    sites_pending.total_count
  end

  def sites_to_promote
    values = mapping_entries
      .with_property(mapping_property_id)
      .pluck(:source_value)

    sites_pending.where(app_master_site_id => '=', mapping_property.code => values)
  end

  def sites_not_curated
    as_collection.sites.where(app_master_site_id => '=')
  end

  def unmapped_sites_csv
    collection = as_collection
    properties = collection.fields.select{|f| !f.name.starts_with?("_")}
    remaining_fields = ['name', 'lat', 'long']
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


  def promote_to_master(site_id)
    if project.promoted_source_list_id != self.id
      project.promoted_source_list_id = self.id
      project.save!
    end

    # grab site info
    s = self.as_collection.sites.find(site_id)

    # TODO raise exception if the site is already consolidated.

    # build master site info:
    #  * name/lat/long
    #  * common_properties_with_master
    #  * mapped geo-political hierarchy
    name = s.data['name']
    lat = s.data['lat']
    long = s.data['long']

    mapped_source_value = s.data['properties'][mapping_property.code]
    mapped_target_value = self.mapping_entries
        .with_property(mapping_property_id)
        .with_source(mapped_source_value)
        .pluck(:target_value)
        .first

    properties = s.data['properties'].select{|k,v| common_properties_with_master.include?(k.to_s)}
    properties[project.target_field.code] = mapped_target_value
    # create master site
    new_site = project.master_collection.sites.create(name:name)
    new_site.update_properties(lat: lat, long: long, properties: properties)

    # mark as consolidated
    self.consolidate_with(site_id, new_site.id)

    true
  end

  # returns array of codes of properties that are shared among
  # this source_list's collection and the master collection
  def common_properties_with_master
    (self.as_collection.fields.map &:code) & (self.project.master_collection.fields.map &:code)
  end

  def can_promote?
    project.no_source_list_was_promoted? || project.promoted_source_list_id == self.id
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
    h['collection_id'] = collection_id
    #TODO create properties for seen/master_site_id
    #     and hide "private" fields

    h
  end

  def curation_progress
    total_count = as_collection.sites.count
    if total_count != 0
      100 - (sites_pending_count * 100 / total_count)
    else
      0
    end
  end

  def classification_progress
    total = 0
    classifed = 0
    mapping.each do |m|
      total += m[:source_count]
      classifed += m[:source_count] if m[:target_value]
    end

    if total != 0
      classifed * 100 / total
    else
      0
    end
  end

  def mapped_hierarchy_counts
    unseen_changes_counts = mapping_property.uniq_values({project.app_seen_field_name => false}) if mapping_property
    mapped_counts = {}
    mapped_counts.default = 0
    mapping.each do |prop|
      if !prop[:target_value].nil? && unseen_changes_counts.keys.include?(prop[:source_value])
        mapped_counts[prop[:target_value]] += unseen_changes_counts[prop[:source_value]]
      end
    end
    mapped_counts
  end

end
