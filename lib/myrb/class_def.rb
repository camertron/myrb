# frozen_string_literal: true

module Myrb
  class ClassDef < Scope
    attr_reader :type, :super_type

    def initialize(type, super_type)
      super(type)
      @super_type = super_type
    end

    def to_rbs(level)
      ''.tap do |result|
        super_class = super_type ? " < #{super_type.to_ruby}" : ''
        result << indent("class #{type.to_ruby}#{super_class}\n", level)

        lines = []

        attr_ivars = ivars.select(&:attr?)
        unless attr_ivars.empty?
          lines << attr_ivars.map do |ivar|
            ivar.attrs.map { |a| a.to_rbs(level + 1) }.join("\n\n")
          end
        end

        result << lines.join("\n\n")
        result << indent("\nend\n", level)
      end
    end

    def inspect(indent = 0)
      str = type.const.to_ruby.dup

      unless type.args.empty?
        type_args = type.args.map { |arg| arg.to_ruby }.join(', ')
        str << "[#{type_args}]"
      end

      str << ')'
      str
    end

    def accept(visitor, level, &block)
      visitor.visit_class_def(self, level)
    end
  end
end