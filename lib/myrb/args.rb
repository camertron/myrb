# frozen_string_literal: true

module Myrb
  class Args < Annotation
    include Enumerable

    attr_reader :args

    def initialize(args)
      @args = args
    end

    def to_ruby
      args.map(&:to_ruby).join(', ')
    end

    def sig
      args.map(&:sig).join(', ')
    end

    def size
      args.size
    end

    alias length size

    def empty?
      args.empty?
    end

    def accept(visitor, level)
      visitor.visit_args(self, level)
    end

    def each(&block)
      args.each(&block)
    end

    def [](idx)
      args[idx]
    end

    def first
      args.first
    end

    def last
      args.last
    end

    def inspect(indent = 0)
      return super() if Myrb.debug?
      args.map { |arg| arg.inspect(indent) }.join(', ')
    end

    def block_arg
      args.find(&:block_arg?)
    end

    def accept(visitor, level)
      visitor.visit_args(self, level)
    end
  end
end
