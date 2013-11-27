set :stage, :production

server 'staging.instedd.org', user: 'ubuntu', roles: %w{web app db}
