set :stage, :production

server ENV['HOST'] || "mfl.instedd.org", user: 'ubuntu', roles: %w{web app db}
