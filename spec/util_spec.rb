# frozen_string_literal: true

module Banano
  RSpec.describe Util do
    let(:hash) do
      {
        "data" => "info",
        "deep": {
          "inside": {
            "key1": "value1",
            "key2": {
              "key2_1": "value2_1",
              "key2_2": "value2_2"
            }
          }
        }
      }
    end

    it 'should not throw error on empty hash' do
      expect { Util.symbolize_keys({}) }.to_not raise_exception
      expect { Util.symbolize_keys('{}') }.to_not raise_exception
    end

    it 'should work with JSON as string' do
      expect(Util.symbolize_keys(JSON.generate(hash))).to include({data: 'info',
                                                    deep: {
                                                      inside: {
                                                        key1: 'value1',
                                                        key2: {
                                                          key2_1: 'value2_1',
                                                          key2_2: 'value2_2'
                                                        }
                                                      }
                                                    }})
    end

    it 'should deep symbolize Hash keys' do
      expect(Util.symbolize_keys(hash)).to include({data: 'info',
                                                    deep: {
                                                      inside: {
                                                        key1: 'value1',
                                                        key2: {
                                                          key2_1: 'value2_1',
                                                          key2_2: 'value2_2'
                                                        }
                                                      }
                                                    }})
    end
  end
end
