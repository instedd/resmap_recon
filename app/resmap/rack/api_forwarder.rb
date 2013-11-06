module Resmap
  module Rack
    class ApiForwarder
      def call(env)
        request = ::Rack::Request.new(env)
        email = request.session[:email]
        password = request.session[:password]
        api = ResourceMap::Api.basic_auth(params[:email], params[:password], Settings.resource_map.host, Settings.resource_map.https)

        [ 200,
          {'Content-Type' => 'application/json'},
          [api.get(env['PATH_INFO'])]
        ]
      end
    end
  end
end
