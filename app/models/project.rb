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

  def no_source_list_was_promoted?
    self.promoted_source_list_id.nil?
  end

  def master_collection
    AppContext.resmap_api.collections.find(master_collection_id)
  end
  memoize :master_collection

  def target_field
    master_collection.field_by_id(master_collection_target_field_id)
  end

  def source_collections
    source_lists.map &:as_collection
  end

  def source_collection_by_id(id)
    source_collections.detect { |c| c.id == id }
  end

  def pending_changes(node_id, search, next_page_hash = {})
    node_ids = node_id ? search_node_ids_under(node_id) : nil

    urls = {}
    src_lists = source_lists
    if next_page_hash.present?
      src_lists = src_lists.select { |s| next_page_hash.keys.include?(s.id.to_s) }
    end
    res = {sites: [], headers: {}}
    src_lists.each do |s|
      source_list_data = s.pending_changes(node_ids, search, next_page_hash[s.id.to_s])
      res[:sites] << source_list_data[:sites]
      res[:headers] = res[:headers].merge(source_list_data[:headers]) if source_list_data[:headers].present?
      urls[s.id] = source_list_data[:next_page_url] if source_list_data[:next_page_url].present?
    end
    res[:next_page_hash] = urls if urls.keys.length > 0
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

end
