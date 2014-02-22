 # config valid only for Capistrano 3.1
  lock '3.1.0'
  
  set :application, 'sitename.com'
  set :repo_url, "git@github.com:toreyheinz/#{fetch(:application)}"
  set :deploy_to, "/home/tc/#{fetch(:application)}"
  set :chruby_ruby, 'ruby-2.1.0'
  
  # Set files & folders that must persist between deployments
  set :linked_files, %w{config/mongoid.yml config/application.yml}
  set :linked_dirs, %w{log}
  
  def template(template_path, upload_path)
    erb = StringIO.new(ERB.new(File.read(template_path)).result(binding))
    upload! erb, upload_path
    info "copying: #{template_path} to: #{upload_path}"
  end
  
  # Default value for :pty is false
  # set :pty, true
  
  namespace :deploy do
    desc 'Restart application'
      task :restart do
        on roles(:app), in: :sequence, wait: 5 do
          # Your restart mechanism here, for example:
          execute :touch, release_path.join('tmp/restart.txt')
        end
      end
  
      after :finishing, 'deploy:cleanup'
      after :finishing, 'deploy:restart'
  
      desc 'Upload Config Files'
      task :upload_config do
      on roles(:app) do
        upload!('config/mongoid.yml', "#{shared_path}/config/mongoid.yml")
      end
    end
  end
  
  namespace :nginx do
    desc "Update nginx configuration for this application"
    task :update do
      on roles(:web) do
        template "config/nginx_passenger.erb", "/home/tc/nginx/sites/#{fetch(:application)}"
      end
    end
  
    %w[start stop restart reload].each do |command|
      desc "#{command} nginx"
      task command do
        on roles(:web) do
          sudo "service nginx #{command}"
       end
      end
    end
  end
