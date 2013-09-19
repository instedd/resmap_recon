class Collection

  def initialize(id)
    @id = id
    @api = ResmapApi.new
  end

  def details
    @details ||= @api.json("collections/#{id}", page: 'all')
  end

  attr_reader :id

  def name
    details['name']
  end

  def sites
    details['sites']
  end

  def uniq_values(field)
    sites.map { |site| site['properties'][field] }.uniq
  end

  def show_url
    @api.url("collections?collection_id=#{id}")
  end

  def import_wizard_url
    @api.url("collections/#{id}/import_wizard")
  end
end
