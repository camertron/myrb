# frozen_string_literal: true

module Myrb
  class ExpressionLexer < LexerInterface
    attr_accessor :parser

    def initialize(source_buffer, init_pos)
      super()

      @source_buffer = source_buffer
      @lexer = BaseLexer.new(source_buffer, init_pos, {})
    end

    def advance
      if vstack[1].is_a?(::Parser::AST::Node)
        return [false, ['$eof']]
      end

      @lexer.advance
    end

    def vstack
      @vstack ||= parser.instance_variable_get(:@vstack)
    end
  end

  class ExpressionParser
    def self.parse(source_buffer, init_pos = 0)
      lexer = ExpressionLexer.new(source_buffer, init_pos)
      parser = new(lexer)
      lexer.parser = parser.send(:parser)
      parser.send(:parse, source_buffer)
    end

    private

    attr_reader :lexer, :parser

    def initialize(lexer)
      @lexer = lexer
      @parser = ::Parser::CurrentRuby.new
      parser.diagnostics.all_errors_are_fatal = false
      parser.instance_variable_set(:@lexer, lexer)
      lexer.diagnostics = parser.diagnostics
      lexer.static_env  = parser.static_env
      lexer.context     = parser.context
    end

    def parse(buffer)
      parser.parse(buffer)
      lexer.vstack.first
    end
  end
end
