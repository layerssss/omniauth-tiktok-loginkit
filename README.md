# omniauth-tiktok-loginkit

[![rspec](https://github.com/layerssss/omniauth-tiktok-loginkit/actions/workflows/rspec.yml/badge.svg)](https://github.com/layerssss/omniauth-tiktok-loginkit/actions/workflows/rspec.yml)
[![rubocop](https://github.com/layerssss/omniauth-tiktok-loginkit/actions/workflows/rubocop.yml/badge.svg)](https://github.com/layerssss/omniauth-tiktok-loginkit/actions/workflows/rubocop.yml)
[![Gem Version](https://badge.fury.io/rb/omniauth-tiktok-loginkit.svg)](https://badge.fury.io/rb/omniauth-tiktok-loginkit)

OmniAuth Strategy for TikTok [LoginKit](https://developers.tiktok.com/doc/login-kit-overview/)

Using TikTok Oauth API v2.

## Config

```
gem "omniauth-tiktok-loginkit"
```

Configure with CLIENT_KEY and CLIENT_SECRET from TikTok Developers Portal (https://developers.tiktok.com/apps/). Note CLIENT_KEY is the value of "Client Key" field, not "App ID" on the portal.

TikTok requires apps to be approved by review before it can access any APIs, including the Oauth APIs. Also any configuration change to the app will cause it to be back in "Staging" status. So please configure all neccessary "Redirect URI" correctly before submitting a review.

TikTok also rejects any "Test App", so it's better to configure test / dev environment redirect URI on the production app.

```
Rails.application.config.middleware.use OmniAuth::Builder do
    provider(
        :tiktok_loginkit, 
        CLIENT_KEY, 
        CLIENT_SECRET,
        *options
    )
end
```

...Or with devise (https://github.com/heartcombo/devise#omniauth)

```
# config/initializers/devise.rb
config.omniauth(
    :tiktok_loginkit, 
    CLIENT_KEY, 
    CLIENT_SECRET, 
    ...options
)

```

## Options

* `name`: change endpoint to /auth/tiktok_another, /auth/tiktok_another/callback. default: `"tiktok_login"`
* `skip_info`: skip User Info API call to retrieve `info` hash. default: `false`
* `scope`: oauth scopes, seperated by comma. default: `"user.info.basic"`


## Usage

Example of `request.env["omniauth.auth"]` can be found in the specs:

* [with default scope: user.info.basic](https://github.com/layerssss/omniauth-tiktok-loginkit/blob/main/spec/omniauth/strategies/tiktok_loginkit_spec.rb#L108)
* [more detailed user info with scopes: user.info.basic,user.info.profile](https://github.com/layerssss/omniauth-tiktok-loginkit/blob/main/spec/omniauth/strategies/tiktok_loginkit_spec.rb#L263)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).