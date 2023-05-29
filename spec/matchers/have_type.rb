# frozen_string_literal: true

RSpec::Matchers.define :have_type do |type_str|
  match do |typeable|
    typeable.type.inspect == type_str
  end

  failure_message do |typeable|
    "expected object to have a type of '#{type_str}' but instead it has a type of '#{typeable.type.inspect}'"
  end
end