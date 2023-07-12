# frozen_string_literal: true

require "spec_helper"

describe "Args" do
  before(:each) do
    code(<<~RUBY)
      class Foo
        def args(pos_arg: String, pos_arg_default: String = "abc", *, kwarg: String?, kwarg_default: Numeric = 1, &block: { (foo: String, bar: Numeric) -> String }) -> nil
        end
      end
    RUBY
  end

  subject { find("Foo#args") }

  it "handles positional args" do
    expect(subject).to(have_arg("pos_arg")).tap do |arg|
      expect(arg).to be_positional
      expect(arg).to have_type("String")
    end
  end

  it "handles positional args with default values" do
    expect(subject).to(have_arg("pos_arg_default")).tap do |arg|
      expect(arg).to be_positional
      expect(arg).to have_type("String")
      expect(arg).to have_default_value("'abc'")
    end
  end

  it "interprets args following a naked splat as keyword args" do
    expect(subject).to(have_arg("kwarg")).tap do |arg|
      expect(arg).to be_kwarg
      expect(arg).to have_type("String?")
    end
  end

  it "handles keyword args with default values" do
    expect(subject).to(have_arg("kwarg_default")).tap do |arg|
      expect(arg).to be_kwarg
      expect(arg).to have_type("Numeric")
      expect(arg).to have_default_value("1")
    end
  end

  it "handles block args" do
    expect(subject).to(have_arg("block")).tap do |arg|
      expect(arg).to be_block_arg
      expect(arg.type).to return_a("String")

      expect(arg.type).to(have_args("foo", "bar")).tap do |foo_arg, bar_arg|
        expect(foo_arg).to have_type("String")
        expect(bar_arg).to have_type("Numeric")
      end
    end
  end
end
