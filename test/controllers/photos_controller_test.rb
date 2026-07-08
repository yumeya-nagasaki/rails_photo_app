require "test_helper"

class PhotosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user_photo = photos(:two)
  end

  test "未ログイン時、写真一覧はログイン画面へリダイレクトされる" do
    get photos_path
    assert_redirected_to new_session_path
  end

  test "未ログイン時、写真新規作成はログイン画面へリダイレクトされる" do
    get new_photo_path
    assert_redirected_to new_session_path
  end

  test "未ログイン時、写真作成はログイン画面へリダイレクトされる" do
    post photos_path, params: photo_params
    assert_redirected_to new_session_path
  end

  test "未ログイン時、ツイートはログイン画面へリダイレクトされる" do
    post tweet_photo_path(photos(:one))
    assert_redirected_to new_session_path
  end

  test "ログイン時、写真一覧が表示される" do
    sign_in_as(@user)

    get photos_path
    assert_response :success
  end

  test "ログイン時、写真新規作成画面が表示される" do
    sign_in_as(@user)

    get new_photo_path
    assert_response :success
  end

  test "有効なパラメータで写真を作成できる" do
    sign_in_as(@user)

    assert_difference -> { @user.photos.count }, 1 do
      post photos_path, params: photo_params
    end

    assert_redirected_to photos_path
    follow_redirect!
    assert_match "写真をアップロードしました", response.body
  end

  test "無効なパラメータでは写真を作成できない" do
    sign_in_as(@user)

    assert_no_difference -> { @user.photos.count } do
      post photos_path, params: { photo: { title: "", image: fixture_file_upload("sample.jpg", "image/jpeg") } }
    end

    assert_response :unprocessable_entity
  end

  test "アクセストークンがない場合、ツイートは警告付きでリダイレクトされる" do
    sign_in_as(@user)
    photo = create_photo_for(@user)

    post tweet_photo_path(photo)

    assert_redirected_to photos_path
    follow_redirect!
    assert_match "tweet appと連携してください", response.body
  end

  test "APIが201を返す場合、ツイートに成功する" do
    photo = create_photo_for(@user)

    authenticated_session do |sess|
      with_env("OAUTH2_CLIENT_SECRET", "test-secret") do
        stub_http_response(body: { access_token: "test-token" }.to_json, status: "200", success: true) do
          sess.get oauth_callback_path, params: { code: "auth-code" }
        end
      end

      stub_http_response(body: "", status: "201", success: true) do
        sess.post tweet_photo_path(photo)
      end

      sess.assert_redirected_to photos_path
      sess.follow_redirect!
      assert_match "ツイートしました", sess.response.body
    end
  end

  test "APIがエラーを返す場合、ツイートに失敗する" do
    photo = create_photo_for(@user)

    authenticated_session do |sess|
      with_env("OAUTH2_CLIENT_SECRET", "test-secret") do
        stub_http_response(body: { access_token: "test-token" }.to_json, status: "200", success: true) do
          sess.get oauth_callback_path, params: { code: "auth-code" }
        end
      end

      stub_http_response(body: "error", status: "500", success: false) do
        sess.post tweet_photo_path(photo)
      end

      sess.assert_redirected_to photos_path
      sess.follow_redirect!
      assert_match "ツイートに失敗しました", sess.response.body
    end
  end

  test "他ユーザーの写真へのツイートはエラー付きでリダイレクトされる" do
    sign_in_as(@user)

    post tweet_photo_path(@other_user_photo)

    assert_redirected_to photos_path
    follow_redirect!
    assert_match "ツイート中にエラーが発生しました", response.body
  end

  private

  def photo_params
    {
      photo: {
        title: "New photo",
        image: fixture_file_upload("sample.jpg", "image/jpeg")
      }
    }
  end

  def create_photo_for(user)
    photo = user.photos.build(title: "Tweet target")
    photo.image.attach(
      io: File.open(file_fixture("sample.jpg")),
      filename: "sample.jpg",
      content_type: "image/jpeg"
    )
    photo.save!
    photo
  end

  def authenticated_session
    open_session do |sess|
      sess.extend(SessionTestHelper)
      sess.sign_in_as(@user)
      sess.get photos_path
      yield sess
    end
  end
end
