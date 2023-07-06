# frozen_string_literal: true

module Myrb
  class IVar < Annotation
    attr_reader :name, :parent_scope, :type, :loc

    def initialize(name, parent_scope, type, loc)
      @name = name
      @parent_scope = parent_scope
      @type = type
      @loc = loc
    end

    def accept(visitor, level)
      visitor.visit_ivar(self, level)
    end
  end
end
