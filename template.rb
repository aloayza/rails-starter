# Add the current directory to the path Thor uses
# to look up files
def source_paths
  Array(super) + 
    [File.expand_path(File.dirname(__FILE__))]
end

# Add commonly used gems
gem 'will_paginate'
gem 'bcrypt'

# add gems for a particular group
gem_group :production do
  gem 'rails_12factor'
  gem 'puma'
end

# remove unneeded gems
gsub_file "Gemfile", /^gem\s+["']sqlite3["'].*$/,''

run 'bundle install --without production'

# config
# config/application.rb
environment 'config.action_view.field_error_proc = Proc.new { |html_tag, instance| "<div class=\"is-invalid\">#{html_tag}</div>".html_safe }'
environment 'config.generators.stylesheets = false'
environment 'config.generators.javascripts = false'

# config/environments/development.rb
gsub_file "config/environments/development.rb", /^\s\sconfig.action_mailer.raise_delivery_errors\s+=+\sfalse.*$/,''

environment 'config.action_mailer.raise_delivery_errors = true', env: 'development'
environment 'config.action_mailer.delivery_method = :test', env: 'development'
environment 'config.action_mailer.default_url_options = { host: host }', env: 'development'
environment 'host = \'localhost:3000\'', env: 'development'

# config/environments/test.rb
environment 'config.action_mailer.default_url_options = { host: \'localhost:3000\' }', env: 'test'

# config/environments/production.rb
environment 'config.force_ssl = true', env: 'production'
environment 'config.action_mailer.raise_delivery_errors = true', env: 'production'
environment 'config.action_mailer.delivery_method = :smtp', env: 'production'
environment 'host = \'.herokuapp.com\'', env: 'production'
environment 'config.action_mailer.default_url_options = { host: host }', env: 'production'
environment 'ActionMailer::Base.smtp_settings = { :address => \'smtp.sendgrid.net\', :port => \'587\', :authentication => :plain, :user_name => ENV[\'SENDGRID_USERNAME\'], :password => ENV[\'SENDGRID_PASSWORD\'], :domain => \'heroku.com\', :enable_starttls_auto => true }', env: 'production'

generate(:controller, "StaticPages", "home", "help", "about")
generate(:controller, "Users", "new")
generate(:controller, "Sessions", "new")
generate(:model, "User", "name:string", "email:string:uniq", "reset_digest:string", "reset_sent_at:datetime", "remember_digest:string", "password_digest:string")
generate(:migration, "add_admin_to_users", "admin:boolean")
generate(:mailer, "UserMailer", "password_reset")
generate(:controller, "PasswordResets", "new", "edit", "--no-test-framework")

copy_file 'Procfile'

inside 'config' do
  remove_file 'routes.rb'
  remove_file 'database.yml'

	copy_file 'puma.rb'
  copy_file 'routes.rb'
	create_file 'database.yml' do <<-EOF
default: &default
  adapter: postgresql
  encoding: unicode
  pool: 5

development:
  <<: *default
  database: #{app_name}_development
  template: template0
  username: aloayza
  password: aloayza
  host: localhost
  port: 5432

test:
  <<: *default
  database: #{app_name}_test
  template: template0

production:
  url: <%= ENV["DATABASE_URL"] %>

		EOF
	end
end

inside 'app' do
  inside 'assets' do
    inside 'stylesheets' do
      remove_file 'application.css'

      copy_file 'application.css'
      copy_file 'buttons.css'
      copy_file 'forms.css'
      copy_file 'grid.css'
      copy_file 'header.css'
      copy_file 'reset.css'
      copy_file 'tables.css'
      copy_file 'typography.css'
      copy_file 'visibility.css'
    end
  end

  inside 'controllers' do
    remove_file 'application_controller.rb'
    remove_file 'password_resets_controller.rb'
    remove_file 'sessions_controller.rb'
    remove_file 'users_controller.rb'

    copy_file 'application_controller.rb'
    copy_file 'password_resets_controller.rb'
    copy_file 'sessions_controller.rb'
    copy_file 'users_controller.rb'
  end

  inside 'helpers' do
    remove_file 'password_resets_helper.rb'
    remove_file 'sessions_helper.rb'
    remove_file 'users_helper.rb'

    copy_file 'password_resets_helper.rb'
    copy_file 'sessions_helper.rb'
    copy_file 'users_helper.rb'
  end

  inside 'mailers' do
    remove_file 'application_mailer.rb'
    remove_file 'user_mailer.rb'

    copy_file 'application_mailer.rb'
    copy_file 'user_mailer.rb'
  end

  inside 'models' do
    remove_file 'user.rb'

    copy_file 'user.rb'
  end

  inside 'views' do
    inside 'layouts' do
      remove_file 'application.html.erb'

      copy_file 'application.html.erb'
      copy_file '_footer.html.erb'
      copy_file '_header.html.erb'
    end

    inside 'password_resets' do
      remove_file 'edit.html.erb'
      remove_file 'new.html.erb'

      copy_file 'edit.html.erb'
      copy_file 'new.html.erb'
    end

    inside 'sessions' do
      remove_file 'new.html.erb'

      copy_file 'new.html.erb'
    end

    inside 'shared' do
      copy_file '_error_messages.html.erb'
    end

    inside 'static_pages' do
      remove_file 'about.html.erb'
      remove_file 'help.html.erb'
      remove_file 'home.html.erb'

      copy_file 'about.html.erb'
      copy_file 'help.html.erb'
      copy_file 'home.html.erb'
    end

    inside 'user_mailer' do
      remove_file 'password_reset.html.erb'
      remove_file 'password_reset.text.erb'

      copy_file 'password_reset.html.erb'
      copy_file 'password_reset.text.erb'
    end

    inside 'users' do
      remove_file 'new.html.erb'

      copy_file 'edit.html.erb'
      copy_file '_form.html.erb'
      copy_file 'index.html.erb'
      copy_file 'new.html.erb'
      copy_file 'show.html.erb'
      copy_file '_user.html.erb'
    end
  end
end

inside 'test' do
  remove_file 'test_helper.rb'

  copy_file 'test_helper.rb'

  inside 'controllers' do
    remove_file 'sessions_controller_test.rb'
    remove_file 'static_pages_controller_test.rb'
    remove_file 'users_controller_test.rb'

    copy_file 'sessions_controller_test.rb'
    copy_file 'static_pages_controller_test.rb'
    copy_file 'users_controller_test.rb'
  end

  inside 'fixtures' do
    remove_file 'users.yml'

    copy_file 'users.yml'
  end

  inside 'integration' do
    copy_file 'password_resets_test.rb'
    copy_file 'site_layout_test.rb'
    copy_file 'users_edit_test.rb'
    copy_file 'users_index_test.rb'
    copy_file 'users_login_test.rb'
    copy_file 'users_signup_test.rb'
  end

  inside 'mailers' do
    remove_file 'user_mailer_test.rb'

    copy_file 'user_mailer_test.rb'

    inside 'previews' do
      remove_file 'user_mailer_preview.rb'

      copy_file 'user_mailer_preview.rb'
    end
  end

  inside 'models' do
    remove_file 'user_test.rb'

    copy_file 'user_test.rb'
  end
end