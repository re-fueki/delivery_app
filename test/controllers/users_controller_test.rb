require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user =  users(:michael)
    @other_user = users(:archer)
  end

  test "should show user" do
    log_in_as(@user)
    get user_url(@user)
    assert_response :success
  end

  test "should redirect show when not logged in" do
    get user_url(@user)
    assert_not flash.empty?
    assert_redirected_to login_url
  end

  test "should redirect show when logged in as wrong user" do
    log_in_as(@other_user)
    get user_url(@user)
    assert flash.empty?
    assert_redirected_to root_url
  end

  test "should get new" do
    get signup_path
    assert_response :success
  end

  test "should create user" do
    assert_difference("User.count") do
      post users_url, params: {
                      user:   {
                      name: "michael",
                      email: "test@example.com",
                      password: "password",
                      password_confirmation: "password"
                      }
      }
    end
    assert_redirected_to account_activation_resend_path
  end

  test "should not create user with invalid data" do
    assert_no_difference("User.count") do
      post users_url, params: {
                      user: { name: "",
                              email: "invalid",
                              password: "foo",
                              password_confirmation: "bar" } }
    end

    assert_response :unprocessable_entity
  end

  test "signup IP limit blocks account creation and email delivery until expiry" do
    5.times do |index|
      post users_url, params: signup_params("signup-#{index}@example.com")
      assert_redirected_to account_activation_resend_path
    end

    assert_no_difference [ "User.count", "ActionMailer::Base.deliveries.size" ] do
      post users_url, params: signup_params("signup-blocked@example.com")
      assert_response :too_many_requests
    end

    get signup_path
    assert_response :success

    travel 16.minutes do
      post users_url, params: signup_params("signup-blocked@example.com")
      assert_redirected_to account_activation_resend_path
    end
  end

  test "signup email limit normalizes email and applies across IP addresses" do
    [ "limited@example.com", "LIMITED@example.com", " limited@example.com " ].each_with_index do |email, index|
      post users_url,
           params: { user: { name: "", email: email } },
           headers: { "REMOTE_ADDR" => "192.0.2.#{index + 1}" }
      assert_response :unprocessable_entity
    end

    assert_no_difference [ "User.count", "ActionMailer::Base.deliveries.size" ] do
      post users_url,
           params: signup_params("limited@example.com"),
           headers: { "REMOTE_ADDR" => "192.0.2.4" }
      assert_response :too_many_requests
    end

    travel 61.minutes do
      post users_url,
           params: signup_params("limited@example.com"),
           headers: { "REMOTE_ADDR" => "192.0.2.4" }
      assert_redirected_to account_activation_resend_path
    end
  end

  test "should edit user" do
    log_in_as(@user)
    get edit_user_path(@user)
    assert_response :success
  end

  test "should redirect edit when not logged in" do
    get edit_user_path(@user)
    assert_not flash.empty?
    assert_redirected_to login_url
  end

  test "should redirect edit when logged in as wrong user" do
    log_in_as(@other_user)
    get edit_user_path(@user)
    assert flash.empty?
    assert_redirected_to root_url
  end

  test "should update user" do
    log_in_as(@user)
    patch user_path(@user), params: {
                            user: { name: "new",
                                    email: "new@example.com",
                                    password: "password",
                                    password_confirmation: "password" } }
    assert_redirected_to user_url(@user)
  end

  test "should not update user with invalid data" do
    log_in_as(@user)

    patch user_path(@user), params: { user: { name: "",
                                              email: "invalid" } }
    assert_response :unprocessable_entity
  end

  test "should redirect update when not logged in" do
    patch user_path(@user), params: { user: { name: @user.name,
                                              email: @user.email } }
    assert_not flash.empty?
    assert_redirected_to login_url
  end

  test "should redirect update when logged in as wrong user" do
    log_in_as(@other_user)
    patch user_path(@user), params: { user: { name: @user.name,
                                              email: @user.email } }
    assert flash.empty?
    assert_redirected_to root_url
  end

  test "should not allow the admin attribute to be edited via the web" do
    log_in_as(@other_user)
    assert_not @other_user.admin?
    patch user_path(@other_user), params: {
                                  user:   { password:              "password",
                                            password_confirmation: "password",
                                            admin:                 "true" } }
    assert_not @other_user.reload.admin?
  end

  private

    def signup_params(email)
      {
        user: {
          name: "テストユーザー",
          email: email,
          password: "password",
          password_confirmation: "password"
        }
      }
    end
end
