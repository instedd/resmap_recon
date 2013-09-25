class Project < ActiveRecord::Base
  has_many :source_lists
  attr_accessible :config, :name
  serialize :config, Hash

  after_save :prepare_source_lists

  def self.config_property(name)
    define_method(name) {
      config["#{name}"]
    }
    define_method("#{name}=".to_sym) { |value|
      config["#{name}"] = value
    }
  end

  config_property :master_collection_id
  config_property :master_collection_target_field_id

  def master_collection
    @master_collection ||= Collection.new(master_collection_id)
  end

  def target_field
    master_collection.field_by_id(master_collection_target_field_id)
  end

  def source_collections
    source_lists.map &:as_collection
  end

  def source_collection_by_id(id)
    source_collections.detect { |c| c.id == id }
  end

  def pending_changes(node_id)
    res = []
    source_lists.each do |s|
      sites = s.pending_changes(node_id)
      res << sites
    end

    res.flatten
  end

  def dismiss_source_site(source_list_id, site_id)
    source_lists.find(source_list_id).dismiss_site(site_id)
  end

  protected

  def prepare_source_lists
    source_lists.each &:prepare
  end
end
