# config valid only for current version of Capistrano
lock '3.6.1'

set :application, 'tcal'
set :repo_url, 'git@github.com:RoryDH/tcal.git'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/home/rh/www/tcal'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto, truncate: :auto

# Default value for :pty is false
set :pty, true

# Default value for :linked_files is []
# append :linked_files, 'config/database.yml', 'config/secrets.yml'

# Default value for linked_dirs is []
# append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system'

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

# deploy.rb
# Default value for :linked_files is []
append :linked_files, 'config/database.yml', 'config/secrets.yml'

# Default value for linked_dirs is []
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system'


set :assets_roles, [:app]
set :migration_role, :db

set :rbenv_type, :user
set :rbenv_ruby, File.read('.ruby-version').strip

namespace :deploy do
  desc "Recreate nginx.conf symlink"
  task :nginx_symlink do
    on roles(:app) do
      execute "sudo rm -f /opt/nginx/conf/nginx.conf && sudo ln -s #{release_path}/config/nginx.conf /opt/nginx/conf/nginx.conf"
    end
  end
  after :publishing, :nginx_symlink

  desc "Uploads YAML files."
  task :upload_yml do
    on roles(:all) do
      upload!("./config/prod_database.yml", "#{shared_path}/config/database.yml")
      upload!("./config/prod_secrets.yml", "#{shared_path}/config/secrets.yml")
    end
  end
  before "deploy:check", :upload_yml
end
