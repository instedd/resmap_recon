class Field
  def initialize(collection, code)
    @collection = collection
    @code = code
  end

  attr_reader :collection
  attr_reader :code
  delegate :api, to: :collection

  def uniq_values
    collection.sites.map { |site| site['properties'][code] }.uniq
  end

  def id
    # HACK
    return 3417 if code == 'kind' && collection.id == 927

    return 3422 if code == 'kind' && collection.id == 928
    return 3423 if code == 'type' && collection.id == 929
  end

  def metadata
    @metadata ||= api.json("/collections/#{collection.id}/fields/#{id}")
  end

  def hierarchy
    metadata['config']['hierarchy']
  end
end
