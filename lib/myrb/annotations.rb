# frozen_string_literal: true

module Myrb
  module Annotations
    class << self
      def register_type_class(const, type_klass)
        registered_type_classes[const] = type_klass
      end

      def get_type(const, type_args, nilable, loc)
        if type_klass = registered_type_classes[const.to_ruby]
          type_klass.new(const, loc, type_args, nilable)
        else
          Type.new(const, loc, type_args, nilable)
        end
      end

      private

      def registered_type_classes
        @registered_type_classes ||= {}
      end
    end


    register_type_class("ClassOf", ClassOf)
    register_type_class("SelfType", SelfType)
  end
end
