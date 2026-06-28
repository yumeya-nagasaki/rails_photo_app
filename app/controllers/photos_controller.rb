class PhotosController < ApplicationController
  def index
    # ログイン中のユーザに紐づく写真を取得
    @photos = Current.user.photos.order(created_at: :desc)
  end

  def new
    # 空の写真オブジェクトを用意する（ビューで使うため）
    @photo = Current.user.photos.build
  end

  def create
    # 写真オブジェクトを作成し、写真パラメータを設定する
    @photo = Current.user.photos.build(photo_params)

    if @photo.save
      # 写真の保存に成功した場合
      redirect_to photos_path, notice: "写真をアップロードしました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def photo_params
    params.require(:photo).permit(:title, :image)
  end
end
