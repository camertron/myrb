# frozen_string_literal: true

module Myrb
  class ConstAssgn < Annotation
    attr_reader :const, :type, :loc

    def initialize(const, type, loc)
      @const = const
      @type = type
      @loc = loc
    end

    def inspect(indent = 0)
      return super() if Myrb.debug?
      "#{const}: #{type.inspect}"
    end

    def accept(visitor, level)
      visitor.visit_const_assgn(self, level)
    end
  end
end
