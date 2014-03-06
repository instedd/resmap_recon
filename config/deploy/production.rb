set :stage, :production

server ENV['HOST'], user: 'ubuntu', roles: %w{web app db}
