# frozen_string_literal: true

require 'parser/current'

module Myrb
  class AnnotatedFile
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def annotations
      process!

      context[:annotations]
    end

    def ast
      process!
    end

    def annotated_ast
      Myrb::Processor.new(annotations).process(ast[0])
    end

    private

    def process!
      @ast ||= begin
        buffer = ::Parser::Source::Buffer.new('(source)', source: contents)
        lexer = Myrb::Lexer.new(buffer, 0, context)
        parser = Myrb::Parser.new(lexer)
        parser.parse(buffer)
      end
    end

    def context
      @context ||= {}
    end

    def contents
      @contents ||= ::File.read(path)
    end
  end
end
