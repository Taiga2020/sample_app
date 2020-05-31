require 'test_helper'

class PasswordResetsTest < ActionDispatch::IntegrationTest
  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:michael)
  end

  test "password resets" do
    #ForgetPasswordページを表示
    get new_password_reset_path
    assert_template 'password_resets/new'
    #無効なメールアドレスを入力(POST送信)
    post password_resets_path, params: { password_reset: { email: "" } }
    assert_not flash.empty? #エラーが出ているはず
    assert_template 'password_resets/new' #元のメール送信ページが表示されているはず
    #有効なメールアドレスを入力(POST送信)
    post password_resets_path, params: { password_reset: { email: @user.email } }
    assert_not_equal @user.reset_digest, @user.reload.reset_digest #reset_digestが更新されているはず
    assert_equal 1, ActionMailer::Base.deliveries.size # 1 = true
    assert_not flash.empty?
    assert_redirected_to root_url

    #以下、パスワード再設定フォームのテスト
    user = assigns(:user)
    #パスワード再設定画面へのリンクを開く
    #有効なユーザー、有効なトークン、【無効なメールアドレス】の場合
    get edit_password_reset_path(user.reset_token, email: "")
    assert_redirected_to root_url #無効なのでルートにリダイレクトされるはず
    #【無効なユーザー】、有効なトークン、有効なメールアドレスの場合
    user.toggle!(:activated)
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_redirected_to root_url #無効なのでリダイレクト
    user.toggle!(:activated)
    #有効なユーザー、【無効なトークン】、有効なメールアドレスの場合
    get edit_password_reset_path('wrong token', email: user.email)
    assert_redirected_to root_url #無効なのでリダイレクト
    #ユーザー、トークン、メールアドレスが全て有効な場合
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_template 'password_resets/edit' #パスワード再設定画面が表示される
    assert_select "input[name=email][type=hidden][value=?]", user.email
    #以下、再設定画面
    #無効なパスワード・パスワード確認を行った場合
    patch password_reset_path(user.reset_token),
      params: { email: user.email,
                user: { password:              "foobaz",
                        password_confirmation: "barquux" } }
    assert_select 'div#error_explanation' #エラー文表示確認
    #パスワードが空欄の場合
    patch password_reset_path(user.reset_token),
      params: { email: user.email,
                user: { password:              "",
                        password_confirmation: "" } }
    assert_select 'div#error_explanation' #エラー文表示確認
    #有効なパスワード・パスワード確認を行った場合
    patch password_reset_path(user.reset_token),
      params: { email: user.email,
                user: { password:              "foobaz",
                        password_confirmation: "foobaz" } }
    assert is_logged_in?      #ログインされるはず
    assert_not flash.empty?   #再設定完了flashが表示されているはず
    assert_redirected_to user #ユーザー画面が表示されるはず
  end

  test "expired token" do
    get new_password_reset_path #ForgetPasswordページを表示
    post password_resets_path,  #（リンクをメール送信）
      params: { password_reset: { email: @user.email } }

    @user = assigns(:user) #有効なユーザー
    @user.update_attribute(:reset_sent_at, 3.hours.ago) #ユーザーの有効期限切れ
    patch password_reset_path(@user.reset_token), #パスワード再設定画面で有効なパスワード・パスワード確認を入力
      params: { email: @user.email,
                user: { password:              "foobar",
                        password_confirmation: "foobar" } }
    assert_response :redirect
    follow_redirect!
    assert_match /expired/i, response.body
  end
end
