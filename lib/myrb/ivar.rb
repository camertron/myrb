# frozen_string_literal: true

module Myrb
  class IVar < Annotation
    attr_reader :name, :type, :loc

    def initialize(name, type, loc)
      @name = name
      @type = type
      @loc = loc
    end

    def accept(visitor, level)
      visitor.visit_ivar(self, level)
    end
  end
end
