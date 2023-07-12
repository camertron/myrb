# frozen_string_literal: true

require "spec_helper"

describe "Interfaces" do
  before(:each) do
    code(<<~RUBY)
      class Foo
        interface _Person
          def name: () -> String
        end
      end
    RUBY
  end

  it "identifies the type alias" do
    klass = find("Foo")
    expect(klass.interfaces.size).to eq(1)

    iface = klass.interfaces.first
    expect(iface.name).to eq("_Person")
    expect(iface.definition).to eq("interface _Person\n    def name: () -> String\n  end")
  end
end
