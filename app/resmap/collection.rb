class Collection

  def initialize(id)
    @api = ResmapApi.new
    @id = id
  end

  def details
    @details ||= @api.json("api/collections/#{id}", page: 'all')
  end

  attr_reader :api
  attr_reader :id

  def name
    details['name']
  end

  def sites
    details['sites']
  end

  def field(code)
    Field.new(self, code)
  end

  def show_url
    @api.url("collections?collection_id=#{id}")
  end

  def import_wizard_url
    @api.url("collections/#{id}/import_wizard")
  end
end
