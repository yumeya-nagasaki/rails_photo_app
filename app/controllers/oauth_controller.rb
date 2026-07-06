require "net/http"

class OauthController < ApplicationController
  def authorize
    redirect_to authorization_url, allow_other_host: true
  end

  def callback
    code = params[:code]

    if code.blank?
      redirect_to photos_path, alert: "認可コードが取得できませんでした"
      return
    end

    token_response = fetch_access_token(code)

    if token_response["access_token"].blank?
      redirect_to photos_path, alert: "アクセストークンが取得できませんでした"
      return
    end

    session[:access_token] = token_response["access_token"]
    redirect_to photos_path, notice: "tweet app連携が完了しました"
  rescue => e
    redirect_to photos_path, alert: "OAuth2認証中にエラーが発生しました: #{e.message}"
  end

  private

  def authorization_url
    uri = URI("http://unifa-recruit-my-tweet-app.ap-northeast-1.elasticbeanstalk.com/oauth/authorize")

    uri.query = {
      client_id: "3R_m2ogptQ_5oNsq3FtPXAz6DYUJry374aQQhqJochQ",
      response_type: "code",
      redirect_uri: "http://localhost:3000/oauth/callback",
      scope: "write_tweet",
      state: ""
    }.to_query

    uri.to_s
  end

  def fetch_access_token(code)
    uri = URI("http://unifa-recruit-my-tweet-app.ap-northeast-1.elasticbeanstalk.com/oauth/token")

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/x-www-form-urlencoded"

    request.set_form_data(
      grant_type: "authorization_code",
      code: code,
      redirect_uri: "http://localhost:3000/oauth/callback",
      client_id: "3R_m2ogptQ_5oNsq3FtPXAz6DYUJry374aQQhqJochQ",
      client_secret: ENV.fetch("OAUTH2_CLIENT_SECRET")
    )

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error("Token endpoint error: #{response.code} #{response.body}")
      return {}
    end

    JSON.parse(response.body)
  end
end
