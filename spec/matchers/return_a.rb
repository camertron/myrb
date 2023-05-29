# frozen_string_literal: true

RSpec::Matchers.define :return_a do |type_str|
  match do |callable|
    callable.return_type.inspect == type_str
  end

  failure_message do |callable|
    "expected callable to have a return type of '#{type_str}' but instead it has a return type of '#{callable.return_type.inspect}'"
  end
end