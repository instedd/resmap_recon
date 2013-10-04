class AppContext

  def self.resmap_api=(api)
    Thread.current[:resmap_api] = api
  end

  def self.resmap_api
    Thread.current[:resmap_api]
  end

end
