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

  def get(api_url)
    options = { :basic_auth => @auth }
    res = self.class.get(url("api/#{api_url}"), options)
    res.body
  end

  def json(api_url)
    JSON.parse get("#{api_url}.json")
  end
end
