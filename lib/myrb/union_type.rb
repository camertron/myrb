# frozen_string_literal: true

module Myrb
  class UnionType < Annotation
    attr_reader :types, :loc

    def initialize(types, loc)
      @types = types
      @loc = loc
    end

    def sig
      "T.any(#{types.map(&:sig).join(', ')})"
    end

    def accept(visitor, level)
      visitor.visit_union_type(self, level)
    end

    def inspect(indent = 0)
      return super() if Myrb.debug?
      types.map(&:inspect).join(' | ')
    end
  end
end
