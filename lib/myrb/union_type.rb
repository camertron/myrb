# frozen_string_literal: true

module Myrb
  class UnionType < Annotation
    attr_reader :types, :loc, :nilable

    alias nilable? nilable

    def initialize(types, loc, nilable)
      @types = types
      @loc = loc
      @nilable = nilable
    end

    def sig
      "T.any(#{types.map(&:sig).join(', ')})"
    end

    def accept(visitor, level)
      visitor.visit_union_type(self, level)
    end

    def inspect(indent = 0)
      return super() if Myrb.debug?
      result = types.map(&:inspect).join(' | ')

      if nilable?
        result = "(#{result})?"
      end

      result
    end
  end
end
