class UsersController < ApplicationController
  rate_limit to: 5, within: 15.minutes,
             by: -> { request.remote_ip },
             with: :render_rate_limited,
             only: :create,
             name: "signup-ip"
  rate_limit to: 3, within: 1.hour,
             by: -> { rate_limit_key(params.dig(:user, :email)) },
             with: :render_rate_limited,
             only: :create,
             name: "signup-email"

  before_action :logged_in_user, only: [ :show, :edit, :update ]
  before_action :correct_user,   only: [ :show, :edit, :update ]
  def new
    @user = User.new
  end

  def show
    @user = User.find(params[:id])
  end

  def create
    @user = User.new(user_params)
    if @user.save
      session[:activation_email] = @user.email

      begin
        @user.send_activation_email
      rescue *ApplicationMailer::DELIVERY_ERRORS => error
        Rails.logger.error(
          "Activation email delivery failed for user_id=#{@user.id}: " \
          "#{error.class}: #{error.message}"
        )
        flash[:alert] = t("flash.account_activations.initial_delivery_failed")
      end

      redirect_to account_activation_resend_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    if @user.email == "guest@example.com"
      redirect_to root_path,
                  alert: t("flash.authorization.guest_user_cannot_be_edited")
      return
    end

    @user = User.find(params[:id])
    if @user.update(user_params)
      flash[:success] = t("flash.users.updated")
      redirect_to @user
    else
      render "edit", status: :unprocessable_entity
    end
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end

    def logged_in_user
      unless logged_in?
        store_location
        flash[:danger] = t("flash.authentication.login_required")
        redirect_to login_url, status: :see_other
      end
    end

    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_url, status: :see_other) unless current_user?(@user)
    end
end
