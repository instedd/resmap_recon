class ResmapApi
  extend Memoist
  # RestClient.log = 'stdout'

  def initialize
    @auth = {
      :username => Settings.resource_map.username,
      :password => Settings.resource_map.password
    }
  end

  def collections
    CollectionRelation.new(self)
  end
  memoize :collections

  def url(url, query = nil)
    "http://#{Settings.resource_map.host}/#{url}#{('?' + query.to_query) unless query.nil?}"
  end

  def get(url, query = {})
    process_response(execute(:get, url, query, nil))
  end

  def post(url, body = {})
    process_response(execute(:post, url, nil, body))
  end

  def put(url, body = {})
    process_response(execute(:put, url, nil, body))
  end

  def delete(url)
    process_response(execute(:delete, url, nil, nil))
  end

  def json(url, query = {})
    JSON.parse get("#{url}.json", query)
  end

  def json_post(url, query = {})
    JSON.parse post("#{url}.json", query)
  end

  protected

  def execute(method, url, query, payload)
    options = {
      :user => @auth[:username],
      :password => @auth[:password],

      :method => method,
      :url => self.url(url, query)
    }

    options[:payload] = payload if payload

    RestClient::Request.execute(options)
  end

  def process_response(response)
    response.body
  end
end
