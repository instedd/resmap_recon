class Site

  def initialize(collection, id_or_hash)
    @collection = collection

    if id_or_hash.is_a?(Fixnum)
      @id = id_or_hash
      @data = nil
    else
      @id = id_or_hash['id']
      @data = id_or_hash
    end
  end

  attr_reader :collection
  attr_reader :id

  delegate :api, to: :collection

  def to_hash
    #TODO fetch if only id is available.
    @data
  end

  def update_property(code, value)
    api.post("sites/#{id}/update_property", {
      es_code: collection.field_by_code(code).id,
      value: value
      })
  end

  def update_properties(hash)
    hash.delete :createdAt
    hash.delete :updatedAt
    p = {}
    hash[:properties].each do |k,v|
      p[collection.field_by_code(k).id] = v
    end
    hash[:properties] = p
    api.post("collections/#{collection.id}/sites/#{id}/partial_update.json", {site: hash.to_json})
  end
end
