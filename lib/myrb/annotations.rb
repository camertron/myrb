# frozen_string_literal: true

module Myrb
  module Annotations
    class << self
      def register_type_class(const, type_klass)
        registered_type_classes[const] = type_klass
      end

      def get_type(const, type_args, loc)
        if type_klass = registered_type_classes[const.to_ruby]
          type_klass.new(loc, type_args)
        else
          Type.new(const, loc, type_args)
        end
      end

      private

      def registered_type_classes
        @registered_type_classes ||= {}
      end
    end


    register_type_class("Array", ArrayType)
    register_type_class("ClassOf", ClassOf)
    register_type_class("Enumerable", EnumerableType)
    register_type_class("Enumerator", EnumeratorType)
    register_type_class("Hash", HashType)
    register_type_class("Proc", ProcType)
    register_type_class("Range", RangeType)
    register_type_class("Set", SetType)
    register_type_class("SelfType", SelfType)
  end
end
