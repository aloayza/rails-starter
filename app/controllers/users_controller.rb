class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  skip_before_action :logged_in_user, only: [:new, :create]
  before_action :correct_user, only: [:edit, :update]
  before_action :admin_user, only: [:index, :destroy]

  # GET /users
  def index
    @users = User.paginate(page: params[:page])
  end

  # GET /users/1
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
  def create
    @user = User.new(user_params)
    if @user.save
      log_in @user
      flash[:success] = "Welcome to my site!"
      redirect_to @user
    else
      render :new
    end
  end

  # PATCH/PUT /users/1
  def update
    if @user.update(user_params)
      flash[:success] = "User was successfully updated"
      redirect_to @user
    else
      render :edit
    end
  end

  # DELETE /users/1
  def destroy
    @user.destroy
    flash[:success] = "User was successfully destroyed"
    redirect_to users_url
  end

  private
    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end
end
