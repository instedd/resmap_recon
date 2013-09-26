class Site

  def initialize(collection, id)
    @collection = collection
    @id = id
  end

  attr_reader :collection
  attr_reader :id

  delegate :api, to: :collection

  def update_property(code, value)
    api.post("sites/#{id}/update_property", {
      es_code: collection.field_by_code(code).id,
      value: value
      })
  end
end
