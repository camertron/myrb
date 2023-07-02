# frozen_string_literal: true

module Myrb
  class Preprocessor
    def self.call(source)
      Myrb::AnnotatedSource.new(source).rewritten_source
    end
  end
end
