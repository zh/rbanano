# frozen_string_literal: true

module Banano
  class Key
    def initialize(node:, key: nil)
      @node = node
      @key = key
    end

    def generate(seed: nil, index: nil)
      if seed.nil? && index.nil?
        rpc(action: :key_create)
      elsif !seed.nil? && !index.nil?
        rpc(action: :deterministic_key, params: {seed: seed, index: index})
      else
        raise ArgumentError, "Method must be called with either seed AND index params"
      end
    end

    # Derive public key and account from private key
    def expand
      return {} if @key.nil?

      rpc(action: :key_expand, params: {key: @key})
    end

    def id
      @key
    end

    def info
      key_required!
      rpc(action: :key_expand)
    end

    private

    def rpc(action:, params: {})
      p = @key.nil? ? {} : {key: @key}
      @node.rpc(action: action, params: p.merge(params))
    end

    def key_required!
      raise ArgumentError, "Key must be present" if @key.nil?
    end
  end
end
