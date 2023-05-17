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

    def source
      @source ||= ::File.read(path)
    end

    def rewritten_source
      @rewritten_source ||= begin
        rewriter = Myrb::Rewriter.new(annotations)
        rewriter.rewrite(make_source_buffer, ast[0])
      end
    end

    private

    def process!
      @ast ||= begin
        buffer = make_source_buffer
        lexer = Myrb::Lexer.new(buffer, 0, context)
        parser = Myrb::Parser.new(lexer)
        lexer.parser = parser
        parser.parse(buffer)
      end
    end

    def make_source_buffer
      ::Parser::Source::Buffer.new('(source)', source: source)
    end

    def context
      @context ||= {}
    end
  end
end
