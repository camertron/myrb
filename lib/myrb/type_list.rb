# frozen_string_literal: true

module Myrb
  class TypeList < Annotation
    include Enumerable

    attr_reader :types, :loc

    def initialize(types, loc)
      @types = types
      @loc = loc
    end

    def empty?
      types.empty?
    end

    def each(&block)
      types.each(&block)
    end

    def inspect(indent = 0)
      return super() if Myrb.debug?
      "[#{types.map(&:inspect).join(', ')}]"
    end
  end
end
