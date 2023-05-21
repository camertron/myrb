# frozen_string_literal: true

module Myrb
  module TokenHelpers
    def type_of(token)
      token[0]
    end

    def text_of(token)
      token[1][0]
    end

    def pos_of(token)
      token[1][1]
    end
  end
end
