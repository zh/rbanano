# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware'

module Banano
  class Client
    LOCAL_ENDPOINT = 'http://localhost:7072'
    DEFAULT_TIMEOUT = 30

    attr_accessor :uri, :timeout

    def initialize(uri: LOCAL_ENDPOINT, timeout: DEFAULT_TIMEOUT)
      @conn = Faraday.new(uri) do |builder|
        builder.adapter Faraday.default_adapter
        builder.request :url_encoded
        builder.options[:open_timeout] = 5
        builder.options[:timeout] = timeout
        builder.headers['Content-Type'] = 'application/json'
        builder.headers['User-Agent'] = 'Banano RPC Client'
        builder.response :json, content_type: 'application/json'
      end
    end

    def rpc_call(action:, params: {})
      data = {action: action}.merge(params)
      response = @conn.post do |req|
        req.body = JSON.dump(data)
      end
      Util.symbolize_keys(response.body)
    end
  end
end
