require "test_helper"

class PhotoTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @photo = @user.photos.build(title: "Test photo")
  end

  test "タイトルは必須である" do
    attach_image(@photo)

    @photo.title = nil
    assert_not @photo.valid?
    assert_includes @photo.errors[:title], "can't be blank"
  end

  test "タイトルは30文字以内である" do
    attach_image(@photo)

    @photo.title = "a" * 31
    assert_not @photo.valid?
    assert_includes @photo.errors[:title], "は30文字以内で入力してください。"
  end

  test "画像は必須である" do
    assert_not @photo.valid?
    assert_includes @photo.errors[:image], "can't be blank"
  end

  test "許可された画像形式を受け付ける" do
    %w[image/jpeg image/png image/gif image/webp].each do |content_type|
      photo = @user.photos.build(title: "Valid photo")
      attach_image(photo, content_type: content_type)

      assert photo.valid?, "expected #{content_type} to be valid"
    end
  end

  test "許可されない画像形式を拒否する" do
    @photo.image.attach(
      io: StringIO.new("not an image"),
      filename: "sample.txt",
      content_type: "text/plain"
    )

    assert_not @photo.valid?
    assert_includes @photo.errors[:image], "はJPEG, PNG, GIF, WebP形式の画像ファイルを選択してください。"
  end

  test "ユーザーに属する" do
    attach_image(@photo)
    assert_equal @user, @photo.user
  end

  private

  def attach_image(photo, content_type: "image/jpeg")
    photo.image.attach(
      io: File.open(file_fixture("sample.jpg")),
      filename: "sample.jpg",
      content_type: content_type
    )
  end
end
