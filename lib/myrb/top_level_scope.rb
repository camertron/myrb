# frozen_string_literal: true

module Myrb
  class TopLevelScope < Scope
    attr_accessor :type_sigil

    def initialize
      super('(toplevel)')
    end

    def accept(visitor, level)
      visitor.visit_top_level_scope(self, level)
    end

    def top_level_scope?
      true
    end
  end
end
