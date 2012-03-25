set :unicorn_script, "/etc/init.d/unicorn"
set(:unicorn_config_path) { "/etc/unicorn/#{application}-#{target_name}.conf" }

namespace :deploy do
  task :start, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} #{unicorn_script} start #{unicorn_config_path}"
  end
  # stop graceful
  task :stop, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} #{unicorn_script} stop #{unicorn_config_path}"
  end
  task :reload, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} #{unicorn_script} restart #{unicorn_config_path}"
  end
  task :restart, :roles => :app, :except => { :no_release => true } do
    reload
  end
  task :stop_start, :roles => :app, :except => { :no_release => true } do
    stop
    start
  end
end

