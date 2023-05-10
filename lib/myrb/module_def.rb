# frozen_string_literal: true

module Myrb
  class ModuleDef < Scope
    def to_rbi(level)
      ''.tap do |result|
        result << indent("module #{type.to_ruby}\n", level)
        result << super(level + 1)
        result << indent("end\n", level)
      end
    end

    def accept(visitor, level)
      visitor.visit_module_def(self, level)
    end

    def inspect(indent = 0)
      type.to_ruby
    end
  end
end
