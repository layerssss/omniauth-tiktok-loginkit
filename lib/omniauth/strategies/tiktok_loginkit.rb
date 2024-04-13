# frozen_string_literal: true

require "oauth2"
require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class TiktokLoginkit < OmniAuth::Strategies::OAuth2 # rubocop:disable Style/Documentation
      class AccessToken < ::OAuth2::AccessToken
      end

      class NoAuthorizationCodeError < StandardError; end
      USER_INFO_URL = "https://open.tiktokapis.com/v2/user/info/"

      option :name, "tiktok-loginkit"
      args %i[client_key client_secret]

      option :client_options, {
        site: "https://www.tiktok.com",
        authorize_url: "https://www.tiktok.com/v2/auth/authorize/",
        token_url: "https://open.tiktokapis.com/v2/oauth/token/",
        auth_scheme: :request_body,
        access_token_class: OmniAuth::Strategies::TiktokLoginkit::AccessToken
      }
      option "scope", "user.info.basic"

      uid { access_token.params.fetch("open_id") }

      info do
        {
          name: user_info.fetch("display_name"),
          image: user_info.fetch("avatar_url_100")
        }
      end

      extra do
        user_info
      end

      def authorize_params
        super.tap do |params|
          # params[:scope] ||= DEFAULT_SCOPE
          params[:client_key] = options.client_key
        end
      end

      def token_params
        super.tap do |params|
          params[:client_key] = options.client_key
          params[:client_secret] = options.client_secret
        end
      end

      def callback_url
        full_host + callback_path
      end

      private

      def user_info # rubocop:disable Metrics/MethodLength
        return if skip_info?

        @user_info ||= begin
          fields = %w[open_id avatar_url avatar_url_100 display_name]
          if options.scope.include?("user.info.profile")
            fields.push("profile_web_link", "profile_deep_link", "bio_description", "is_verified")
          end
          response = access_token
                     .get(
                       USER_INFO_URL,
                       params: {
                         fields: fields.join(",")
                       }
                     )
                     .parsed
          response.fetch("data").fetch("user")
        end
      end
    end
  end
end
