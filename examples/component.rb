# frozen_string_literal: true

module Foo::Bar
  class TestComponent[K, V] < ViewComponent::Base
    prepend Boo
    include Bar
    extend Baz

    def initialize(title: Array[Numeric], thing: Hash[K, String | Numeric]) -> nil
      @title = title
      @thing = thing
    end

    def each(&block: Proc[[String, String], String]) -> nil
    end

    def render -> String
    end
  end
end
