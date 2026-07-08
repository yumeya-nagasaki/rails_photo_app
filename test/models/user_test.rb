require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "メールアドレスは小文字化され前後の空白が除去される" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "メールアドレスは必須である" do
    user = User.new(password: "password")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  test "メールアドレスは一意である" do
    user = User.new(email_address: users(:one).email_address, password: "password")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "has already been taken"
  end

  test "パスワードは8文字以上である" do
    user = User.new(email_address: "new@example.com", password: "short")
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "写真を複数持つ" do
    assert_respond_to users(:one), :photos
    assert_includes users(:one).photos, photos(:one)
  end

  test "セッションを複数持つ" do
    user = users(:one)
    session = user.sessions.create!

    assert_includes user.sessions, session
  end
end
