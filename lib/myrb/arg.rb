# frozen_string_literal: true

module Myrb
  class Arg < Annotation
    include TokenHelpers

    attr_reader :name, :type, :loc, :block_arg, :kwarg, :splat, :default_value_tokens

    alias block_arg? block_arg
    alias kwarg? kwarg
    alias splat? splat

    def initialize(name:, type:, loc:, block_arg:, kwarg:, splat:, default_value_tokens:)
      @name = name
      @type = type
      @loc = loc
      @block_arg = block_arg
      @kwarg = kwarg
      @splat = splat
      @default_value_tokens = default_value_tokens
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

      (+'').tap do |result|
        result << '&' if block_arg?
        result << '*' if splat?
        result << name if name
        result << ": #{type.inspect}"

        unless default_value_tokens.empty?
          result << " = #{default_value_string}"
        end
      end
    end

    def positional_arg?
      !kwarg? && !block_arg?
    end

    def default_value?
      !@default_value_tokens.empty?
    end

    def default_value_string
      range = pos_of(@default_value_tokens.first).with(
        end_pos: pos_of(@default_value_tokens.last).end_pos
      )

      range.source
    end
  end
end
