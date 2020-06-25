# frozen_string_literal: true

module Banano
  # The <tt>Banano::Block</tt> class contains methods to discover
  # publicly-available information about blocks on the nano network.
  #
  # A block is represented by a unique id like this:
  #
  #   "FBF8B0E6623A31AB528EBD839EEAA91CAFD25C12294C46754E45FD017F7939EB"
  #
  class Block
    def initialize(node:, block:)
      @node = node
      @block = block
      block_required! # All methods expect a block
    end

    # Returns the {Banano::Account} of the block.
    #
    # ==== Example:
    #   block.account # => Banano::Account
    #
    # @return [Banano::Account] the account of the block
    def account
      address = rpc(action: :block_account, param_name: :hash)[:account]
      Banano::Account.new(node: @node, address: address)
    end

    # Stop generating work for a block.
    #
    # ==== Example:
    #
    #   block.cancel_work # => true
    #
    # @return [Boolean] signalling if the action was successful
    def cancel_work
      rpc(action: :work_cancel, param_name: :hash).empty?
    end

    # Returns a consecutive list of block hashes in the account chain
    # starting at block back to count (direction from frontier back to
    # open block, from newer blocks to older). Will list all blocks back
    # to the open block of this chain when count is set to "-1".
    # The requested block hash is included in the answer.
    #
    # See also #successors.
    #
    # ==== Example:
    #
    #   block.chain(limit: 2)
    #
    # @param limit [Integer] maximum number of block hashes to return (default is 1000)
    # @param offset [Integer] return the account chain block hashes offset by
    #                         the specified number of blocks (default is 0)
    def chain(limit: 1000, offset: 0)
      params = {count: limit, offset: offset}
      rpc(action: :chain, param_name: :block, params: params)[:blocks]
    end
    alias ancestors chain

    # Request confirmation for a block from online representative nodes.
    # Will return immediately with a boolean to indicate if the request for
    # confirmation was successful. Note that this boolean does not indicate
    # the confirmation status of the block.
    #
    # ==== Example:
    #   block.confirm # => true
    #
    # @return [Boolean] if the confirmation request was sent successful
    def confirm
      rpc(action: :block_confirm, param_name: :hash)[:started] == '1'
    end

    # This call is for internal diagnostics/debug purposes only. Do not
    # rely on this interface being stable and do not use in a production system.
    #
    # Check if the block appears in the list of recently confirmed blocks by
    # online representatives.
    #
    # This method can work in conjunction with {Banano::Block#confirm},
    # whereby you can send any block (old or new) out to online representatives to
    # confirm. The confirmation process can take up to a couple of minutes.
    #
    # The method returning +false+ can indicate that the block is still in the process of being
    # confirmed and that you should call the method again soon, or that it
    # was confirmed earlier than the list available in {Banano::Node#confirmation_history},
    # or that it was not confirmed.
    #
    # ==== Example:
    #   block.confirmed_recently? # => true
    #
    # @return [Boolean] +true+ if the block has been recently confirmed by
    #   online representatives.
    def confirmed_recently?
      @node.rpc(action: :confirmation_history)[:confirmations].map do |h|
        h[:hash]
      end.include?(@block)
    end
    alias recently_confirmed? confirmed_recently?

    # Generate work for a block.
    #
    # ==== Example:
    #   block.generate_work # => "2bf29ef00786a6bc"
    #
    # @param use_peers [Boolean] if set to +true+, then the node will query
    #   its work peers (if it has any, see {Banano::WorkPeer#list}).
    #   When +false+, the node will only generate work locally (default is +false+)
    # @return [String] the work id of the work completed.
    def generate_work(use_peers: false)
      rpc(action: :work_generate, param_name: :hash, params: {use_peers: use_peers})[:work]
    end

    # Returns Array of Hashes containing information about a chain of
    # send/receive blocks, starting from this block.
    #
    # ==== Example:
    #
    #   block.history(limit: 1)
    #
    # @param limit [Integer] maximum number of send/receive block hashes
    #   to return in the chain (default is 1000)
    def history(limit: 1000)
      response = rpc(action: :history, param_name: :hash, params: {count: limit})
      response[:history].collect {|entry| Banano::Util.symbolize_keys(entry) }
    end

    # Returns the block hash id.
    #
    # ==== Example:
    #
    #   block.id #=> "FBF8B0E..."
    #
    # @return [String] the block hash id
    def id
      @block
    end

    # Returns a Hash of information about the block.
    #
    # ==== Examples:
    #
    #   block.info
    #   block.info(allow_unchecked: true)
    #
    # @param allow_unchecked [Boolean] (default is +false+). If +true+,
    #   information can be returned about blocks that are unchecked (unverified).
    def info(allow_unchecked: false)
      if allow_unchecked
        response = rpc(action: :unchecked_get, param_name: :hash)
        return _parse_info_response(response) unless response.key?(:error)
        # If unchecked not found, continue to checked block
      end

      response = rpc(action: :block, param_name: :hash)
      _parse_info_response(response)
    end

    # ==== Example:
    #
    #   block.is_valid_work?("2bf29ef00786a6bc") # => true
    #
    # @param work [String] the work id to check is valid
    # @return [Boolean] signalling if work is valid for the block
    def is_valid_work?(work)
      response = rpc(action: :work_validate, param_name: :hash, params: {work: work})
      !response.empty? && response[:valid] == '1'
    end

    # Republish blocks starting at this block up the account chain
    # back to the nano network.
    #
    # @return [Array<String>] block hashes that were republished
    #
    # ==== Example:
    #
    #   block.republish
    #
    def republish(destinations: nil, sources: nil)
      if !destinations.nil? && !sources.nil?
        raise ArgumentError, "Either destinations or sources but not both"
      end

      # Add in optional arguments
      params = {}
      params[:destinations] = destinations unless destinations.nil?
      params[:sources] = sources unless sources.nil?
      params[:count] = 1 unless params.empty?

      rpc(action: :republish, param_name: :hash, params: params)[:blocks]
    end

    # ==== Example:
    #
    #   block.pending? #=> false
    #
    # @return [Boolean] signalling if the block is a pending block.
    def pending?
      response = rpc(action: :pending_exists, param_name: :hash)
      !response.empty? && response[:exists] == '1'
    end

    # Publish the block to the banano network.
    #
    # Note, if block has previously been published, use #republish instead.
    #
    # ==== Examples:
    #
    #   block.publish # => "FBF8B0E..."
    #
    # @param [String] subtype: 'send', 'receive', 'open', 'epoch' etc.
    # @return [String] the block hash, or false.
    def publish(subtype = '')
      json_rpc(action: :process, params: {subtype: subtype})
    end
    alias process publish

    # Returns an Array of block hashes in the account chain ending at
    # this block.
    #
    # See also #chain.
    #
    # ==== Example:
    #
    #   block.successors
    #
    # @param limit [Integer] maximum number of send/receive block hashes
    #   to return in the chain (default is 1000)
    # @param offset [Integer] return the account chain block hashes offset
    #   by the specified number of blocks (default is 0)
    # @return [Array<String>] block hashes in the account chain ending at this block
    def successors(limit: 1000, offset: 0)
      params = {count: limit, offset: offset}
      rpc(action: :successors, param_name: :block, params: params)[:blocks]
    end

    private

    # Some RPC calls expect the param that represents the block to be named
    # "hash", and others "block".
    # The param_name argument allows us to specify which it should be for this call.
    def rpc(action:, param_name:, params: {})
      p = @block.nil? ? {} : {param_name.to_sym => @block}
      @node.rpc(action: action, params: p.merge(params))
    end

    # Special RPC - publish require {block: block.info} parameter
    def json_rpc(action:, params: {})
      p = {block: JSON.dump(info), json_block: true}
      @node.rpc(action: action, params: p.merge(params))
    end

    def block_required!
      raise ArgumentError, "Block must be present" if @block.nil?
    end
  end
end
