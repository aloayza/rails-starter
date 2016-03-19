class StaticPagesController < ApplicationController
  skip_before_action :logged_in_user, only: [:home, :about, :help]

  def home
  end

  def about
  end

  def help
  end
end