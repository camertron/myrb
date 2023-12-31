# frozen_string_literal: true

module Myrb
  class MethodDef < Annotation
    attr_reader :name, :parent_scope, :type_args, :args, :return_type, :loc, :method_defs

    def initialize(name, parent_scope, type_args, args, return_type, loc)
      @name = name
      @parent_scope = parent_scope
      @type_args = type_args
      @args = args
      @return_type = return_type
      @loc = loc
      @method_defs = []
    end

    def to_rbi(level)
      ''.tap do |result|
        result << indent("#{sig}\n", level)
        result << indent("def #{name}(#{args.to_ruby})\n", level)
        result << "#{yield}\n" if block_given?
        result << indent("end", level)
      end
    end

    def accept(visitor, level)
      visitor.visit_method_def(self, level)
    end

    def top_level_scope?
      false
    end

    def sig
      sig_parts = [].tap do |parts|
        unless args.empty?
          parts << "params(#{args.sig})"
        end

        if return_type
          parts << "returns(#{return_type.sig})"
        else
          parts << "void"
        end
      end

      "sig { #{sig_parts.join('.')} }"
    end

    def inspect(indent = 0)
      return super() if Myrb.debug?
      (block_arg, *), other_args = args.partition(&:block_arg?)
      result = "#{name}: "
      result << "#{type_args.inspect} " unless type_args.empty?
      result << "(#{other_args.map(&:inspect).join(', ')})"
      result << " #{block_arg.inspect})" if block_arg
      result << " -> #{return_type.inspect}"
      result
    end
  end
end
