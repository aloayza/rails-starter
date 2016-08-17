# Add the current directory to the path Thor uses
# to look up files
def source_paths
  Array(super) + 
    [File.expand_path(File.dirname(__FILE__))]
end

# Add gems
remove_file "Gemfile"
run "touch Gemfile"
add_source 'https://rubygems.org'
gem 'rails', '4.2.7'
gem 'pg'
gem 'sass-rails'
gem 'uglifier'
gem 'coffee-rails'
gem 'jquery-rails'
gem 'turbolinks'
gem 'sdoc', '~> 0.4.0', group: :doc
gem 'will_paginate'
gem 'bcrypt'

# add gems for a particular group
gem_group :development, :test do
  gem 'byebug'
end

gem_group :development do
  gem 'web-console'
  gem 'spring'
  gem 'better_errors'
end

gem_group :production do
  gem 'rails_12factor'
  gem 'puma'
end

site_title = ask("What is the title of this site?")
run 'bundle install --without production'

after_bundle do
  # config
  # config/application.rb
  environment 'config.action_view.field_error_proc = Proc.new { |html_tag, instance| "<div class=\"is-invalid\">#{html_tag}</div>".html_safe }'
  environment 'config.generators.stylesheets = false'
  environment 'config.generators.javascripts = false'
  environment 'config.generators.helper = false'
  environment 'config.generators.jbuilder = false'

  # config/environments/development.rb
  gsub_file "config/environments/development.rb", /^.*config.action_mailer.raise_delivery_errors\s+=+\sfalse.*$/,''

  environment 'config.action_mailer.default_url_options = { host: host }', env: 'development'
  environment 'host = \'localhost:3000\'', env: 'development'
  environment 'config.action_mailer.delivery_method = :test', env: 'development'
  environment 'config.action_mailer.raise_delivery_errors = true', env: 'development'

  # config/environments/test.rb
  environment 'config.action_mailer.default_url_options = { host: \'example.com\' }', env: 'test'

  # config/environments/production.rb
  environment 'ActionMailer::Base.smtp_settings = { :address => \'smtp.sendgrid.net\', :port => \'587\', :authentication => :plain, :user_name => ENV[\'SENDGRID_USERNAME\'], :password => ENV[\'SENDGRID_PASSWORD\'], :domain => \'heroku.com\', :enable_starttls_auto => true }', env: 'production'
  environment 'config.action_mailer.default_url_options = { host: host }', env: 'production'
  environment 'host = \'.herokuapp.com\'', env: 'production'
  environment 'config.action_mailer.delivery_method = :smtp', env: 'production'
  environment 'config.action_mailer.raise_delivery_errors = true', env: 'production'
  environment 'config.force_ssl = true', env: 'production'

  generate(:controller, "StaticPages", "home", "about", "help")
  generate(:controller, "Users", "new")
  generate(:controller, "Sessions", "new")
  generate(:model, "User", "name:string", "email:string:uniq", "reset_digest:string", "reset_sent_at:datetime", "remember_digest:string", "password_digest:string")
  generate(:mailer, "UserMailer", "password_reset")
  generate(:controller, "PasswordResets", "new", "edit", "--no-test-framework")

  create_file 'Procfile' do <<-EOF
