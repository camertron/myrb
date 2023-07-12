# frozen_string_literal: true

require "spec_helper"

describe "Methods" do
  context "inside classes" do
    before(:each) do
      code(<<~RUBY)
        class StringHelpers
          def some_method(arg: String) -> String | nil
          end
        end
      RUBY
    end

    it "parses the method definition" do
      mtd = find("StringHelpers#some_method")
      expect(mtd).to_not be_nil
      expect(mtd).to have_arg("arg")
      expect(mtd).to return_a("String | nil")
    end
  end

  context "inside other methods" do
    before(:each) do
      code(<<~RUBY)
        def outer_method
          def inner_method(arg: String) -> Array[Numeric]
          end
        end
      RUBY
    end

    it "parses the method definition" do
      inner_mtd = find("#inner_method", find("#outer_method"))
      expect(inner_mtd).to_not be_nil
      expect(inner_mtd).to have_arg("arg")
      expect(inner_mtd).to return_a("Array[Numeric]")
    end
  end
end
