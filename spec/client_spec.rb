# frozen_string_literal: true

module Banano
  RSpec.describe Client do
    let(:local_uri) { Client::LOCAL_ENDPOINT }

    it 'should allow different RPC endpoints' do
      custom_uri = 'http://example.com:7072'

      stub_request(:post, custom_uri).with(
        body: {action: :block_info}.to_json,
        headers: headers
      ).to_return(
        status: 200,
        body: '{}',
        headers: {}
      )

      Client.new(uri: custom_uri).rpc_call(action: :block_info)
    end
  end
end
