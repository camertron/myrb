# frozen_string_literal: true

RSpec::Matchers.define :match_selector do |selector_str|
  match do |scope|
    Myrb::Selector.parse(selector_str).find_in(scope)
  end

  failure_message do
    "expected scope to match #{selector_str} but no match was found"
  end
end
