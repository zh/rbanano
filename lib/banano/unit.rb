# frozen_string_literal: true

require 'bigdecimal'

module Banano
  class Unit
    # Constant used to convert back and forth between raw and banano
    STEP = BigDecimal(10)**29
    TOTAL = (BigDecimal(2)**128 - 1).to_i

    # Converts an amount of banano to an amount of raw.
    #
    # @param banano [Float|Integer] amount in banano
    # @return [Integer] amount in raw
    def self.ban_to_raw(banano)
      return 0 unless banano.is_a?(Numeric) && banano > 0

      result = (banano * STEP).to_i
      return 0 if result > TOTAL

      result
    end

    # Converts an amount of raw to an amount of banano
    #
    # @param raw [BigDecimal|String] amount in raw
    # @return [Float|Integer] amount in banano
    def self.raw_to_ban(raw)
      return 0 unless raw.is_a?(BigDecimal) || raw.is_a?(String)

      begin
        value = raw.is_a?(String) ? BigDecimal(raw) : raw
        return 0 if value < 1.0 || value > TOTAL

        value / STEP
      rescue ArgumentError
        0
      end
    end
  end
end
