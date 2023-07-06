# frozen_string_literal: true

module Myrb
  class SingletonClassDef < ClassDef
    def initialize(parent_class_def)
      super(Type.new(Constant.new("Class:#{parent_class_def.type.name}")), nil)
    end

    def singleton?
      true
    end

    def accept(visitor, level)
      visitor.visit_class_def(self, level)
    end
  end
end
