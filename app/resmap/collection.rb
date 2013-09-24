class Collection

  def initialize(id)
    @api = ResmapApi.new
    @id = id
  end

  def details
    @details ||= @api.json("/api/collections/#{id}", page: 'all')
  end

  attr_reader :api
  attr_reader :id

  def name
    @name ||= @api.json("/collections/#{id}")['name']
  end

  def sites
    details['sites']
  end

  def fields
    @fields ||= begin
      fields_mapping = @api.json("/collections/#{id}/fields/mapping")
      fields_mapping.map { |fm| Field.new(self, fm) }
    end
  end

  def field_by_id(id)
    fields.detect { |f| f.id == id }
  end

  def show_url
    @api.url("collections?collection_id=#{id}")
  end

  def import_wizard_url
    @api.url("collections/#{id}/import_wizard")
  end
end
