set :stage, :staging

server ENV['HOST'] || "mfl-staging.instedd.org", user: 'ubuntu', roles: %w{web app db}
