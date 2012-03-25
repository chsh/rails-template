# Rails 3.2 Application generator template
# ussage: rails new rails3-template.rb -T -d postgresql --skip-bundle
app_title = app_name.underscore.titleize

=begin
require 'openssl'
OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:ca_path] ||= '/etc/ssl/certs'

require 'open-uri'
require 'net/https'
module Net
  class HTTP
    alias_method :original_use_ssl=, :use_ssl=
    def use_ssl=(flag)
      self.ca_path = '/etc/ssl/certs' if File.exists?('/etc/ssl/certs')
      self.verify_mode = OpenSSL::SSL::VERIFY_PEER
      self.original_use_ssl = flag
    end
  end
end
=end

require 'openssl'
module OpenSSL::SSL
  remove_const :VERIFY_PEER
end
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

run "echo 'rvm use 1.9.3-p125@#{app_name} --create' > .rvmrc"
# database.yml related actions
# omit config/database.yml
run 'cp config/database.yml config/database.yml.example'
# prepare database.yml for production
run 'cp config/database.yml config/database.yml.production'
append_to_file '.gitignore', <<EOL
/config/database.yml
/config/database.yml.production
EOL

# remove unnesessary files
remove_file 'README.rdoc'
remove_file 'public/index.html'
remove_file 'public/robots.txt'
remove_file 'public/images/rails.png'

file 'README.md', <<-README
#{app_title}
README

# views
gem 'haml'
gem 'haml-rails', group: :development

# twitter bootstrap
gem_group :assets do
  gem 'bootstrap-rails'
end

# form
gem 'formtastic',
    git: 'git://github.com/justinfrench/formtastic.git',
    branch: '2.1-stable'
gem 'formtastic-bootstrap',
    git: 'https://github.com/cgunther/formtastic-bootstrap.git',
    branch: 'bootstrap2-rails3-2-formtastic-2-1'
gem 'tabulous'

initializer 'formtastic.rb' do
"Formtastic::Helpers::FormHelper.builder = FormtasticBootstrap::FormBuilder"
end
initializer 'fix_openssl_verification_error.rb' do
  <<EOL
require 'openssl'
module OpenSSL
  module SSL
    remove_const :VERIFY_PEER
  end
end
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
EOL
end

# testing
gem_group :development, :test do
  gem 'rspec-rails'
  gem 'factory_girl_rails'
end

# configs
gem 'configuration'

# facebook auth
gem 'devise'
gem 'omniauth'
gem 'omniauth-facebook'
gem 'koala'

get 'https://raw.github.com/gist/2191438/a0c3c075c21cd7250265b95bf42e95904c9f8206/omniauth_callbacks_controller.rb', 'app/controllers/users/omniauth_callbacks_controller.rb'
get 'https://raw.github.com/gist/2191440/ea5073f3147309227145c21b0fc20cd3fb259b83/sessions_controller.rb', 'app/controllers/users/sessions_controller.rb'

# server deployment
gem 'unicorn'
gem 'capistrano'
# assets
gem_group :assets do
  gem 'therubyracer'
end

remove_file 'config/database.yml'
create_file 'config/database.yml' do
  <<-EOL
development:
  adapter: postgresql
  encoding: unicode
  database: #{app_name}_d
  pool: 5
  username: #{ENV['RAILS_DB_USER']}
  password: #{ENV['RAILS_DB_PASS']}

test:
  adapter: postgresql
  encoding: unicode
  database: #{app_name}_t
  pool: 5
  username: #{ENV['RAILS_DB_USER']}
  password: #{ENV['RAILS_DB_PASS']}
EOL
end

#-------------------
run 'bundle install'
#-------------------
#
run 'bundle exec rake db:drop RAILS_ENV=development'
run 'bundle exec rake db:drop RAILS_ENV=test'
run 'bundle exec rake db:create'
run 'bundle exec rake db:migrate'

generate 'rspec:install'

create_file 'spec/support/factory_girl.rb' do
  <<EOL
# rspec
RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end
EOL
end
create_file 'spec/factories.rb'

generate 'devise:install'
generate 'devise User'
gsub_file 'config/environments/development.rb', /\nend/, "\n  config.action_mailer.default_url_options = { :host => 'localhost:3000' }\nend"

gsub_file 'config/routes.rb', /(devise_for :users)/, '\1, controllers: { omniauth_callbacks: "users/omniauth_callbacks", sessions: "users/sessions"}'
gsub_file 'app/models/user.rb', /(:validatable)\n/, "\\1, :omniauthable\n"

generate 'controller top welcome'
gsub_file 'config/routes.rb', /get "top\/welcome"/, 'root to: "top#welcome"'

create_file 'app/assets/stylesheets/twitter_bootstrap.css.scss' do
  <<EOL
@import 'bootstrap';
body {
  padding-top: 60px;
}
EOL
end

in_root do
  user_migration_file = `echo db/migrate/*_users.rb`
end
remove_file user_migration_file
create_file user_migration_file do
  <<EOL
class DeviseCreateUsers < ActiveRecord::Migration
  def change
    create_table(:users) do |t|
      t.string :facebook_user_id, null: false
      t.text :facebook_profile

      t.timestamps
    end

    add_index :users, :facebook_user_id, unique: true
  end
end
EOL
end
