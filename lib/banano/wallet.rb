# frozen_string_literal: true

# The <tt>Banano::Wallet</tt> class lets you manage your banano wallets,
# as well as some account-specific things like making and receiving payments.
#
# === Wallet seeds vs ids
#
# Your wallets each have an id as well as a seed. Both are 32-byte uppercase hex
# strings that look like this:
#
#   000D1BAEC8EC208142C99059B393051BAC8380F9B5A2E6B2489A277D81789F3F
#
# This class uses wallet _ids_ to identify your wallet. A wallet id only
# exists locally on the banano node that it was created on. The person
# who knows this id can only perform all read and write actions against
# the wallet and all accounts inside the wallet from the same banano node
# that it was created on. This makes wallet ids fairly safe to use as a
# person needs to know your wallet id as well as have access to run
# RPC commands against your banano node to be able to control your accounts.
#
# A _seed_ on the other hand can be used to link any wallet to another
# wallet's accounts, from anywhere in the banano network. This happens
# by setting a wallet's seed to be the same as a previous wallet's seed.
# When a wallet has the same seed as another wallet, any accounts
# created in the second wallet will be the same accounts as those that were
# created in the previous wallet, and the new wallet's owner will
# also gain ownership of the previous wallet's accounts. Note, that the
# two wallets will have different ids, but the same seed.
#

