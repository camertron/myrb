# frozen_string_literal: true

require 'parser/current'

module Myrb
  class AnnotatedSource
    attr_reader :source

    def initialize(source)
      @source = source
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

    def rewritten_source
      @rewritten_source ||= begin
        rewriter = Myrb::Rewriter.new(annotations)
        rewriter.rewrite(make_source_buffer, ast[0])
      end
    end

    def rbs_source
      @rbs_source ||= begin
        visitor = Myrb::RBSVisitor.new
        visitor.visit(annotations, 0)
      end
    end

    private

    def process!
      @ast ||= begin
        buffer = make_source_buffer
        lexer = Myrb::Lexer.new(buffer, 0, context)
        parser = Myrb::Parser.new(lexer)
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
