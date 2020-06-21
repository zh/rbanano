# frozen_string_literal: true

module Banano
  RSpec.describe Node do
    it 'should return node info' do
      stub_request(:post, Client::LOCAL_ENDPOINT).with(
        body: {action: :version}.to_json,
        headers: headers
      ).to_return(
        status: 200,
        body: JSON.generate({a: 'b'}),
        headers: {}
      )

      Node.new.info
    end
  end
end
