# config valid for current version and patch releases of Capistrano
lock "~> 3.16.0"
server '54.82.107.31', port: 22, roles: [:web, :app, :db], primary: true

#set :repo_url,        'ssh://APKA45X7PM4KFPLCSJVF@git-codecommit.ap-south-1.amazonaws.com/v1/repos/Survey2Connect'
set :repo_url,        'https://github.com/gunateja-challagundla/Practice.git'
set :git_http_username, 'gunateja.challagundla@gmail.com'
set :git_http_password, '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'
set :application,     'ruby'
set :user,            'ubuntu'
set :puma_threads,    [5, 20]
set :puma_workers,    2
set :format, :pretty
#set :rvm_ruby_version, 'ruby 2.7.1p83'

# Don't change these unless you know what you're doing
set :pty,             true
set :use_sudo,        false
set :stage,           :production
set :deploy_via,      :remote_cache
set :deploy_to,       "/home/#{fetch(:user)}/apps/#{fetch(:application)}"
set :puma_bind,       "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}-puma.sock?backlog=1024"
set :puma_state,      "#{shared_path}/tmp/pids/puma.state"
set :puma_pid,        "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.error.log"
set :puma_error_log,  "#{release_path}/log/puma.access.log"
set :branch, "nonmaster"
set :ssh_options, {
  forward_agent: true,  
  auth_methods: ["publickey"],
  user: 'ubuntu',
  keys: ["/home/ubuntu/forNginx.pem"]
}
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true  # Change to false when not using ActiveRecord
set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }
set :linked_dirs, %w(tmp/pids)

## Defaults:
# set :scm,           :git
# set :branch,        :nonmaster
# set :format,        :pretty
# set :log_level,     :debug
# set :keep_releases, 5

## Linked Files & Directories (Default None):
# set :linked_files, %w{config/database.yml}
# set :linked_dirs,  %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

## Linked Files & Directories (Default None):
# set :linked_files, %w{config/database.yml}
set :linked_files, %w{config/master.key}
# set :linked_dirs,  %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

namespace :puma do
  desc 'Create Directories for Puma Pids and Socket'
  task :make_dirs do
    on roles(:app) do
      execute "mkdir #{shared_path}/tmp/sockets -p"
      execute "mkdir #{shared_path}/tmp/pids -p"
    end
  end

  before :start, :make_dirs
end

namespace :deploy do
  desc "Make sure local git is in sync with remote."
  task :check_revision do
    on roles(:app) do
      unless `git rev-parse HEAD` == `git rev-parse origin/nonmaster`
        puts "WARNING: HEAD is not the same as origin/nonmaster"
        puts "Run `git push` to sync changes."
        exit
      end
    end
  end

  desc 'Initial Deploy'
  task :initial do
    on roles(:app) do
      before 'deploy:restart', 'puma:start'
      invoke 'deploy'
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      invoke! 'puma:restart'
    end
  end

  before :starting,     :check_revision
  # after  :finishing,    :compile_assets
  after  :finishing,    :cleanup
  after  :finishing,    :restart

end



