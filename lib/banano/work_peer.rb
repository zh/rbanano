# frozen_string_literal: true

module Banano
  class WorkPeer
    def initialize(node)
      @node = node
    end

    def add(address:, port:)
      rpc(action: :work_peer_add, params: {address: address, port: port}).key?(:success)
    end

    def clear
      rpc(action: :work_peers_clear).key?(:success)
    end

    def list
      rpc(action: :work_peers)[:work_peers]
    end

    private

    def rpc(action:, params: {})
      @node.rpc(action: action, params: params)
    end
  end
end
