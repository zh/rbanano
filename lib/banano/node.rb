# frozen_string_literal: true

module Banano
  class Node
    attr_reader :uri, :timeout

    def initialize(uri: Client::LOCAL_ENDPOINT, timeout: Client::DEFAULT_TIMEOUT)
      @client = Client.new(uri: uri, timeout: timeout)
    end

    def rpc(action:, params: {})
      @client.rpc_call(action: action, params: params)
    end

    # The number of accounts in the nano ledger--essentially all
    # accounts with _open_ blocks. An _open_ block
    # is the type of block written to the nano ledger when an account
    # receives its first payment (see {Nanook::WalletAccount#receive}). All accounts
    # that respond +true+ to {Nanook::Account#exists?} have open blocks in the ledger.
    #
    # @return [Integer] number of accounts with _open_ blocks.
    def account_count
      rpc(action: :frontier_count)[:count]
    end
    alias frontier_count account_count

    # The count of all blocks downloaded to the node, and
    # blocks still to be synchronized by the node.
    #
    # @return [Hash{Symbol=>Integer}] number of blocks and unchecked
    #   synchronizing blocks
    def block_count
      rpc(action: :block_count)
    end

    # The count of all known blocks by their type.
    #
    # @return [Hash{Symbol=>Integer}] number of blocks by type
    def block_count_by_type
      rpc(action: :block_count_type)
    end
    alias block_count_type block_count_by_type

    # TODO: add bootstrap methods

    # @return [Hash{Symbol=>String}] information about the node peers
    def peers
      h = -> (h) { Hash[h.map{ |k,v| [k.to_s, v] }] }
      h.call(rpc(action: :peers)[:peers])
    end

    # All representatives and their voting weight.
    #
    # @param raw [Boolean] if true return raw balances, else banano units
    # @return [Hash{Symbol=>Integer}] known representatives and their voting weight
    def representatives(raw = true)
      response = rpc(action: :representatives)[:representatives]
      response = response.delete_if {|_, balance| balance.to_s == '0' } # remove 0 balance reps
      return response if raw == true

      r = response.map do |address, balance|
        [address.to_s, Banano::Unit.raw_to_ban(balance).to_f]
      end
      Hash[r]
    end

    # All online representatives that have voted recently. Note, due to the
    # design of the nano RPC, this method cannot return the voting weight
    # of the representatives.
    #
    # ==== Example:
    #
    #   node.representatives_online # => ["ban_111...", "ban_311..."]
    #
    # @return [Array<String>] array of representative account ids
    def representatives_online
      rpc(action: :representatives_online)[:representatives]
    end
    alias reps_online representatives_online

    # @param limit [Integer] number of synchronizing blocks to return
    # @return [Hash{Symbol=>String}] information about the synchronizing blocks for this node
    def synchronizing_blocks(limit: 1000)
      response = rpc(action: :unchecked, params: {count: limit})[:blocks]
      # response = response.map do |block, info|
      #  [block, JSON.parse(info).to_symbolized_hash]
      # end
      # Hash[response.sort].to_symbolized_hash
      response
    end
    alias unchecked synchronizing_blocks

    # The percentage completeness of the synchronization process for
    # your node as it downloads the nano ledger. Note, it's normal for
    # your progress to not ever reach 100. The closer to 100, the more
    # complete your node's data is, and so the query methods in this class
    # become more reliable.
    #
    # @return [Float] the percentage completeness of the synchronization
    #   process for your node
    def sync_progress
      response = block_count

      count = response[:count].to_i
      unchecked = response[:unchecked].to_i
      total = count + unchecked

      count.to_f * 100 / total.to_f
    end

    # @return [Hash{Symbol=>Integer|String}] version information for this node
    def version
      rpc(action: :version)
    end
    alias info version
  end
end
