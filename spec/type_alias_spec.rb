# frozen_string_literal: true

require "spec_helper"

describe "Type aliases" do
  before(:each) do
    code(<<~RUBY)
      class Foo
        type cmd = String | Array[String]
      end
    RUBY
  end

  it "identifies the type alias" do
    klass = find("Foo")
    expect(klass.type_aliases.size).to eq(1)

    type_alias = klass.type_aliases.first
    expect(type_alias.name).to eq("cmd")
    expect(type_alias.definition).to eq("type cmd = String | Array[String]")
  end
end
