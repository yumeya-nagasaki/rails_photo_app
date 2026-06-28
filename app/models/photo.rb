class Photo < ApplicationRecord
  belongs_to :user

  has_one_attached :image

  validates :image, presence: true
  validates :title, presence: true, length: { maximum: 30, message: "は30文字以内で入力してください。" }

  validate :image_must_be_valid_type

  private

  def image_must_be_valid_type
    # 画像ファイルが添付されていない場合、リターン
    return unless image.attached?

    allowed_types = [
      "image/jpeg",
      "image/png",
      "image/gif",
      "image/webp"
    ]

    unless image.blob.content_type.in?(allowed_types)
      # 画像ファイルの形式が許可されていない場合、エラーを追加
      errors.add(:image, "はJPEG, PNG, GIF, WebP形式の画像ファイルを選択してください。")
    end
  end
end
