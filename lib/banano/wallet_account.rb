# frozen_string_literal: true

require 'forwardable'

# The <tt>Banano::WalletAccount</tt> class lets you manage
# your banano accounts, including making and receiving payments.
#
module Banano
  class WalletAccount
    extend Forwardable
    # @!method balance(raw: true)
    #   (see Banano::Account#balance)
    # @!method block_count
    #   (see Banano::Account#block_count)
    # @!method delegators(raw: true)
    #   (see Banano::Account#delegators)
    # @!method exists?
    #   (see Banano::Account#exists?)
    # @!method id
    #   (see Banano::Account#id)
    # @!method info((detailed: false, raw: true)
    #   (see Banano::Account#info)
    # @!method last_modified_at
    #   (see Banano::Account#last_modified_at)
    # @!method pending(limit: 1000, detailed: false, raw: true)
    #   (see Banano::Account#pending)
    # @!method public_key
    #   (see Banano::Account#public_key)
    # @!method history(limit: 1000, raw: true)
    #   (see Banano::Account#history)
    # @!method representative
    #   (see Banano::Account#representative)
    def_delegators :@banano_account_instance,
                   :balance,
                   :delegators,
                   :exists?,
                   :id,
                   :info,
                   :last_modified_at,
                   :pending,
                   :public_key,
                   :history,
                   :representative
    alias open? exists?

    def initialize(node:, wallet:, account: nil)
      @node = node
      @wallet = wallet
      @account = account
      @banano_account_instance = nil

      unless @account.nil?
        # Wallet must contain the account
        unless Banano::Wallet.new(node: @node, wallet: @wallet).contains?(@account)
          raise ArgumentError, "Account does not exist in wallet. Account: #{@account}, wallet: #{@wallet}"
        end

        # An object to delegate account methods that don't
        # expect a wallet param in the RPC call, to allow this
        # class to support all methods that can be called on Banano::Account
        @banano_account_instance = Banano::Account.new(node: @node, address: @account)
      end
    end

    # Creates a new account, or multiple new accounts, in this wallet.
    #
    # ==== Examples:
    #
    #   wallet_account.create     # => Banano::WalletAccount
    #   wallet_account.create(2)  # => [Banano::WalletAccount, Banano::WalletAccount]
    #
    # @param count [Integer] number of accounts to create
    #
    # @return [Banano::WalletAccount] returns a single {Banano::WalletAccount}
    #   if invoked with no argument
    # @return [Array<Banano::WalletAccount>] returns an Array of {Banano::WalletAccount}
    #   if method was called with argument +n+ >  1
    # @raise [ArgumentError] if +n+ is less than 1
    def create(count = 1)
      raise ArgumentError, "number of accounts must be greater than 0" if count < 1

      if count == 1
        Banano::WalletAccount.new(node: @node,
                                  wallet: @wallet,
                                  account: rpc(action: :account_create)[:account])
      else
        Array(rpc(action: :accounts_create, params: {count: count})[:accounts]).map do |account|
        Banano::WalletAccount.new(node: @node,
                                  wallet: @wallet,
                                  account: account)
        end
      end
    end

    # Unlinks the account from the wallet.
    #
    # ==== Example:
    #
    #   wallet_account.destroy # => true
    #
    # @return [Boolean] +true+ if action was successful, otherwise +false+
    def destroy
      rpc(action: :account_remove)[:removed] == '1'
    end

    # Makes a payment from this account to another account
    # on the banano network. Returns a <i>send</i> block hash
    # if successful, or a {Banano::Error} if unsuccessful.
    #
    # Note, there may be a delay in receiving a response due to Proof
    # of Work being done. <i>Proof of Work is precomputed for one transaction
    # in the background. If it has been a while since your last transaction
    # it will send instantly, the next one will need to wait for
    # Proof of Work to be generated.</i>
    #
    # @param to [String] account id of the recipient of your payment
    # @param amount [Integer|Float]
    # @param raw [Boolean] raw or banano units
    # @param id [String] must be unique per payment. It serves an important
    #   purpose; it allows you to make the same call multiple times with
    #   the same +id+ and be reassured that you will only ever send this
    #   nano payment once
    #
    # @return [String] the send block id for the payment
    # @raise [Banano::Error] if unsuccessful
    def pay(to:, amount:, raw: true, id:)
      # Check that to account is a valid address
      response = rpc(action: :validate_account_number, params: {account: to})
      raise ArgumentError, "Account address is invalid: #{to}" unless response[:valid] == '1'

      raw_amount = raw ? amount : Banano::Unit.ban_to_raw(amount)
      # account is called source, so don't use the normal rpc method
      p = {
        wallet: @wallet,
        source: @account,
        destination: to,
        amount: raw_amount,
        id: id
      }
      response = rpc(action: :send, params: p)
      return Banano::Error.new(response[:error]) if response.key?(:error)

      response[:block]
    end

    # Receives a pending payment for this account.
    #
    # When called with no +block+ argument, the latest pending payment
    # for the account will be received.
    #
    # Returns a <i>receive</i> block id
    # if a receive was successful, or +false+ if there were no pending
    # payments to receive.
    #
    # You can receive a specific pending block if you know it by
    # passing the block in as an argument.
    #
    # ==== Examples:
    #
    #   account.receive               # => "9AE2311..."
    #   account.receive("718CC21...") # => "9AE2311..."
    #
    # @param block [String] optional block id of pending payment. If
    #   not provided, the latest pending payment will be received
    #
    # @return [String] the receive block id
    # @return [false] if there was no block to receive
    def receive(block = nil)
      if block.nil?
        _receive_without_block
      else
        _receive_with_block(block)
      end
    end

    # Sets the representative for the account.
    #
    # A representative is an account that will vote on your account's
    # behalf on the nano network if your account is offline and there is
    # a fork of the network that requires voting on.
    #
    # Returns the <em>change block</em> that was
    # broadcast to the nano network. The block contains the information
    # about the representative change for your account.
    #
    # @param [String] representative the id of the representative account
    #   to set as this account's representative
    # @return [String] id of the <i>change</i> block created
    # @raise [ArgumentError] if the representative account does not exist
    def change_representative(representative)
      unless Banano::Account.new(node: @node, address: representative).exists?
        raise ArgumentError, "Representative account does not exist: #{representative}"
      end

      rpc(action: :account_representative_set,
          params: {representative: representative})[:block]
    end

    private

    def _receive_without_block
      # Discover the first pending block
      pending_blocks = rpc(action: :pending, params: {account: @account, count: 1})

      return false if pending_blocks[:blocks].empty?

      # Then call receive_with_block as normal
      _receive_with_block(pending_blocks[:blocks][0])
    end

    # Returns block if successful, otherwise false
    def _receive_with_block(block)
      response = rpc(action: :receive, params: {block: block})[:block]
      response.nil? ? false : response
    end

    def rpc(action:, params: {})
      p = {}
      return p unless @wallet

      p[:wallet] = @wallet
      p[:account] = @account unless @account.nil?

      @node.rpc(action: action, params: p.merge(params))
    end
  end
end
