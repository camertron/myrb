# frozen_string_literal: true

require "forwardable"

module Myrb
  class Endable < Scope
    extend Forwardable

    def_delegators :@parent_scope, :method_defs, :scopes, :attrs, :ivars, :mixins

    def initialize(parent_scope)
      @parent_scope = parent_scope

      super(UntypedType.new)
    end
  end
end
