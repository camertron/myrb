# frozen_string_literal: true

module Myrb
  class ExpressionParser < ::Parser::CurrentRuby
    class StopError < StandardError; end

    def self.parse(source_buffer, init_pos = 0)
      lexer = BaseLexer.new(source_buffer, init_pos, {})
      parser = new(lexer)
      parser.send(:parse, source_buffer)
    end

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

    def on_error(*)
      raise StopError
    end
  end
end
