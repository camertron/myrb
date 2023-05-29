# frozen_string_literal: true

module Foo::Bar
  class TestComponent[K, V] < ViewComponent::Base
    private attr_reader foobars: Hash[String, Thing?]

    prepend Boo
    include Bar
    extend Baz

    def initialize(title: Array[Numeric] = foo('title'.upcase), thing: Hash[K, String | Numeric]) -> nil
      @title = title
      @thing = thing
    end

    def whatever[U](arg: String?)
    end

    def keyword_args(pos_arg: String, *, kwarg: Numeric = 1, other_kwarg: Float)
    end

    def another(foo, *)
    end

    def each(&block: { (foo: String, bar: Numeric) -> String }) -> nil
    end

    private def render -> String
    end
  end
end
