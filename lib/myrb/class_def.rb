# frozen_string_literal: true

module Myrb
  class ClassDef < ModuleDef
    attr_reader :type, :super_type

    def initialize(type, super_type)
      super(type)
      @super_type = super_type
    end

    def inspect(indent = 0)
      return super() if Myrb.debug?
      str = type.const.to_ruby.dup

      if type.has_args?
        type_args = type.type_args.map { |arg| arg.to_ruby }.join(', ')
        str << "[#{type_args}]"
      end

      str
    end

    def accept(visitor, level, &block)
      visitor.visit_class_def(self, level)
    end
  end
end
