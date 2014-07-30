set :application, 'resmap_recon'
set :repo_url, 'https://bitbucket.org/instedd/resmap_recon.git'

# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

set :rvm_type, :system
set :rvm_ruby_version, '1.9.3'

set :branch, ENV['REVISION'] || 'master'
set :deploy_to, '/u/apps/resmap_recon'
# set :deploy_to, '/var/www/my_app'
# set :scm, :git

# set :format, :pretty
# set :log_level, :debug
# set :pty, true

set :linked_files, %w{config/settings.yml config/database.yml config/guisso.yml config/newrelic.yml}
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets}
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# set :default_env, { path: "/opt/ruby/bin:$PATH" }
# set :keep_releases, 5

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  task :write_version do
    on roles(:app) do
      within repo_path do
        execute :git, "describe --always > #{release_path}/VERSION"
      end
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

  after :finishing, 'deploy:cleanup'
  after :updating, 'deploy:write_version'
  after 'deploy:publishing', 'deploy:restart'
end
