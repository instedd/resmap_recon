class SourceList < ActiveRecord::Base
  extend Memoist
  include Configurable

  belongs_to :project
  attr_accessible :collection_id, :config, :project
  has_many :site_mappings, dependent: :delete_all

  delegate :app_layer_name, :app_seen_field_name, :app_master_site_id, to: :project

  def as_collection
    AppContext.resmap_api.collections.find(collection_id)
  end
  memoize :as_collection

  def name
    as_collection.name rescue "error col-id:#{collection_id}"
  end

  def current_site_mappings
    site_mappings.not_curated
  end

  def pending_changes(node_id, search, page)
    res = {sites: []}
    db_query = site_mappings.not_curated
    db_query = db_query.where(mfl_hierarchy: node_id) if node_id
    pending_ids = db_query.pluck(:site_id).map &:to_i
    unless pending_ids.empty?
      query = {
        site_id: pending_ids,
      }
      query[:search] = search if search

      result = as_collection.sites.where(query).page_size(5).page(page)
    end

    unless result.nil?
      result.each do |s|
        res[:sites] << site_to_hash(s)
      end
      res[:headers] = {}
      as_collection.fields.each{|f| res[:headers][f.code] = f.name}

      res[:current_page] = page
      res[:total_count] = result.total_count
    end

    res
  end

  def sites_pending
    ids = site_mappings.pending.pluck(:site_id)
    find_sites_from_ids(ids)
  end

  def sites_not_curated
    ids = site_mappings.not_curated.pluck(:site_id)
    find_sites_from_ids(ids)
  end

  def unmapped_sites_csv
    collection = as_collection
    properties = collection.fields.select{|f| !f.name.starts_with?("_")}
    remaining_fields = ['name', 'lat', 'long']
    csv_string = CSV.generate do |csv|
      csv << remaining_fields + properties.map(&:name)
      sites_pending.each do |site|
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
    site = site_mappings.find_by_site_id(site_id)
    site.dismissed = true
    site.save!
  end

  def consolidate_with(site_id, master_site_id)
    site = site_mappings.find_by_site_id(site_id)
    site.mfl_site_id = master_site_id
    site.save!
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

    mapped_target_value = site_mappings.find_by_site_id(site_id).mfl_hierarchy

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
    ids = site_mappings.where('mfl_site_id = ?', master_site_id).pluck(:site_id)
    find_sites_from_ids(ids).map { |s| site_to_hash(s) }
  end

  def site_to_hash(site)
    h = Hash[site.to_hash]
    h['source_list'] = {
      id: id,
      name: name
    }
    h['collection_id'] = collection_id
    # TODO: this generates an N+1 query when called from pending_changes and consolidated_with
    h['pending'] = site_mappings.find_by_site_id(site.id).try(:pending?)
    h
  end

  def curation_progress
    total_count = site_mappings.count
    if total_count != 0
      site_mappings.curated.count * 100 / total_count
    else
      0
    end
  end

  def mapping_progress
    total_count = site_mappings.count
    if total_count != 0
      (total_count - site_mappings.pending.count) * 100 / total_count
    else
      0
    end
  end

  def mapped_hierarchy_counts
    Hash[site_mappings.not_curated.select('site_mappings.*, count(id) as sum').group('mfl_hierarchy').map{|e| [e.mfl_hierarchy, e.sum]}]
  end

  def import_sites_from_resource_map
    as_collection.sites.where({}).each do |site|
      site_mappings.create! site_id: site.id, name: site.name
    end
  end

  # def process_automapping(chosen_fields, corrections)
  def process_automapping(chosen_fields)
    error_tree = []
    count = 0

    sites_pending.each do |site|
      hier_in_level = project.hierarchy
      missed = false
      error_branch = []
      current_mfl_id = nil
      chosen_fields.each do |field|
        value = field['kind'] == "Fixed value" ? field['name'] : site.properties[field['id']]
        index = hier_in_level.map{|entry| entry['name']}.index(value)
        if index
          current_mfl_id = hier_in_level[index]['id']
          hier_in_level = hier_in_level[index]['sub']
          error_branch << value
        # elsif corrections[value]
        #   index = hier_in_level.map{|entry| entry['name']}.index(corrections[value])
        #   current_mfl_id = hier_in_level[index]['id']
        #   hier_in_level = hier_in_level[index]['sub']
        #   error_branch << value
        #   new_error_branch = array_to_tree_branch(error_branch, hier_in_level, corrections[value])
        #   error_tree = merge_into(error_tree, new_error_branch)
        else
          missed = true
          error_branch << value
          new_error_branch = array_to_tree_branch(error_branch, hier_in_level)
          error_tree = merge_into(error_tree, new_error_branch)
          break
        end
      end
      unless missed
        mapping = SiteMapping.find_or_initialize_by_site_id(site.id)
        mapping.mfl_hierarchy = current_mfl_id
        mapping.save!
        count += 1
      end
    end
    [error_tree, count]
  end

  private

  def array_to_tree_branch(a, hier_in_level, fixed='')
    tree = {name: a.first, sub: []}
    previous = tree[:sub]
    current = {}
    a[1..-1].each do |el|
      current = {name: el, sub: []}
      previous << current
      previous = current[:sub]
    end
    if fixed.present?
      current.merge!({fixed: fixed})
    else
      current.merge!({options: hier_in_level.map{|entry| entry['name']}})
    end
    tree
  end

  def merge_into(tree, branch)
    branch_to_merge = tree.select{|root| root[:name] == branch[:name]}.first
    if branch_to_merge
      index = tree.index{|root| root[:name] == branch[:name]}
      branch[:sub].each do |child|
        branch_to_merge[:sub] = merge_into(branch_to_merge[:sub], child)
      end
    else
      tree << branch
    end
    tree
  end

  def find_sites_from_ids(ids)
    if ids.empty?
      []
    else
      as_collection.sites.where(site_id: ids, page_size: 1000)
    end
  end

end
