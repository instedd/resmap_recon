module Resmap
  module Rack
    class ApiForwarder
      def call(env)
        request = ::Rack::Request.new(env)

        email = request.session[:email]
        password = request.session[:password]

        AppContext.resmap_api = ResourceMap::Api.basic_auth(email, password, Settings.resource_map.host, Settings.resource_map.https)
        AppContext.setup_url_rewrite_from_request(request)

        query = nil
        unless request.query_string.blank?
          query = ::Rack::Utils.parse_nested_query(request.query_string)
        end

        [ 200,
          {'Content-Type' => 'application/json'},
          [AppContext.resmap_url_to_recon(AppContext.resmap_api.get(env['PATH_INFO'], query))]
        ]
      end
    end
  end
end
