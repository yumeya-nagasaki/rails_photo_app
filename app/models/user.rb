class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  # ユーザーは複数の写真を持つ、ユーザーが削除されたら写真も削除される
  has_many :photos, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
  validates :password, length: { minimum: 8 }, allow_nil: true
end
