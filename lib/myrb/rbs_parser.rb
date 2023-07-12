# frozen_string_literal: true

require "rbs"

module Myrb
  class RBSParser
    attr_reader :buffer, :init_pos

    def self.parse(buffer, init_pos)
      _, _, aliases = new(buffer, init_pos).parse
      aliases.first if aliases
    end

    def initialize(buffer, init_pos)
      @buffer = buffer
      @init_pos = init_pos
    end

    def parse
      start_pos = init_pos

      loop do
        end_pos = @buffer.source.index("\n", start_pos)
        return unless end_pos

        chunk = @buffer.source[start_pos...end_pos]

        begin
          signature = RBS::Parser.parse_signature(chunk)
        rescue RBS::ParsingError
        else
          return signature
        end

        start_pos = end_pos + 1
      end
    end
  end
end
