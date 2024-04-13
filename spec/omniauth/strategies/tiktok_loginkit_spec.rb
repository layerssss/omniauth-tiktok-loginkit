# frozen_string_literal: true

RSpec.describe OmniAuth::Strategies::TiktokLoginkit do # rubocop:disable Metrics/BlockLength
  let(:app) { ->(_) { [200, {}, "success"] } }
  let(:client_key) { "CLIENT_KEY" }
  let(:client_secret) { "CLIENT_SECRET" }
  let(:subject) { OmniAuth::Strategies::TiktokLoginkit.new(app, client_key, client_secret) }
  let(:session) { {} }

  before do
    env["rack.session"] = session
    OmniAuth.config.on_failure = proc do |env|
      raise env["omniauth.error"]
    end
    OmniAuth.config.allowed_request_methods = %i[get]
  end

  context "request phase" do
    let(:env) do
      Rack::MockRequest.env_for(
        "http://localhost:3000/auth/tiktok-loginkit"
      )
    end

    it "redirects to the authorize_url" do
      status, headers, = subject.call!(env)
      expect(status).to eq(302)
      redirected_uri = URI.parse(headers["Location"])
      redirected_params = Rack::Utils.parse_query(redirected_uri.query)
      expect(redirected_uri.host).to eq("www.tiktok.com")
      expect(redirected_uri.path).to eq("/v2/auth/authorize/")
      expect(redirected_params).to include(
        "client_key" => client_key,
        "redirect_uri" => "http://localhost:3000/auth/tiktok-loginkit/callback",
        "response_type" => "code",
        "scope" => "user.info.basic",
        "state" => subject.session["omniauth.state"]
      )
    end
  end

  context "callback phase" do # rubocop:disable Metrics/BlockLength
    let(:env) do
      Rack::MockRequest.env_for(
        "http://localhost:3000/auth/tiktok-loginkit/callback?code=CODE&state=STATE&scopes=user.info.basic"
      )
    end

    before do # rubocop:disable Metrics/BlockLength
      session["omniauth.state"] = "STATE"

      # stub AccessToken API call:
      # https://developers.tiktok.com/doc/oauth-user-access-token-management/
      stub_request(:post, "https://open.tiktokapis.com/v2/oauth/token/")
        .with(
          body: {
            "client_key" => "CLIENT_KEY",
            "client_secret" => "CLIENT_SECRET",
            "code" => "CODE",
            "grant_type" => "authorization_code",
            "redirect_uri" => "http://localhost:3000/auth/tiktok-loginkit/callback"
          }
        )
        .to_return(
          status: 200,
          body: {
            "access_token": "act.example12345Example12345Example",
            "expires_in": 86_400,
            "open_id": "afd97af1-b87b-48b9-ac98-410aghda5344",
            "refresh_expires_in": 31_536_000,
            "refresh_token": "rft.example12345Example12345Example",
            "scope": "user.info.basic",
            "token_type": "Bearer"
          }.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )

      # stub UserInfo API call:
      # https://developers.tiktok.com/doc/tiktok-api-v2-get-user-info/
      stub_request(:get, "https://open.tiktokapis.com/v2/user/info/?fields=open_id,avatar_url,avatar_url_100,display_name")
        .with(
          headers: {
            "Accept" => "*/*",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "Authorization" => "Bearer act.example12345Example12345Example"
          }
        )
        .to_return(
          status: 200,
          body: {
            "data" => {
              "user" => {
                "open_id" => "afd97af1-b87b-48b9-ac98-410aghda5344",
                "avatar_url" => "https://example.com/avatar.jpg",
                "avatar_url_100" => "https://example.com/avatar_100.jpg",
                "display_name" => "example"
              }
            }
          }.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )
    end

    it "calls the callback with the access token" do
      status, = subject.call!(env)
      expect(status).to eq(200)
      expect(env.fetch("omniauth.auth")).to include(
        "provider" => "tiktok-loginkit",
        "uid" => "afd97af1-b87b-48b9-ac98-410aghda5344",
        "info" => {
          "name" => "example",
          "image" => "https://example.com/avatar_100.jpg"
        },
        "credentials" => include(
          "token" => "act.example12345Example12345Example",
          "refresh_token" => "rft.example12345Example12345Example",
          "expires" => true
        ),
        "extra" => {
          "avatar_url" => "https://example.com/avatar.jpg",
          "avatar_url_100" => "https://example.com/avatar_100.jpg",
          "display_name" => "example",
          "open_id" => "afd97af1-b87b-48b9-ac98-410aghda5344"
        }
      )
    end
  end

  context "callback phase with skip_info" do # rubocop:disable Metrics/BlockLength
    before do
      subject.options[:skip_info] = true
    end

    let(:env) do
      Rack::MockRequest.env_for(
        "http://localhost:3000/auth/tiktok-loginkit/callback?code=CODE&state=STATE&scopes=user.info.basic"
      )
    end

    before do # rubocop:disable Metrics/BlockLength
      session["omniauth.state"] = "STATE"

      # stub AccessToken API call:
      # https://developers.tiktok.com/doc/oauth-user-access-token-management/
      stub_request(:post, "https://open.tiktokapis.com/v2/oauth/token/")
        .with(
          body: {
            "client_key" => "CLIENT_KEY",
            "client_secret" => "CLIENT_SECRET",
            "code" => "CODE",
            "grant_type" => "authorization_code",
            "redirect_uri" => "http://localhost:3000/auth/tiktok-loginkit/callback"
          }
        )
        .to_return(
          status: 200,
          body: {
            "access_token": "act.example12345Example12345Example",
            "expires_in": 86_400,
            "open_id": "afd97af1-b87b-48b9-ac98-410aghda5344",
            "refresh_expires_in": 31_536_000,
            "refresh_token": "rft.example12345Example12345Example",
            "scope": "user.info.basic",
            "token_type": "Bearer"
          }.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )
    end

    it "calls the callback with the access token" do
      status, = subject.call!(env)
      expect(status).to eq(200)
      expect(env.fetch("omniauth.auth")).to include(
        "provider" => "tiktok-loginkit",
        "uid" => "afd97af1-b87b-48b9-ac98-410aghda5344",
        "credentials" => include(
          "token" => "act.example12345Example12345Example",
          "refresh_token" => "rft.example12345Example12345Example",
          "expires" => true
        ),
        "extra" => {}
      )
    end
  end

  context "callback phase with user.info.profile scope" do # rubocop:disable Metrics/BlockLength
    let(:env) do
      Rack::MockRequest.env_for(
        "http://localhost:3000/auth/tiktok-loginkit/callback?code=CODE&state=STATE&scopes=user.info.basic,user.info.profile"
      )
    end

    before do # rubocop:disable Metrics/BlockLength
      session["omniauth.state"] = "STATE"

      # stub AccessToken API call:
      # https://developers.tiktok.com/doc/oauth-user-access-token-management/
      stub_request(:post, "https://open.tiktokapis.com/v2/oauth/token/")
        .with(
          body: {
            "client_key" => "CLIENT_KEY",
            "client_secret" => "CLIENT_SECRET",
            "code" => "CODE",
            "grant_type" => "authorization_code",
            "redirect_uri" => "http://localhost:3000/auth/tiktok-loginkit/callback"
          }
        )
        .to_return(
          status: 200,
          body: {
            "access_token": "act.example12345Example12345Example",
            "expires_in": 86_400,
            "open_id": "afd97af1-b87b-48b9-ac98-410aghda5344",
            "refresh_expires_in": 31_536_000,
            "refresh_token": "rft.example12345Example12345Example",
            "scope": "user.info.basic",
            "token_type": "Bearer"
          }.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )

      # stub UserInfo API call:
      # https://developers.tiktok.com/doc/tiktok-api-v2-get-user-info/
      stub_request(:get, "https://open.tiktokapis.com/v2/user/info/?fields=open_id,avatar_url,avatar_url_100,display_name,profile_web_link,profile_deep_link,bio_description,is_verified,username")
        .with(
          headers: {
            "Accept" => "*/*",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "Authorization" => "Bearer act.example12345Example12345Example"
          }
        )
        .to_return(
          status: 200,
          body: {
            "data" => {
              "user" => {
                "open_id" => "afd97af1-b87b-48b9-ac98-410aghda5344",
                "avatar_url" => "https://example.com/avatar.jpg",
                "avatar_url_100" => "https://example.com/avatar_100.jpg",
                "display_name" => "example",
                "profile_web_link" => "https://example.com/profile",
                "profile_deep_link" => "https://example.com/profile/deep",
                "bio_description" => "example bio",
                "is_verified" => true,
                "username" => "example"
              }
            }
          }.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )
    end

    it "calls the callback with the access token" do # rubocop:disable Metrics/BlockLength
      status, = subject.call!(env)
      expect(status).to eq(200)
      expect(env.fetch("omniauth.auth")).to include(
        "provider" => "tiktok-loginkit",
        "uid" => "afd97af1-b87b-48b9-ac98-410aghda5344",
        "info" => {
          "name" => "example",
          "image" => "https://example.com/avatar_100.jpg",
          "nickname" => "example",
          "description" => "example bio",
          "urls" => {
            "TikTok" => "https://example.com/profile",
            "TikTok Deep Link" => "https://example.com/profile/deep"
          }
        },
        "credentials" => include(
          "token" => "act.example12345Example12345Example",
          "refresh_token" => "rft.example12345Example12345Example",
          "expires" => true
        ),
        "extra" => {
          "avatar_url" => "https://example.com/avatar.jpg",
          "avatar_url_100" => "https://example.com/avatar_100.jpg",
          "display_name" => "example",
          "open_id" => "afd97af1-b87b-48b9-ac98-410aghda5344",
          "profile_web_link" => "https://example.com/profile",
          "profile_deep_link" => "https://example.com/profile/deep",
          "bio_description" => "example bio",
          "is_verified" => true,
          "username" => "example"
        }
      )
    end
  end
end