web: bundle exec puma -C config/puma.rb
    EOF
  end

  route "resources :password_resets, only: [:new, :create, :edit, :update]"
  route "resources :users"
  route "delete 'logout'     => 'sessions#destroy'"
  route "post 'login'        => 'sessions#create'"
  route "get 'login'         => 'sessions#new'"
  route "get 'signup'        => 'users#new'"
  route "get 'about'         => 'static_pages#about'"
  route "get 'help'          => 'static_pages#help'"
  route "root 'static_pages#home'"

  inside 'config' do
    gsub_file "routes.rb", /^.*get\s+["']password_resets\/new["'].*$/, ''
    gsub_file "routes.rb", /^.*get\s+["']password_resets\/edit["'].*$/, ''
    gsub_file "routes.rb", /^.*get\s+["']sessions\/new["'].*$/, ''
    gsub_file "routes.rb", /^.*get\s+["']users\/new["'].*$/, ''
    gsub_file "routes.rb", /^.*get\s+["']static_pages\/home["'].*$/, ''
    gsub_file "routes.rb", /^.*get\s+["']static_pages\/about["'].*$/, ''
    gsub_file "routes.rb", /^.*get\s+["']static_pages\/help["'].*$/, ''
    create_file 'puma.rb' do <<-EOF
workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads_count = Integer(ENV['MAX_THREADS'] || 5)
threads threads_count, threads_count

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'development'

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/
  # deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
end
      EOF
    end
    remove_file 'database.yml'
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

  inside 'db' do
    inside 'migrate' do
      copy_file '30151221044517_add_admin_to_users.rb'
    end
    remove_file 'seeds.rb'
    create_file 'seeds.rb' do <<-EOF
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
User.create!(name: "Allen Loayza",
    email: "allen.loayza@gmail.com",
    password: "123456789",
    password_confirmation: "123456789",
    admin: true)
      EOF
    end
  end

  inside 'app' do
    inside 'assets' do
      inside 'stylesheets' do
        insert_into_file 'application.css', " *= require reset\n", before: " *= require_tree ."
        insert_into_file 'application.css', " *= require main\n", before: " *= require_tree ."
        copy_file 'buttons.css'
        copy_file 'components.css'
        copy_file 'forms.css'
        copy_file 'grid.css'
        copy_file 'header.css'
        copy_file 'main.css'
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
      remove_file 'static_pages_controller.rb'
      create_file 'application_controller.rb' do <<-EOF
class ApplicationController < ActionController::Base
  before_action :logged_in_user, :current_user
  protect_from_forgery with: :exception
  include SessionsHelper

  private
    def logged_in_user
      unless logged_in?
        store_location
        flash[:danger] = "Please log in"
        redirect_to login_url
      end
    end

    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_url) unless current_user?(@user) || current_user.admin?
    end

    def admin_user
      redirect_to(root_url) unless current_user.admin?
    end
end
        EOF
      end
      copy_file 'password_resets_controller.rb'
      copy_file 'sessions_controller.rb'
      copy_file 'static_pages_controller.rb'
      copy_file 'users_controller.rb'
    end

    inside 'helpers' do
      remove_file 'application_helper.rb'
      create_file 'application_helper.rb' do <<-EOF
module ApplicationHelper
  def full_title(page_title = '')
    base_title = "#{site_title}" 
    if page_title.empty?
      base_title
    else
      page_title + " - " + base_title
    end
  end

  def errors_for(model, attribute)
    if model.errors[attribute].present?
      content_tag :p, :class => 'error-message' do
        model.errors[attribute].join(", ").titleize
      end
    end
  end

  def fab_action()
    if logged_in?
      if current_user.admin?
      end
    else
      if current_page?(root_path)
        signup_path
      end
    end
  end
end
        EOF
      end
      copy_file 'sessions_helper.rb'
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
        create_file 'application.html.erb' do <<-EOF
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <meta http-equiv="x-ua-compatible" content="ie=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><%= full_title(yield(:title)) %></title>
    <%= stylesheet_link_tag 'https://fonts.googleapis.com/css?family=Roboto:300,400,500,700', media: 'all', 'data-turbolinks-track' => true %>
    <%= stylesheet_link_tag 'https://fonts.googleapis.com/icon?family=Material+Icons', media: 'all', 'data-turbolinks-track' => true %>
    <%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track' => true %>
    <%= javascript_include_tag  'application', 'data-turbolinks-track' => true %>
    <%= csrf_meta_tags %>
  </head>
  <body>
    <%= render 'layouts/header' %>
    <main>
      <% flash.each do |message_type, message| %>
        <%= content_tag :div, class: ["alert", "\#{message_type}"] do %>
          <%= message %>
          <%= link_to content_tag(:i, "close", class: ["material-icons", "md-light"]), '#', class: "close" %>
        <% end %>
      <% end %>
      <div class="row">
        <div class="small-12 small-centered columns">
          <%= yield %>
        </div>
      </div>
    </main>
    <%= render 'layouts/footer' %>
    <%= debug(params) if Rails.env.development? %>
  </body>
<script>
  $('#menu').click(function() {
    $('#drawer').show();
    $('#obfuscator').show();
  });

  $('#obfuscator').click(function() {
    $('#drawer').hide();
    $('#obfuscator').hide();
  });

  $(".close").click(function(e) {
      e.preventDefault();
      $(this).parent().hide();
  });
</script>
</html>
          EOF
        end
        copy_file '_footer.html.erb'
        copy_file '_header.html.erb'
        gsub_file "_header.html.erb", /^.*<h1><\/h1>.*$/, "<h1>#{site_title}</h1>"
        gsub_file "_header.html.erb", /^.*<h5><\/h5>.*$/, "<h5>#{site_title}</h5>"
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
        remove_file 'edit.html.erb'
        remove_file 'index.html.erb'
        remove_file 'show.html.erb'
        copy_file 'edit.html.erb'
        copy_file '_form.html.erb'
        copy_file 'index.html.erb'
        copy_file 'new.html.erb'
        copy_file 'show.html.erb'
      end
    end
  end

  inside 'test' do
    remove_file 'test_helper.rb'
    create_file 'test_helper.rb' do <<-EOF
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
  include ApplicationHelper

  # Add more helper methods to be used by all tests here...
  def is_logged_in?
    !session[:user_id].nil?
  end

  def log_in_as(user, options = {})
    password = options[:password] || 'password'
    if integration_test?
      post login_path, session: { email: user.email, password: password }
    else
      session[:user_id] = user.id
    end
  end

  private

    def integration_test?
      defined?(post_via_redirect)
    end
end
      EOF
    end

    inside 'controllers' do
      remove_file 'sessions_controller_test.rb'
      remove_file 'static_pages_controller_test.rb'
      remove_file 'users_controller_test.rb'
      copy_file 'sessions_controller_test.rb'
      copy_file 'static_pages_controller_test.rb'
      gsub_file "static_pages_controller_test.rb", /^.*@base_title = "".*$/, "@base_title = '#{site_title}'"
      copy_file 'users_controller_test.rb'
    end

    inside 'fixtures' do
      remove_file 'users.yml'
      copy_file 'users.yml'
    end

    inside 'helpers' do
      copy_file 'application_helper_test.rb'
      gsub_file "application_helper_test.rb", /^.*assert_equal full_title, "".*$/, "assert_equal full_title, '#{site_title}'"
      gsub_file "application_helper_test.rb", /^.*assert_equal full_title\("Help"\), "Help - ".*$/, "assert_equal full_title('Help'), 'Help - #{site_title}'"
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

  inside 'lib' do
    inside 'templates' do
      inside 'erb' do
        inside 'scaffold' do
          copy_file '_form.html.erb'
          copy_file 'edit.html.erb'
          copy_file 'index.html.erb'
          copy_file 'new.html.erb'
          copy_file 'show.html.erb'
        end
      end
      inside 'rails' do
        inside 'scaffold_controller' do
          copy_file 'controller.rb'
        end
      end
    end
  end

  rake "db:create", env: "development"
  rake "db:create", env: "test"
  rake "db:migrate", env: "development"
  rake "db:migrate", env: "test"
  rake "db:seed"

  if yes? 'Do you want to initialize git? (y/n)'
    git :init
    git add: "."
    git commit: "-a -m 'Initial commit'"
  end
end