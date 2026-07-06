require "net/http"

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

  def tweet
    @photo = Current.user.photos.find(params[:id])
    access_token = session[:access_token]

    if access_token.blank?
      redirect_to photos_path, alert: "tweet appと連携してください"
      return
    end

    response = post_tweet(access_token, @photo)

    if response.code == "201"
      redirect_to photos_path, notice: "ツイートしました"
    else
      Rails.logger.error("Tweet API error: #{response.code} #{response.body}")
      redirect_to photos_path, alert: "ツイートに失敗しました"
    end
  rescue => e
    redirect_to photos_path, alert: "ツイート中にエラーが発生しました: #{e.message}"
  end

  private

  def photo_params
    params.require(:photo).permit(:title, :image)
  end

  def post_tweet(access_token, photo)
    uri = URI("http://unifa-recruit-my-tweet-app.ap-northeast-1.elasticbeanstalk.com/api/tweets")

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer " + access_token
    request.body = {
      text: photo.title,
      url: url_for(photo.image)
    }.to_json

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end
  end
end
