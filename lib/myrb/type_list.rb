# frozen_string_literal: true

module Myrb
  class TypeList < Annotation
    include Enumerable

    attr_reader :types

    def initialize(types)
      @types = types
    end

    def empty?
      types.empty?
    end

    def each(&block)
      types.each(&block)
    end

    def inspect(indent = 0)
      "[#{types.map(&:inspect).join(', ')}]"
    end
  end
end
