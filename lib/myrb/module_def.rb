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
      return super() if Myrb.debug?
      type.to_ruby
    end

    def singleton_class_def
      @singleton_class_def ||= SingletonClassDef.new(self)
    end

    def has_singleton_class?
      @singleton_class_def != nil
    end

    def singleton?
      false
    end
  end
end
