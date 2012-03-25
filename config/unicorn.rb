# unicorn_rails -c /srv/myapp/current/config/unicorn.rb -E production -D
#
app_dir = "#{ENV['DEPLOY_ROOT']}/current"
shared_dir = "#{ENV['DEPLOY_ROOT']}/shared"

deploy_name = ENV['DEPLOY_ROOT'].gsub(/^.+\//, '')

working_directory app_dir
# worker_processes  (rails_env == 'production' ? 10 : 4)
preload_app       true
timeout           30

listen      "/tmp/unicorn.#{deploy_name}.sock", :backlog => 2048

pid         "#{shared_dir}/pids/unicorn.pid"
stderr_path "#{shared_dir}/log/unicorn.log"
stdout_path "#{shared_dir}/log/unicorn.log"


GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=)

before_fork do |server, worker|
  ActiveRecord::Base.connection.disconnect!

  ##
  # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
  # immediately start loading up a new version of itself (loaded with a new
  # version of our app). When this new Unicorn is completely loaded
  # it will begin spawning workers. The first worker spawned will check to
  # see if an .oldbin pidfile exists. If so, this means we've just booted up
  # a new Unicorn and need to tell the old one that it can now die. To do so
  # we send it a QUIT.
  #
  # Using this method we get 0 downtime deploys.

  old_pid = "#{shared_dir}/pids/unicorn.pid.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end


after_fork do |server, worker|
  ActiveRecord::Base.establish_connection

  worker.user('deployer', 'deployer') if Process.euid == 0
end
