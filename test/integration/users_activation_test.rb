require 'test_helper'

class UsersActivationTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:michael)
    @non_activated_user = users(:red)
  end

  # test "index only activated user" do 　　　　　　#/userの統合テスト
  #   log_in_as(@user)                            #ログインする
  #   get users_path                              #usersにアクセスする
  #   assert_select "a[href=?]", user_path(@user) #@userへのリンクがあることを確認
  #   assert_select "a[href=?]", user_path(@non_activated_user), count: 0 #@userへのリンクがないことを確認
  # end
  #
  # test "show only activated user" do    #/users/:idの統合テスト
  #   log_in_as(@non_activated_user)      #ログインする（誤答）
  #   get users_path                      #@userの詳細ページにアクセスする（誤答）→usersにアクセスする
  #   get user_path(@non_activated_user)  #@non_activated_userの詳細ページにアクセスする（誤答）→users/:id(有効化されていないユーザー)にアクセスする
  #   assert_redirected_to root_url       #root_urlにリダイレクトされる
  # end

  test "should not allow the not activated attribute" do # 有効化されていない属性を許可しない
    log_in_as(@non_activated_user)                       # @non_activated_userでログインする
    assert_not @non_activated_user.activated?            # @non_activated_userの有効化属性がfalseであること
    get users_path                                       # getで/usersにアクセスする
    assert_select "a[href=?]", user_path(@non_activated_user), count: 0 # 有効化されていないユーザーが表示されていないことを確認
                                                                        #（@non_activated_userのプロフィールページへのリンクがユーザー一覧に表示されていないことを確認）
    get user_path(@non_activated_user)                   # getで/users/:id（有効化されていないユーザー）にアクセスする
    assert_redirected_to root_url                        # ルートURLにリダイレクトされるはず 
  end
end
