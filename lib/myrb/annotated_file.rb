# frozen_string_literal: true

require 'parser/current'

module Myrb
  class AnnotatedFile < AnnotatedSource
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def source
      @source ||= ::File.read(path)
    end

    private

    def make_source_buffer
      ::Parser::Source::Buffer.new(path, source: source)
    end
  end
end
