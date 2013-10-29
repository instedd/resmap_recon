module Resmap
  module Rack
    class ApiForwarder
      def call(env)
        request = ::Rack::Request.new(env)
        email = request.session[:email]
        password = request.session[:password]
        api = ResmapApi.basic(email, password)

        [ 200,
          {'Content-Type' => 'application/json'},
          [api.get(env['PATH_INFO'])]
        ]
      end
    end
  end
end
