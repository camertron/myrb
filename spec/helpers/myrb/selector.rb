# frozen_string_literal: true

module Myrb
  module SelectorTokenizer
    TOKEN_REGEXES = {
      constant: /\A[A-Z][\w:]+\z/,
      hash: /\A#\z/,
      dot: /\A\.\z/,
      comma: /\A,\z/,
      lparen: /\A\(\z/,
      rparen: /\A\)\z/,
      identifier: /\A\w+\z/
    }

    SPLIT_REGEX = /[A-Z][\w:]+|#|\.|,|\(|\)|\w+/

    class << self
      def tokenize(str)
        str.scan(SPLIT_REGEX).filter_map do |val|
          type = TOKEN_REGEXES.keys.find { |k| TOKEN_REGEXES[k] =~ val }
          next unless type

          [type, val]
        end
      end
    end
  end

  class SelectorLexer
    def initialize(str)
      @generator = SelectorTokenizer.tokenize(str).each
    end

    def advance
      @generator.next
    rescue StopIteration
      [:eof, nil]
    end
  end

  class SelectorParseError < StandardError; end

  class SelectorList
    attr_reader :selectors

    def initialize(selectors)
      @selectors = selectors
    end

    def find_in(scope)
      selectors.each do |selector|
        if result = selector.find_in(scope)
          return result
        end
      end

      nil
    end

    def find_all_in(scope)
      selectors.flat_map do |selector|
        selector.find_all_in(scope)
      end
    end

    def find_any_in(scope)
      selectors.flat_map do |selector|
        selector.find_any_in(scope)
      end
    end
  end

  class Selector
    class << self
      def parse(*args)
        SelectorParser.parse(*args)
      end
    end

    attr_reader :constant, :mtd, :args

    def initialize(constant, mtd, args)
      @constant = constant
      @mtd = mtd
      @args = args
    end

    # Finds the first thing that matches and returns it, i.e. does not return an array.
    def find_in(scope)
      find_each_in(scope) do |found|
        return found
      end
    end

    # The idea here is to always return an array, no matter the specificity. However,
    # when selecting args, the selector only matches if all the args can be matched.
    # In other words, if not all args can be matched, find_all_in returns an empty
    # array as if the selector matches nothing.
    def find_all_in(scope)
      found = find_each_in(scope).map(&:itself)
      return [] if specificity == :arg && found.size < args.size

      found
    end

    # Always return an array, no matter the specificity. When selecting args, this
    # method will return any that match. Use find_all_in if you want all args to match.
    def find_any_in(scope)
      find_each_in(scope).map(&:itself)
    end

    def specificity
      return :arg unless args.empty?
      return :method if mtd
      :scope
    end

    private

    def find_each_in(scope)
      return to_enum(__method__, scope) unless block_given?

      scope = find_constant_in(scope, constant) if constant
      return nil unless scope
      yield scope and return unless mtd

      mtd_def = scope.method_defs.find { |d| d.name == mtd }
      return nil unless mtd_def
      yield mtd_def and return if args.empty?

      args.each do |arg|
        mtd_arg = mtd_def.args.find { |mtd_arg| mtd_arg.name == arg }
        yield mtd_arg if mtd_arg
      end
    end

    def find_constant_in(scope, const)
      each_const_segment(const) do |prefix, suffix|
        if child_scope = scope.scopes.find { |s| s.type.const.to_ruby == prefix }
          if suffix
            return find_constant_in(child_scope, suffix)
          else
            return child_scope
          end
        end
      end
    end

    def each_const_segment(const)
      return to_enum(__method__, const) unless block_given?

      idx = const.size

      while idx
        prefix = const[0...idx]
        suffix = idx == const.size ? nil : const[(idx + 2)..-1]
        yield prefix, suffix

        idx = const.rindex('::', idx - 2)
      end
    end
  end

  class SelectorParser
    class << self
      def parse(str)
        new(SelectorLexer.new(str)).parse
      end
    end

    def initialize(lexer)
      @lexer = lexer
      @current = lexer.advance
    end

    def parse
      handle_selector_list
    end

    private

    attr_reader :lexer, :current

    def handle_selector_list
      selectors = []

      loop do
        break if type_of(current) == :eof

        selectors << handle_selector

        if type_of(current) == :comma
          consume(:comma)
        else
          break
        end
      end

      consume(:eof)

      SelectorList.new(selectors)
    end

    def handle_selector
      constant = if type_of(current) == :constant
        text_of(current).tap do
          consume(:constant)
        end
      end

      mtd = if type_of(current) == :hash
        consume(:hash)
        text_of(current).tap do
          consume(:identifier)
        end
      end

      args = []

      if type_of(current) == :lparen
        consume(:lparen)

        loop do
          args << text_of(current)
          consume(:identifier)

          if type_of(current) == :comma
            consume(:comma)
          else
            break
          end
        end

        consume(:rparen)
      end

      Selector.new(constant, mtd, args)
    end

    def consume(type)
      if type_of(current) != type
        raise SelectorParseError, "expected #{type} but got #{type_of(current)}"
      end

      @current = lexer.advance
    end

    def type_of(token)
      token[0]
    end

    def text_of(token)
      token[1]
    end
  end
end