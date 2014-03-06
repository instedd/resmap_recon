set :stage, :production

set :branch, fetch(:branch, 'master')

server ENV['HOST'], user: 'ubuntu', roles: %w{web app db}
