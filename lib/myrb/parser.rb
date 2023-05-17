# frozen_string_literal: true

require 'parser/current'

module Myrb
  class Parser
    attr_reader :lexer, :parser

    def initialize(lexer)
      @lexer = lexer
      @parser = ::Parser::CurrentRuby.new
      parser.diagnostics.all_errors_are_fatal = true
      parser.instance_variable_set(:@lexer, lexer)
      lexer.diagnostics = parser.diagnostics
      lexer.static_env  = parser.static_env
      lexer.context     = parser.context
    end

    def parse(buffer)
      parser.parse_with_comments(buffer)
    end
  end
end

# unfortunately these have to be set globally :(
Parser::Builders::Default.tap do |builder|
  builder.emit_lambda              = true
  builder.emit_procarg0            = true
  builder.emit_encoding            = true
  builder.emit_index               = true
  builder.emit_arg_inside_procarg0 = true
  builder.emit_forward_arg         = true
  builder.emit_kwargs              = true
  builder.emit_match_pattern       = true
end
