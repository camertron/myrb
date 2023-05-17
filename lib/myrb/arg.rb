# frozen_string_literal: true

module Myrb
  class Arg < Annotation
    attr_reader :name, :type, :block_arg, :default_value_tokens, :loc

    alias block_arg? block_arg

    def initialize(name, type, block_arg, default_value_tokens, loc)
      @name = name
      @type = type
      @block_arg = block_arg
      @default_value_tokens = default_value_tokens
      @loc = loc
    end

    def to_ruby
      "#{block_arg ? '&' : ''}#{name}"
    end

    def sig
      sym_join(name, type.sig)
    end

    def accept(visitor, level)
      visitor.visit_arg(self, level)
    end

    def inspect(indent = 0)
      return super() if Myrb.debug?
      type.inspect
    end
  end
end
