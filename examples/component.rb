# frozen_string_literal: true

module Foo::Bar
  class TestComponent[K, V] < ViewComponent::Base
    private attr_reader foobars: Hash[String, String]

    prepend Boo
    include Bar
    extend Baz

    def initialize(title: Array[Numeric] = foo('title'.upcase), thing: Hash[K, String | Numeric]) -> nil
      @title = title
      @thing = thing
    end

    def each(&block: Proc[[String, String], String]) -> nil
    end

    private def render -> String
    end
  end
end
