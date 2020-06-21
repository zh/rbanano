# frozen_string_literal: true

module Banano
  class Util
    class << self
      def symbolize_keys(hash)
        return {} if hash.empty?

        converted = hash.is_a?(String) ? JSON.parse(hash) : hash
        converted.inject({}) do |result, (key, value)|
          new_key = case key
                    when String then key.to_sym
                    else key
                    end
          new_value = case value
                      when Hash then symbolize_keys(value)
                      else value
                      end
          result[new_key] = new_value
          result
        end
      end
    end
  end
end
