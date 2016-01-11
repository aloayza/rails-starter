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
#gsub_file "Gemfile", /^gem\s+["']sqlite3["'].*$/,''

site_title = ask("What is the title of this site?")

run 'bundle install --without production'

after_bundle do
  # config
  # config/application.rb
  environment 'config.action_view.field_error_proc = Proc.new { |html_tag, instance| "<div class=\"is-invalid\">#{html_tag}</div>".html_safe }'
  environment 'config.generators.stylesheets = false'
  environment 'config.generators.javascripts = false'

  # config/environments/development.rb
  gsub_file "config/environments/development.rb", /^\s\sconfig.action_mailer.raise_delivery_errors\s+=+\sfalse.*$/,''

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

  inside 'config' do
    remove_file 'routes.rb'
    remove_file 'database.yml'
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
    create_file 'routes.rb' do <<-EOF
Rails.application.routes.draw do
  root 'static_pages#home'
  get 'help'          => 'static_pages#help'
  get 'about'         => 'static_pages#about'
  get 'signup'        => 'users#new'
  get 'login'         => 'sessions#new'
  post 'login'        => 'sessions#create'
  delete 'logout'     => 'sessions#destroy'
  resources :users
  resources :password_resets, only: [:new, :create, :edit, :update]
end
      EOF
    end
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
        remove_file 'application.css'
        create_file 'application.css' do <<-EOF
/*
 * This is a manifest file that'll be compiled into application.css, which will include all the files
 * listed below.
 *
 * Any CSS and SCSS file within this directory, lib/assets/stylesheets, vendor/assets/stylesheets,
 * or any plugin's vendor/assets/stylesheets directory can be referenced here using a relative path.
 *
 * You're free to add application-wide styles to this file and they'll appear at the bottom of the
 * compiled file so the styles you add here take precedence over styles defined in any styles
 * defined in the other CSS/SCSS files in this directory. It is generally better to create a new
 * file per style scope.
 *
 *= require reset
 *= require_tree .
 *= require_self
 */
html, body {
  height: 100%;
  font-family: 'Roboto', 'Helvetica', 'Arial', sans-serif;
}

footer {
  position: fixed;
  bottom: 0;
  width: 100%;
  text-align: right;
  padding-right: 25px;
  padding-bottom: 15px;
}

img {
  max-width: 100%;
  height: auto;
  display: inline-block;
  vertical-align: middle;
  -ms-interpolation-mode: bicubic;
}

#map_canvas img,
#map_canvas embed,
#map_canvas object,
.map_canvas img,
.map_canvas embed,
.map_canvas object,
.mqa-display img,
.mqa-display embed,
.mqa-display object {
  max-width: none !important;
}

.left { float: left !important; }
.right { float: right !important; }

*,
*:before,
*:after {
  -webkit-box-sizing: inherit;
  -moz-box-sizing: inherit;
  box-sizing: inherit;
}

.clearfix:before, .clearfix:after {
  content: " ";
  display: table;
}

.clearfix:after { clear: both; }
          EOF
        end
        copy_file 'buttons.css'
        copy_file 'components.css'
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
      create_file 'application_controller.rb' do <<-EOF
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  include SessionsHelper
end
        EOF
      end
      copy_file 'password_resets_controller.rb'
      copy_file 'sessions_controller.rb'
      create_file 'users_controller.rb' do <<-EOF
class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :logged_in_user, only: [:index, :edit, :update, :destroy]
  before_action :correct_user, only: [:edit, :update]
  before_action :admin_user, only: [:index, :destroy]

  # GET /users
  # GET /users.json
  def index
    @users = User.paginate(page: params[:page])
  end

  # GET /users/1
  # GET /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)
    if @user.save
      log_in @user
      flash[:success] = "Welcome to #{site_title}!"
      redirect_to @user
    else
      render :new
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    if @user.update(user_params)
      flash[:success] = "User was successfully updated"
      redirect_to @user
    else
      render :edit
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    flash[:success] = "User was successfully destroyed"
    redirect_to users_url
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end

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
    end

    inside 'helpers' do
      remove_file 'application_helper.rb'
      remove_file 'password_resets_helper.rb'
      remove_file 'sessions_helper.rb'
      remove_file 'users_helper.rb'
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
end
        EOF
      end
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
          <%= link_to raw('&times;'), '#', class: "close" %>
        <% end %>
      <% end %>
      <div class="row">
        <div class="small-11 small-centered large-8 columns">
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
        create_file '_header.html.erb' do <<-EOF
<header>
  <!-- Navigation. We hide it in small screens. -->
  <nav class="show-for-medium-up">
    <ul>
      <% if logged_in? %>
        <li><%= link_to 'Logout', logout_path, method: "delete" %></li>
        <li><%= link_to 'Settings', edit_user_path(current_user) %></li>
        <li><%= link_to 'Current', current_user %></li>
        <% if current_user.admin? %>
          <li><%= link_to 'All', users_path %></li>
        <% end %>
      <% else %>
        <li><%= link_to 'Help', help_path %></li>
        <li><%= link_to 'Sign up', signup_path %></li>
        <li><%= link_to 'Login', login_path %></li>
        <li><%= link_to 'Home', root_path %></li>
      <% end %>
    </ul>
  </nav>
  <i class="material-icons md-light" id="menu">menu</i>
  <!-- Title -->
  <h1>#{site_title}</h1>
</header>
<nav id="drawer">
  <!-- Title -->
  <h5>#{site_title}</h5>
  <ul>
    <% if logged_in? %>
      <% if current_user.admin? %>
        <li><%= link_to 'All', users_path %></li>
      <% end %>
      <li><%= link_to 'Current', current_user %></li>
      <li><%= link_to 'Settings', edit_user_path(current_user) %></li>
      <li><%= link_to 'Logout', logout_path, method: "delete" %></li>
    <% else %>
      <li><%= link_to 'Home', root_path %></li>
      <li><%= link_to 'Login', login_path %></li>
      <li><%= link_to 'Sign up', signup_path %></li>
      <li><%= link_to 'Help', help_path %></li>
      <li><%= link_to 'About', about_path %></li>
    <% end %>
  </ul>
</nav>
<div id="obfuscator"></div>
          EOF
        end
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
      create_file 'static_pages_controller_test.rb' do <<-EOF
require 'test_helper'

class StaticPagesControllerTest < ActionController::TestCase

  def setup
    @base_title = "#{site_title}"
  end

  test "should get home" do
    get :home
    assert_response :success
    assert_select "title", "\#{@base_title}"
  end

  test "should get help" do
    get :help
    assert_response :success
    assert_select "title", "Help - \#{@base_title}"
  end

  test "should get about" do
    get :about
    assert_response :success
    assert_select "title", "About - \#{@base_title}"
  end

end
        EOF
      end
      copy_file 'users_controller_test.rb'
    end

    inside 'fixtures' do
      remove_file 'users.yml'
      copy_file 'users.yml'
    end

    inside 'helpers' do
      create_file 'application_helper_test.rb' do <<-EOF
require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test "full title helper" do
    assert_equal full_title,         "#{site_title}"
    assert_equal full_title("Help"), "Help - #{site_title}"
  end
end
        EOF
      end
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