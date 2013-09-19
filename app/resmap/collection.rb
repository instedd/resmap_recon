class Collection

  def initialize(id)
    @id = id
    @api = ResmapApi.new
  end

  def details
    @details ||= @api.json("collections/#{id}")
  end

  attr_reader :id

  def name
    details['name']
  end

  def show_url
    @api.url("collections?collection_id=#{id}")
  end
end