module Banano
  class Wallet
    attr_reader :node

    def initialize(node:, wallet: nil)
      @node = node
      @wallet = wallet
    end

    # Changes a wallet's seed.
    #
    # It's recommended to only change the seed of a wallet that contains
    # no accounts.
    #
    # ==== Example:
    #
    #   wallet.change_seed("000D1BA...") # => true
    #
    # @param seed [String] the seed to change to.
    # @return [Boolean] indicating whether the change was successful.
    def change_seed(seed)
      wallet_required!
      rpc(action: :wallet_change_seed, params: {seed: seed}).key?(:success)
    end

    # Returns the given account in the wallet as a {Banano::WalletAccount} instance
    # to let you start working with it.
    #
    # Call with no +account+ argument if you wish to create a new account
    # in the wallet, like this:
    #
    #   wallet.account.create     # => Banano::WalletAccount
    #
    # See {Banano::WalletAccount} for all the methods you can call on the
    # account object returned.
    #
    # ==== Examples:
    #
    #   wallet.account("nano_...") # => Banano::WalletAccount
    #   wallet.account.create     # => Banano::WalletAccount
    #
    # @param [String] account optional String of an account (starting with
    #   <tt>"ban_..."</tt>) to start working with. Must be an account within
    #   the wallet. When no account is given, the instance returned only
    #   allows you to call +create+ on it, to create a new account.
    # @raise [ArgumentError] if the wallet does no contain the account
    # @return [Banano::WalletAccount]
    def account(account = nil)
      Banano::WalletAccount.new(node: @node, wallet: @wallet, account: account)
    end

    # Array of {Banano::WalletAccount} instances of accounts in the wallet.
    #
    # ==== Example:
    #
    #   wallet.accounts # => [Banano::WalletAccount, Banano::WalletAccount...]
    #
    # @return [Array<Banano::WalletAccount>] all accounts in the wallet
    def accounts
      wallet_required!
      rpc(action: :account_list)[:accounts]
    end

    # Will return +true+ if the account exists in the wallet.
    #
    # ==== Example:
    #   wallet.contains?("ban_1...") # => true
    #
    # @param account [String] id (will start with <tt>"ban_..."</tt>)
    # @return [Boolean] indicating if the wallet contains the given account
    # TODO: account address validation - Maybe Banano::Address ....
    def contains?(account)
      wallet_required!
      response = rpc(action: :wallet_contains, params: {account: account})
      !response.empty? && response[:exists] == '1'
    end

    # Creates a new wallet.
    #
    # The wallet will be created only on this node. It's important that
    # if you intend to add funds to accounts in this wallet that you
    # backup the wallet *seed* in order to restore the wallet in future.
    #
    # ==== Example:
    #   Banano::Wallet.new.create # => Banano::Wallet
    #
    # @return [Banano::Wallet]
    def create
      @wallet = rpc(action: :wallet_create)[:wallet]
      self
    end

    # Destroys the wallet.
    #
    # ==== Example:
    #
    #   wallet.destroy # => true
    #
    # @return [Boolean] indicating success of the action
    def destroy
      wallet_required!
      rpc(action: :wallet_destroy)
      @wallet = nil
      true
    end

    # Generates a String containing a JSON representation of your wallet.
    #
    def export
      wallet_required!
      rpc(action: :wallet_export)[:json]
    end

    # The default representative account id for the wallet. This is the
    # representative that all new accounts created in this wallet will have.
    #
    # Changing the default representative for a wallet does not change
    # the representatives for any accounts that have been created.
    #
    # ==== Example:
    #
    #   wallet.default_representative # => "ban_3pc..."
    #
    # @return [String] Representative account of the account
    def default_representative
      rpc(action: :wallet_representative)[:representative]
    end
    alias representative default_representative

    # Sets the default representative for the wallet. A wallet's default
    # representative is the representative all new accounts created in
    # the wallet will have. Changing the default representative for a
    # wallet does not change the representatives for existing accounts
    # in the wallet.
    #
    # ==== Example:
    #
    #   wallet.change_default_representative("ban_...") # => "ban_..."
    #
    # @param [String] representative the id of the representative account
    #   to set as this account's representative
    # @return [String] the representative account id
    # @raise [ArgumentError] if the representative account does not exist
    # @raise [Banano::Error] if setting the representative fails
    def change_default_representative(representative)
      unless Banano::Account.new(node: @node, address: representative).exists?
        raise ArgumentError, "Representative account does not exist: #{representative}"
      end

      if rpc(action: :wallet_representative_set,
            params: {representative: representative})[:set] == '1'
        representative
      else
        raise Banano::Error, "Setting the representative failed"
      end
    end
    alias change_representative change_default_representative

    # @return [String] the wallet id
    def id
      @wallet
    end

    # Information about this wallet and all of its accounts.
    #
    # ==== Examples:
    #
    #   wallet.info
    #
    # @param raw [Boolean] if true return raw, else return ban units
    # @return [Hash{Symbol=>String|Array<Hash{Symbol=>String|Integer|Float}>}]
    # information about the wallet.
    def info
      wallet_required!
      rpc(action: :wallet_info)
    end

    # Locks the wallet. A locked wallet cannot pocket pending transactions or make payments.
    #
    # ==== Example:
    #
    #   wallet.lock #=> true
    #
    # @return [Boolean] indicates if the wallet was successfully locked
    def lock
      wallet_required!
      response = rpc(action: :wallet_lock)
      !response.empty? && response[:locked] == '1'
    end

    # Returns +true+ if the wallet is locked.
    #
    # ==== Example:
    #
    #   wallet.locked? #=> false
    #
    # @return [Boolean] indicates if the wallet is locked
    def locked?
      wallet_required!
      response = rpc(action: :wallet_locked)
      !response.empty? && response[:locked] != '0'
    end

    # Unlocks a previously locked wallet.
    #
    # ==== Example:
    #
    #   wallet.unlock("new_pass") #=> true
    #
    # @return [Boolean] indicates if the unlocking action was successful
    def unlock(password)
      wallet_required!
      rpc(action: :password_enter, params: {password: password})[:valid] == '1'
    end

    # Changes the password for a wallet.
    #
    # ==== Example:
    #
    #   wallet.change_password("new_pass") #=> true
    # @return [Boolean] indicates if the action was successful
    def change_password(password)
      wallet_required!
      rpc(action: :password_change, params: {password: password})[:changed] == '1'
    end

    # Balance of all accounts in the wallet, optionally breaking the balances down by account.
    #
    # ==== Examples:
    #   wallet.balance
    #
    # Example response:
    #
    #   {
    #     "balance"=>5,
    #     "pending"=>0.001
    #   }
    #
    # @param [Boolean] account_break_down (default is +false+). When +true+
    #  the response will contain balances per account.
    # @param raw [Boolean] raw or banano units
    #
    # @return [Hash{Symbol=>Integer|Float|Hash}]
    def balance(account_break_down: false, raw: true)
      wallet_required!

      if account_break_down
        response = rpc(action: :wallet_balances)[:balances].tap do |r|
          unless raw == true
            r.each do |account, _|
              r[account][:balance] = Banano::Unit.raw_to_ban(r[account][:balance]).to_f
              r[account][:pending] = Banano::Unit.raw_to_ban(r[account][:pending]).to_f
            end
          end
        end
        return response.collect {|k, v| [k.to_s, v] }.to_h
      end

      rpc(action: :wallet_balance_total).tap do |r|
        unless raw == true
          r[:balance] = Banano::Unit.raw_to_ban(r[:balance]).to_f
          r[:pending] = Banano::Unit.raw_to_ban(r[:pending]).to_f
        end
      end
    end

    # Makes a payment from an account in your wallet to another account
    # on the nano network.
    #
    # Note, there may be a delay in receiving a response due to Proof of
    # Work being done. From the {Nano RPC}[https://docs.nano.org/commands/rpc-protocol/#send]:
    #
    # <i>Proof of Work is precomputed for one transaction in the
    # background. If it has been a while since your last transaction it
    # will send instantly, the next one will need to wait for Proof of
    # Work to be generated.</i>
    #
    # @param from [String] account id of an account in your wallet
    # @param to (see Banano::WalletAccount#pay)
    # @param amount (see Banano::WalletAccount#pay)
    # @param raw [Boolean] raw or banano units
    # @params id (see Banano::WalletAccount#pay)
    #
    # @return (see Banano::WalletAccount#pay)
    # @raise [Banano::Error] if unsuccessful
    def pay(from:, to:, amount:, raw: true, id:)
      wallet_required!
      validate_wallet_contains_account!(from)
      # account(from) will return Banano::WalletAccount
      account(from).pay(to: to, amount: amount, raw: raw, id: id)
    end

    # Information about pending blocks (payments) that are waiting
    # to be received by accounts in this wallet.
    #
    # See also the {#receive} method of this class for how to receive a pending payment.
    #
    # @param limit [Integer] number of accounts with pending payments to return (default is 1000)
    # @param detailed [Boolean] return complex Hash of pending block info (default is +false+)
    # @param raw [Boolean] raw or banano units
    #
    # ==== Examples:
    #
    #   wallet.pending
    #
    def pending(limit: 1000, detailed: false, raw: true)
      wallet_required!
      params = {count: limit}
      params[:source] = true if detailed

      response = rpc(action: :wallet_pending, params: params)[:blocks]
      return response unless detailed && !response.empty?

      # Map the RPC response, which is:
      # account=>block=>[amount|source] into
      # account=>[block|amount|source]
      response.map do |account, data|
        new_data = data.map do |block, amount_and_source|
          d = amount_and_source.merge(block: block.to_s)
          d[:amount] = Banano::Unit.raw_to_ban(d[:amount]) unless raw == true
          d
        end

        [account, new_data]
      end
    end

    # Receives a pending payment into an account in the wallet.
    #
    # When called with no +block+ argument, the latest pending payment
    # for the account will be received.
    #
    # Returns a <i>receive</i> block hash id if a receive was successful,
    # or +false+ if there were no pending payments to receive.
    #
    # You can receive a specific pending block if you know it by
    # passing the block has in as an argument.
    # ==== Examples:
    #
    #   wallet.receive(into: "ban_..")               # => "9AE2311..."
    #   wallet.receive("718CC21...", into: "ban_..") # => "9AE2311..."
    #
    # @param block (see Banano::WalletAccount#receive)
    # @param into [String] account id of account in your wallet to receive the
    #   payment into
    #
    # @return (see Banano::WalletAccount#receive)
    def receive(block: nil, into:)
      wallet_required!
      validate_wallet_contains_account!(into)
      # account(into) will return Banano::WalletAccount
      account(into).receive(block)
    end

    # Restores a previously created wallet by its seed.
    # A new wallet will be created on your node (with a new wallet id)
    # and will have its seed set to the given seed.
    #
    # ==== Example:
    #
    #   Banano::Protocol.new.wallet.restore(seed: seed, accounts: 1) # => Banano::Wallet
    #
    # @param seed [String] the wallet seed to restore.
    # @param accounts [Integer] optionally restore the given number of accounts for the wallet.
    #
    # @return [Banano::Wallet] a new wallet
    # @raise [Banano::Error] if unsuccessful
    def restore(seed:, accounts: 0)
      create

      raise Banano::Error, "Unable to set seed for wallet" unless change_seed(seed)

      account.create(accounts) if accounts > 0
      self
    end

    def rpc(action:, params: {})
      p = @wallet.nil? ? {} : {wallet: @wallet}
      @node.rpc(action: action, params: p.merge(params))
    end

    def wallet_required!
      raise ArgumentError, "Wallet must be present" if @wallet.nil?
    end

    def validate_wallet_contains_account!(account)
      @known_valid_accounts ||= []
      return true if @known_valid_accounts.include?(account)

      if contains?(account)
        @known_valid_accounts << account
      else
        raise ArgumentError,
              "Account does not exist in wallet. Account: #{account}, wallet: #{@wallet}"
      end
    end
  end
end
