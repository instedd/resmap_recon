set :application, 'resmap_recon'
set :repo_url, 'https://bitbucket.org/instedd/resmap_recon.git'

# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

set :rvm_type, :system
set :rvm_ruby_version, '1.9.3'

set :branch, ENV['REVISION'] || 'master'
set :deploy_to, '/u/apps/resmap_recon'
set :port, 4000

# set :format, :pretty
# set :log_level, :debug
# set :pty, true

set :linked_files, %w{config/settings.yml config/database.yml config/guisso.yml config/newrelic.yml}
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets}

namespace :foreman do
  desc 'Export the Procfile to Ubuntu upstart scripts'
  task :export do
    on roles(:app) do
      within current_path do
        execute :echo, "RAILS_ENV=production > .env"
        %w(PATH GEM_HOME GEM_PATH).each do |var|
          execute :rvm, %(#{fetch(:rvm_ruby_version)} do ruby -e 'puts "#{var}=\#{ENV["#{var}"]}"' >> .env)
        end
        execute :bundle, "exec rvmsudo foreman export upstart /etc/init -f Procfile -a #{fetch(:application)} -u `whoami` -p #{fetch(:port)} --concurrency=\"web=1\""
      end
    end
  end

  desc "Start the application services"
  task :start do
    on roles(:app) do
      sudo "start #{fetch(:application)}"
    end
  end

  desc "Stop the application services"
  task :stop do
    on roles(:app) do
      sudo "stop #{fetch(:application)}"
    end
  end

  desc "Restart the application services"
  task :restart do
    on roles(:app) do
      execute "sudo start #{fetch(:application)} || sudo restart #{fetch(:application)}"
    end
  end

  after 'deploy:publishing', 'foreman:export'
  after 'deploy:restart', 'foreman:restart'
end

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
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
