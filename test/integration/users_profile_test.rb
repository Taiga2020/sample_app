require 'test_helper'

class UsersProfileTest < ActionDispatch::IntegrationTest
  include ApplicationHelper

  def setup
    @user = users(:michael)
  end

  test "profile display" do
    get user_path(@user) #有効なユーザー
    assert_template 'users/show' #プロフィール画面の表示を確認
    assert_select 'title', full_title(@user.name) #タグ確認
    assert_select 'h1', text: @user.name #タグ確認
    assert_select 'h1>img.gravatar' #タグ確認
    assert_match @user.microposts.count.to_s, response.body #マイクロポストの数確認
    assert_select 'div.pagination', count:1 #タグ確認
    @user.microposts.paginate(page: 1).each do |micropost|
      assert_match micropost.content, response.body
    end
  end
end
