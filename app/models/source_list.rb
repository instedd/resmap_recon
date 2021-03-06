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

  def not_curated_site_ids
    site_mappings.not_curated.pluck(:site_id)
  end

  def sites_with_mappings
    mappings = site_mappings.inject({}) do |mapping_dict, mapping|
      mapping_dict[mapping.site_id] = {"mapping" => mapping, "site" => nil}
      mapping_dict
    end

    sites = find_sites_from_ids(mappings.keys)

    sites.each(true) do |s|
      mappings[s.id.to_s]["site"] = s
    end

    mappings
  end

  def csv_serialize(sites, extra_columns)
    collection = as_collection
    properties = collection.fields.select{|f| !f.name.starts_with?("_")}
    remaining_fields = ['name', 'lat', 'long']

    csv_string = CSV.generate do |csv|
      csv << remaining_fields + properties.map(&:name) + extra_columns

      sites.each do |site_projection|
        site, extras = yield(site_projection)

        data = site.data
        row = []

        remaining_fields.each do |code|
          row << data[code]
        end

        properties.map(&:code).each do |prop|
          row << data['properties'][prop]
        end

        if extras
          extras.each do |extra|
            row << extra
          end
        end

        csv << row
      end
    end
    csv_string
  end

  def sites_with_mfl_id_csv
    csv_serialize sites_with_mappings, ['mfl_id'] do |site_projection|
      [site_projection[1]["site"], [site_projection[1]["mapping"].mfl_site_id]]
    end
  end

  def unmapped_sites_csv
    csv_serialize sites_pending.all, [] do |site_projection|
      [site_projection, nil]
    end
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

  # returns array of codes of properties that are shared among
  # this source_list's collection and the master collection
  def common_properties_with_master
    (self.as_collection.fields.map &:code) & (self.project.master_collection.fields.map &:code)
  end

  def properties_not_in_master
    (self.as_collection.fields.map &:code) - (self.project.master_collection.fields.map &:code)
  end

  def consolidated_with(master_site_id)
    ids = site_mappings.where('mfl_site_id = ?', master_site_id).pluck(:site_id)

    consolidated_sites = []
    find_sites_from_ids(ids).each(true) do |s|
      consolidated_sites.push(site_to_hash(s))
    end

    consolidated_sites
  end

  def site_to_hash(site)
    h = Hash[site.to_hash]
    h['source_list'] = {
      id: id,
      name: name
    }
    h['collection_id'] = collection_id
    # TODO: this generates an N+1 query when called from pending_changes and consolidated_with
    mapping = site_mappings.find_by_site_id(site.id)
    h['pending'] = mapping.try(:pending?)
    h['mfl_hierarchy'] = mapping.mfl_hierarchy
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
    mappings = []

    as_collection.sites.where({}).page_size(1000).each(true) do |s|
      mappings.push(SiteMapping.new site_id: s.id, name: s.name, source_list_id: id)
    end

    SiteMapping.import mappings
  end

  def process_automapping(chosen_fields)
    error_tree = []
    count = 0
    successful_mappings = []

    sites_pending.each(true) do |site|
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
        else
          missed = true
          error_branch << value
          new_error_branch = array_to_tree_branch(error_branch, hier_in_level)
          error_tree = merge_into(error_tree, new_error_branch)
          break
        end
      end
      unless missed
        successful_mappings << {id: site.id, mfl_id: current_mfl_id}
        count += 1
      end
    end

    if count == sites_pending.total_count
      successful_mappings.each do |mapping|
        site_mapping = SiteMapping.where(source_list_id: id, site_id: mapping[:id]).first_or_initialize
        site_mapping.mfl_hierarchy = mapping[:mfl_id]
        site_mapping.save!
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
      EmptySiteApiResult.new as_collection
    else
      as_collection.sites.where(site_id: ids).page_size(1000)
    end
  end

  # Hack, I know...
  class EmptySiteApiResult < ResourceMap::SiteResult
    def initialize(collection)
      super collection, {}
    end

    def each(seamless_paging=false)
      [].each do |e|
        yield e
      end
    end
  end
end
