# frozen_string_literal: true

module Vkontakte
  # Make Vkontakte API requests
  #
  # https://vk.ru/dev/api_requests
  #
  class API
    attr_reader :access_token, :proxy, :api_version, :timeout, :adapter
    attr_accessor :lang

    def initialize(
      access_token = nil,
      proxy: nil,
      api_version: Vkontakte::API_VERSION,
      lang: 'ru',
      timeout: 60,
      adapter: Faraday.default_adapter
    )
      @access_token = access_token
      @proxy = proxy
      @api_version = api_version
      @lang = lang
      @timeout = timeout
      @adapter = adapter
    end

    def method_missing(method, *params)
      method_name = method.to_s.split('_').join('.')
      response = execute(method_name, *params)
      if response['error']
        error_code = response['error']['error_code']
        error_msg  = response['error']['error_msg']
        raise Vkontakte::API::Error.new(method_name, error_code, error_msg, params)
      end

      response['response']
    end

    private

    def execute(method_name, params = {})
      params.merge!(access_token: @access_token, lang: @lang, v: @api_version, https: '1')

      url = "https://api.#{Vkontakte::BASE_DOMAIN}/method/#{method_name}"

      response = make_request(url, params)

      JSON.parse(response.body)
    end

    def make_request(url, params)
      connection.post(url, params)
    end

    def connection
      @connection ||= Faraday.new do |builder|
        builder.proxy = proxy_options
        builder.options.open_timeout = timeout
        builder.options.timeout = timeout
        builder.options.params_encoder = Faraday::FlatParamsEncoder
        builder.request :url_encoded
        builder.adapter adapter
      end
    end

    def proxy_options
      return unless proxy

      scheme = proxy.socks? ? 'socks5h' : proxy.type.to_s
      {
        uri: URI::Generic.build(scheme: scheme, host: proxy.addr, port: proxy.port),
        user: proxy.user,
        password: proxy.password
      }
    end
  end
end
