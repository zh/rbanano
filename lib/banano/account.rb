# frozen_string_literal: true

module Banano
  class Account
    attr_accessor :address

    def initialize(node:, address:)
      @node = node
      @address = address
    end

    # The last modified time of the account in the time zone of
    # your node (usually UTC).
    #
    # ==== Example:
    #
    #   account.last_modified_at # => Time
    #
    # @return [Time] last modified time of the account in the time zone of
    #   your nano node (usually UTC).
    def last_modified_at
      response = rpc(action: :account_info)
      Time.at(response[:modified_timestamp].to_i)
    end

    # The public key of the account.
    #
    # ==== Example:
    #
    #   account.public_key # => "3068BB1..."
    #
    # @return [String] public key of the account
    def public_key
      rpc(action: :account_key)[:key]
    end

    # The representative account id for the account.
    # Representatives are accounts that cast votes in the case of a
    # fork in the network.
    #
    # ==== Example:
    #
    #   account.representative # => "ban_3pc..."
    #
    # @return [String] Representative account of the account
    def representative
      rpc(action: :account_representative)[:representative]
    end

    # The account's balance, including pending (unreceived payments).
    # To receive a pending amount see {WalletAccount#receive}.
    #
    # ==== Examples:
    #
    #   account.balance
    #
    # Example response:
    #
    #   {
    #     balance: 2,
    #     pending: 1.1
    #   }
    #
    # @param raw [Boolean] if true raw, else banano units
    # @raise ArgumentError if an invalid +unit+ was given.
    # @return [Hash{Symbol=>Integer|Float}]
    def balance(raw = true)
      rpc(action: :account_balance).tap do |r|
        unless raw == true
          r[:balance] = Banano::Unit.raw_to_ban(r[:balance]).to_f
          r[:pending] = Banano::Unit.raw_to_ban(r[:pending]).to_f
        end
      end
    end

    # @return [Integer] number of blocks for this account
    def block_count
      rpc(action: :account_block_count)[:block_count].to_i
    end

    # Information about pending blocks (payments) that are
    # waiting to be received by the account.
    #
    # The default response is an Array of block ids.
    #
    # With the +detailed:+ argument, the method returns an Array of Hashes,
    # which contain the source account id, amount pending and block id.
    #
    # ==== Examples:
    #
    #   account.pending # => ["000D1BA..."]
    #
    # Asking for more detail to be returned:
    #
    #   account.pending(detailed: true)
    #
    # @param limit [Integer] number of pending blocks to return (default is 1000)
    # @param detailed [Boolean]return a more complex Hash of pending block information (default is +false+)
    # @param raw [Boolean] if true raw, else banano units
    #
    # @return [Array<String>]
    # @return [Array<Hash{Symbol=>String|Integer}>]
    def pending(limit: 1000, detailed: false, raw: true)
      params = {count: limit}
      params[:source] = true if detailed

      response = rpc(action: :wallet_pending, params: params)[:blocks]
      return response unless detailed && !response.empty?

      response.map do |key, val|
        p = val.merge(block: key.to_s)
        p[:amount] = Banano::Unit.raw_to_ban(p[:amount]).to_f unless raw == true
        p
      end
    end

    # The id of the account.
    #
    # ==== Example:
    #
    #   account.id # => "ban_16u..."
    #
    # @return [String] the id of the account
    def id
      @address
    end

    # Information about this accounts that have set this account as their representative.
    #
    # === Example:
    #
    #   account.delegators
    #
    # @param raw [Boolean] if true return raw balances, else banano units
    # @return [Hash{Symbol=>Integer}] account ids which delegate to this account
    def delegators(raw = true)
      response = rpc(action: :delegators)[:delegators]
      return response if raw == true

      r = response.map do |address, balance|
        [address.to_s, Banano::Unit.raw_to_ban(balance).to_f]
      end
      Hash[r]
    end

    # Information about the account.
    #
    # ==== Examples:
    #
    #   account.info
    #
    # @return [Hash{Symbol=>String|Integer|Float}] information about the account
    def info
      rpc(action: :account_info)
    end

    # Returns true if the account has an <i>open</i> block.
    #
    # An open block gets published when an account receives a payment
    # for the first time.
    #
    # ==== Example:
    #
    #   account.exists? # => true
    #   # or
    #   account.open?   # => true
    #
    # @return [Boolean] Indicates if this account has an open block
    def exists?
      response = info
      !response.empty? && !response[:open_block].nil?
    end
    alias open? exists?

    # An account's history of send and receive payments.
    #
    # ==== Example:
    #
    #   account.history
    #
    # @param limit [Integer] maximum number of history items to return
    # @param raw [Boolean] raw or banano
    # @return [Array<Hash{Symbol=>String}>] the history of send and receive payments for this account
    def history(limit: 1000, raw: true)
      response = Array(rpc(action: :account_history, params: {count: limit})[:history])
      response = response.collect {|h| Banano::Util.symbolize_keys(h) }
      return response if raw == true

      response.map! do |history|
        history[:amount] = Banano::Unit.raw_to_ban(history[:amount]).to_f
        history
      end
    end

    private

    def rpc(action:, params: {})
      p = @address.nil? ? {} : {account: @address}
      @node.rpc(action: action, params: p.merge(params))
    end
  end
end
