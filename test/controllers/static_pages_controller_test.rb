require "test_helper"

class StaticPagesControllerTest < ActionDispatch::IntegrationTest
  test "should get root" do
    get root_url
    assert_response :success
    assert_select "form[action='#{route_search_path}'][method='get']" do
      assert_select "input[name='address']"
    end
    assert_select "a[href='#{new_town_path}']", count: 0
    assert_select "script[data-font-awesome-script][defer]", count: 1
    assert_select "script[data-sortable-script]", count: 0
  end

  test "home shows town registration only to admins" do
    log_in_as(users(:archer))
    get root_url
    assert_select "a[href='#{new_town_path}']", count: 0

    log_in_as(users(:michael))
    get root_url
    assert_select "a[href='#{new_town_path}']", count: 1
  end

  test "should get contact" do
    get contact_path
    assert_response :success
    assert_select "a[href='#{new_contact_path}']", text: "メールを送る"
    assert_select "a[href='#{help_path}']", text: "ヘルプを見る"
  end

  test "should get help" do
    get help_path
    assert_response :success
    assert_select "h1", text: "使い方"
    assert_select "a[href='#{towns_path}']", text: "町一覧を見る"
    assert_select "aside a[href='#{help_path}']", text: /ヘルプ/
    assert_select "footer a[href='#{help_path}']", text: /Help/
  end
end
