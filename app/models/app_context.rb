class AppContext

  def self.resmap_api=(api)
    Thread.current[:resmap_api] = api
  end

  def self.resmap_api
    Thread.current[:resmap_api]
  end

  def self.resmap_url_to_recon(json_or_url)
    # HACK /rm/ mount of ApiForwarder
    api_mount = "#{Thread.current[:scheme]}://#{Thread.current[:host_with_port]}/rm/"
    api_url = self.resmap_api.url

    json_or_url.gsub(api_url, api_mount)
  end

  def self.setup_url_rewrite_from_request(request)
    self.setup_url_rewrite(URI(request.url).scheme, request.host_with_port)
  end

  def self.setup_url_rewrite(scheme, host_with_port)
    Thread.current[:scheme] = scheme
    Thread.current[:host_with_port] = host_with_port
  end
end
