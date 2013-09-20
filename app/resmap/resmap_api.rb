class ResmapApi
  include HTTParty

  def initialize
    @auth = {
      :username => Settings.resource_map.username,
      :password => Settings.resource_map.password
    }
  end

  def url(url)
    "http://#{Settings.resource_map.host}/#{url}"
  end

  def get(url, query = {})
    options = {
      :basic_auth => @auth
    }
    options[:query] = query unless query.nil?
    res = self.class.get(url("#{url}"), options)
    res.body
  end

  def json(url, query = {})
    JSON.parse get("#{url}.json", query)
  end
end
