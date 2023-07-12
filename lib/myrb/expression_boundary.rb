# frozen_string_literal: true

module Myrb
  class ExpressionBoundary
    extend TokenHelpers

    def self.find(source_buffer, init_pos = 0)
      parser = ExpressionParser.new(source_buffer, init_pos)
      result = parser.parse

      if result
        return init_pos...result.loc.expression.end_pos
      end

      last_token_pos = pos_of(parser.last_token)

      if last_token_pos.begin_pos != init_pos
        init_pos...last_token_pos.begin_pos
      end
    end
  end

  class ExpressionParser
    def initialize(source_buffer, init_pos = 0)
      @source_buffer = source_buffer
      lexer = BaseLexer.new(source_buffer, init_pos, {})
      @parser = DerivedExpressionParser.new(lexer)
    end

    def parse
      @parser.parse(@source_buffer)
    end

    def last_token
      @parser.last_token
    end
  end

  class DerivedExpressionParser < ::Parser::CurrentRuby
    class StopError < StandardError; end

    attr_reader :last_token

    def initialize(lexer)
      super()

      @lexer = lexer
      @error_vstack = []

      diagnostics.all_errors_are_fatal = false

      lexer.diagnostics = diagnostics
      lexer.static_env  = static_env
      lexer.context     = context
    end

    def parse(source_buffer)
      super
    rescue StopError
    ensure
      return @vstack.last
    end

    private

    def on_error(*args)
      raise StopError
    end
  end
end
