class Project < ActiveRecord::Base
  extend Memoist
  include Configurable

  has_many :user_project_memberships
  has_many :users, through: :user_project_memberships,
    before_add: :ensure_resmap_user_membership,
    before_remove: :revoke_resmap_user_membership

  has_many :source_lists,
    before_add: :ensure_resmap_memberships

  attr_accessible :config, :name
  validates :name, :presence => true

  default_scope order('name')

  config_property :master_collection_id
  config_property :master_collection_target_field_id
  config_property :promoted_source_list_id

  serialize :hierarchy, MarshalZipSerializable

  class NoHierarchyDefinedError < StandardError; end

  def no_source_list_was_promoted?
    self.promoted_source_list_id.nil?
  end

  def master_collection
    AppContext.resmap_api.collections.find(master_collection_id)
  end
  memoize :master_collection

  def target_field_defined?
    begin
      target_field
      true
    rescue NoHierarchyDefinedError
      false
    end
  end

  def target_field
    if master_collection_target_field_id
      master_collection.field_by_id(master_collection_target_field_id)
    else
      pull_hierarchy_field || raise(NoHierarchyDefinedError)
    end     
  end

  def required_hierarchy
    unless self.hierarchy    
      pull_hierarchy_field || raise(NoHierarchyDefinedError)
    end

    self.hierarchy
  end

  def source_collections
    source_lists.map &:as_collection
  end

  def source_collection_by_id(id)
    source_collections.detect { |c| c.id == id }
  end

  def pending_changes(source_list_id, node_id, search, page)
    node_ids = node_id ? search_node_ids_under(node_id) : nil

    #TODO: receive which source list to use from client
    l = source_lists.find(source_list_id) || []

    res = l.pending_changes(node_ids, search, page)

    if res[:headers].present?
      res[:headers_array] = []

      res[:headers].each_pair do |code, name|
        res[:headers_array].push({ code: code, name: name })
      end

      res[:headers] = res.delete(:headers_array)
    else
      res[:headers] = []
    end

    res
  end

  def search_node_ids_under(node_id, nodes = hierarchy)
    nodes.each do |node|
      if node["id"] == node_id
        return gather_children_ids(node)
      elsif node["sub"]
        result = search_node_ids_under(node_id, node["sub"])
        return result if result
      end
    end
    nil
  end

  def gather_children_ids(node, ids = [])
    ids << node["id"]
    if node["sub"]
      node["sub"].each do |sub|
        gather_children_ids sub, ids
      end
    end
    ids
  end

  def consolidated_with(master_site_id)
    source_lists.flat_map { |s| s.consolidated_with(master_site_id) }
  end

  def dismiss_source_site(source_list_id, site_id)
    source_lists.find(source_list_id).dismiss_site(site_id)
  end

  def revoke_resmap_user_membership(user)
    email = user.email

    master_collection.members.find_or_create_by_email(email).delete!
    source_lists.each do |s|
      s.as_collection.members.find_or_create_by_email(email).delete!
    end
  end

  def ensure_resmap_user_membership(user)
    ensure_membership_permissions user: user
  end

  def ensure_resmap_memberships(source_list)
    ensure_membership_permissions source_list: source_list
  end

  def ensure_membership_permissions(options)
    users_to_add = options.has_key?(:user) ? [options[:user]] : self.users
    source_lists_to_add = options.has_key?(:source_list) ? [options[:source_list]] : self.source_lists

    users_to_add.each do |user|
      self.master_collection.members.find_or_create_by_email(user.email).set_admin!
      source_lists_to_add.each do |s|
        s.as_collection.members.find_or_create_by_email(user.email).set_admin!
      end
    end
  end

  def app_suffix
    "#{Settings.system_id}_#{id}"
  end

  def app_layer_name
    "_recon_tool_#{app_suffix}_"
  end

  def app_seen_field_name
    "_seen_#{app_suffix}_"
  end

  def app_master_site_id
    "_master_site_id_#{app_suffix}_"
  end

  private

  def pull_hierarchy_field
    master_collection.reload
    hierarchy_field = master_collection.field_by_code('admin_division')

    if hierarchy_field && hierarchy_field.id
      self.master_collection_target_field_id = hierarchy_field.id
      self.hierarchy = YAML.load(hierarchy_field.hierarchy.to_yaml)
      self.save!
      hierarchy_field
    else
      nil
    end
  end
end
