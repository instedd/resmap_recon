class Collection

  def initialize(id)
    @api = ResmapApi.new
    @id = id
  end

  def reload
    @details = nil
    @name = nil
    @fields = nil
    @layer_names = nil
  end

  def details
    @details ||= @api.json("api/collections/#{id}", page: 'all')
  end

  attr_reader :api
  attr_reader :id

  def name
    @name ||= @api.json("collections/#{id}")['name']
  end

  def sites
    details['sites']
  end

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
end
