module Resmap
  module Rack
    class ApiForwarder
      def call(env)
        request = ::Rack::Request.new(env)
        email = request.session[:email]
        password = request.session[:password]
        api = ResourceMap::Api.basic_auth(email, password, Settings.resource_map.host, Settings.resource_map.https)

        query = nil
        unless request.query_string.blank?
          query = ::Rack::Utils.parse_nested_query(request.query_string)
        end

        [ 200,
          {'Content-Type' => 'application/json'},
          [rewrite_response(env, request, api, api.get(env['PATH_INFO'], query))]
        ]
      end

      protected

      def rewrite_response(env, request, api, body)
        api_mount = "#{URI(request.url).scheme}://#{request.host_with_port}#{env['SCRIPT_NAME']}/"
        api_url = api.url

        body.gsub(api_url, api_mount)
      end
    end
  end
end
