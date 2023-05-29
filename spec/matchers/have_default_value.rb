# frozen_string_literal: true

RSpec::Matchers.define :have_default_value do |value|
  match do |arg_def|
    arg_def.default_value_string == value
  end

  failure_message do |arg_def|
    "expected argument #{arg_def.name} to have a default value of #{value.inspect} but got #{arg_def.default_value_string.inspect} instead"
  end
end