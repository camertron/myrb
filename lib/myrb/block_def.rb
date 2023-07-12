# frozen_string_literal: true

require "singleton"

module Myrb
  class BlockDef < Scope
    include Singleton

    def initialize
      super(BlockType.new(nil, [], UntypedType.new))
    end
  end
end
