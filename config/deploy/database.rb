
before "deploy:setup", "db:configure"
before "deploy:assets:precompile", "db:symlink"

namespace :db do
  desc "Create database yaml in shared path"
  task :configure do

    db_config = File.read(ENV['DBYAML_PATH'] || 'config/database.yml.production')

    run "mkdir -p #{shared_path}/config"
    put db_config, "#{shared_path}/config/database.yml"
  end

  desc "Make symlink for database yaml"
  task :symlink do
    run "ln -nfs #{shared_path}/config/database.yml #{latest_release}/config/database.yml"
  end
end
