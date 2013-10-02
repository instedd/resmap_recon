class Collection
  extend Memoist

  def initialize(id)
    @api = ResmapApi.new
    @id = id
  end

  def reload
    @fields = nil
    @layer_names = nil
    self.flush_cache
  end

  def details
    api.json("api/collections/#{id}", page: 'all')
  end
  memoize :details

  attr_reader :api
  attr_reader :id

  def name
    api.json("collections/#{id}")['name']
  end
  memoize :name

  def sites
    SiteRelation.new(self)
  end
  memoize :sites

  def fields
    @fields ||= begin
      fields_mapping = @api.json("collections/#{id}/fields/mapping")
      fields_mapping.map { |fm| Field.new(self, fm) }
    end
  end

  def layers
    @layers ||= @api.json("collections/#{id}/layers").map { |l| Layer.new(self, l) }
  end

  def find_or_create_layer_by_name(name)
    res = layers.detect { |l| l.name == name }

    if res.nil?
      data = { layer: { name: name, ord: layers.length + 1 } }
      api.post("collections/#{id}/layers", data)
      @layers = nil
      res = layers.detect { |l| l.name == name }
    end

    res
  end

  def field_by_id(id)
    fields.detect { |f| f.id == id }
  end

  def field_by_code(code)
    fields.detect { |f| f.code == code }
  end

  def show_url
    @api.url("collections?collection_id=#{id}")
  end

  def import_wizard_url
    @api.url("collections/#{id}/import_wizard")
  end

  class SiteRelation
    attr_reader :collection
    delegate :api, to: :collection

    def initialize(collection)
      @collection = collection
    end

    def all
      collection.details['sites']
    end

    def where(attrs)
      sites_data = api.json("api/collections/#{collection.id}", {page: 'all'}.merge(attrs))['sites']
      sites_data.map { |site_hash| Site.new(collection, site_hash) }
    end

    def find(site_id)
      Site.new(collection, site_id)
    end
  end
end
