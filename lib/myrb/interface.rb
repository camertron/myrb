# frozen_string_literal: true

module Myrb
  class Interface < Annotation
    attr_reader :name, :definition, :loc

    def initialize(name, definition, loc)
      @name = name
      @definition = definition
      @loc = loc
    end

    def accept(visitor, level)
      visitor.visit_interface(self, level)
    end
  end
end
