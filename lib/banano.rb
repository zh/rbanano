# frozen_string_literal: true

Dir[File.dirname(__FILE__) + '/banano/*.rb'].each {|file| require file }

module Banano
  class Protocol
    attr_reader :node

    def initialize(uri: Client::LOCAL_ENDPOINT, timeout: Client::DEFAULT_TIMEOUT)
      @node = Node.new(uri: uri, timeout: timeout)
    end

    # Returns a new instance of {Banano::Account}.
    #
    # ==== Example:
    #   account = Banano::Protocol.new.account(address: "ban_3e3j...")
    #
    # @param address [String] the id of the account you want to work with
    # @return [Banano::Account]
    def account(address)
      Banano::Account.new(node: @node, address: address)
    end

    # Returns a new instance of {Banano::Block}.
    #
    # ==== Example:
    #   block = Banano::Protocol.new.block("FBF8B0E...")
    #
    # @param block [String] the id/hash of the block you want to work with
    # @return [Banano::Block]
    def block(block)
      Banano::Block.new(node: @node, block: block)
    end

    # Returns a new instance of {Banano::Key}.
    #
    # ==== Example:
    #   key = Banano::Protocol.new.key("3068BB...")
    #
    # @param key [String] a private key
    # @return [Banano::Key]
    def key(key = nil)
      Banano::Key.new(node: @node, key: key)
    end

    # Returns a new instance of {Banano::Wallet}.
    #
    # ==== Example:
    #   wallet = Banano::Protocol.new.wallet("000D1BAE...")
    #
    # @param wallet [String] the id of the wallet you want to work with
    # @return [Banano::Wallet]
    def wallet(wallet = nil)
      Banano::Wallet.new(node: @node, wallet: wallet)
    end
  end
end
