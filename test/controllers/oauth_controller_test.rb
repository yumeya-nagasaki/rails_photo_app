require "test_helper"

class OauthControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "未ログイン時、認可開始はログイン画面へリダイレクトされる" do
    get oauth_authorize_path
    assert_redirected_to new_session_path
  end

  test "未ログイン時、コールバックはログイン画面へリダイレクトされる" do
    get oauth_callback_path, params: { code: "auth-code" }
    assert_redirected_to new_session_path
  end

  test "認可開始は外部OAuth URLへリダイレクトされる" do
    sign_in_as(@user)

    get oauth_authorize_path

    assert_response :redirect
    assert_match %r{unifa-recruit-my-tweet-app\.ap-northeast-1\.elasticbeanstalk\.com/oauth/authorize}, response.location
    assert_match "client_id=3R_m2ogptQ_5oNsq3FtPXAz6DYUJry374aQQhqJochQ", response.location
    assert_match "response_type=code", response.location
  end

  test "認可コードがない場合、コールバックは警告付きでリダイレクトされる" do
    sign_in_as(@user)

    get oauth_callback_path

    assert_redirected_to photos_path
    follow_redirect!
    assert_match "認可コードが取得できませんでした", response.body
  end

  test "認可コードがある場合、アクセストークンを保存する" do
    with_env("OAUTH2_CLIENT_SECRET", "test-secret") do
      stub_http_response(body: { access_token: "oauth-token" }.to_json, status: "200", success: true) do
        authenticated_session do |sess|
          sess.get oauth_callback_path, params: { code: "auth-code" }

          sess.assert_redirected_to photos_path
          assert_equal "oauth-token", sess.request.session[:access_token]
          sess.follow_redirect!
          assert_match "tweet app連携が完了しました", sess.response.body
        end
      end
    end
  end

  test "トークン取得に失敗した場合、警告付きでリダイレクトされる" do
    with_env("OAUTH2_CLIENT_SECRET", "test-secret") do
      stub_http_response(body: "error", status: "400", success: false) do
        authenticated_session do |sess|
          sess.get oauth_callback_path, params: { code: "auth-code" }

          sess.assert_redirected_to photos_path
          assert_nil sess.request.session[:access_token]
          sess.follow_redirect!
          assert_match "アクセストークンが取得できませんでした", sess.response.body
        end
      end
    end
  end

  private

  def authenticated_session
    open_session do |sess|
      sess.extend(SessionTestHelper)
      sess.sign_in_as(@user)
      sess.get photos_path
      yield sess
    end
  end
end
