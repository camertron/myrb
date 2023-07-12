$:.push(__dir__)
$:.push(File.join(__dir__, "helpers"))

require "rspec"
require "matchers/have_arg"
require "matchers/have_default_value"
require "matchers/have_type"
require "matchers/have_type_arguments"
require "matchers/match_selector"
require "matchers/return_a"

require "parser/current"

require "myrb"
require "myrb/selector"

module Myrb
  module SpecHelpers
    def code(source)
      @annotated_source = Myrb::AnnotatedSource.new(source)
    end

    def annotations
      @annotated_source.annotations
    end

    def find(selector, scope = annotations)
      Myrb::Selector.parse(selector).find_in(scope)
    end

    def find_all(selector, scope = annotations)
      Myrb::Selector.parse(selector).find_all_in(scope)
    end

    def find_any(selector, scope = annotations)
      Myrb::Selector.parse(selector).find_any_in(scope)
    end
  end
end

RSpec.configure do |config|
  config.include(Myrb::SpecHelpers)
end
