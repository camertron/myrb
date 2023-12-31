# frozen_string_literal: true

module Myrb
  class Constant < Annotation
    attr_reader :name, :loc, :tokens

    def self.from_tokens(loc, tokens)
      name = tokens.map { |_, (text, _)| text }.join
      new(name, loc, tokens)
    end

    def initialize(name, loc = nil, tokens = nil)
      @name = name
      @loc = loc
      @tokens = tokens
    end

    def to_ruby
      name
    end

    def inspect
      return super() if Myrb.debug?
      to_ruby
    end

    def accept(visitor, level)
      visitor.visit_constant(self, level)
    end
  end


  class Type < Annotation
    attr_reader :const, :loc, :type_args, :nilable

    alias nilable? nilable

    def initialize(const, loc = nil, type_args = TypeArgs.empty, nilable = false)
      @const = const
      @loc = loc
      @type_args = type_args
      @nilable = nilable
    end

    alias nilable? nilable

    def to_ruby
      const.to_ruby
    end

    def sig
      const.name.dup.tap do |result|
        result << type_args.sig unless type_args.empty?
      end
    end

    def inspect(indent = 0)
      return super() if Myrb.debug?
      const.name.dup.tap do |result|
        result << type_args.inspect unless type_args.empty?
        result << "?" if nilable?
      end
    end

    def has_args?
      type_args ? !type_args.empty? : false
    end

    def accept(visitor, level)
      visitor.visit_type(self, level)
    end
  end


  class TypeArgs < Annotation
    include Enumerable

    attr_reader :loc, :args

    def self.empty
      new(nil, [])
    end

    def initialize(loc, args)
      @loc = loc
      @args = args
    end

    def empty?
      args.empty?
    end

    def sig
      "[#{args.map(&:sig).join(', ')}]"
    end

    def inspect(indent = 0)
      return super() if Myrb.debug?
      "[#{args.map(&:inspect).join(', ')}]"
    end

    def each(&block)
      @args.each(&block)
    end

    def accept(visitor, level)
      visitor.visit_type_args(self, level)
    end
  end


  class NilType < Annotation
    attr_reader :loc

    def initialize(loc)
      @loc = loc
    end

    def accept(visitor, level)
      visitor.visit_nil_type(self, level)
    end

    def inspect
      'nil'
    end
  end


  class UntypedType < Annotation
    attr_reader :loc

    def initialize(loc = {})
      @loc = loc
    end

    def accept(visitor, level)
      visitor.visit_untyped_type(self, level)
    end

    def inspect
      'untyped'
    end
  end


  class VoidType < Annotation
    attr_reader :loc

    def initialize(loc = {})
      @loc = loc
    end

    def accept(visitor, level)
      visitor.visit_void_type(self, level)
    end

    def inspect
      'void'
    end
  end


  class BoolType < Annotation
    attr_reader :loc

    def initialize(loc = {})
      @loc = loc
    end

    def accept(visitor, level)
      visitor.visit_bool_type(self, level)
    end

    def inspect
      'bool'
    end
  end


  class BlockType < Annotation
    attr_reader :loc, :args, :return_type

    def initialize(loc, args, return_type)
      @loc = loc
      @args = args
      @return_type = return_type
    end

    def name
      nil
    end

    def sig
      result = ["T.proc"].tap do |parts|
        unless args.empty?
          at = args.map.with_index do |arg, i|
            "arg#{i}: #{arg.sig}"
          end

          parts << "params(#{at.join(', ')})"
        end

        if return_type
          parts << "returns(#{return_type.sig})"
        else
          parts << 'void'
        end
      end

      result.join('.')
    end

    def inspect
      return super() if Myrb.debug?
      (+'{ (').tap do |result|
        result << args.map(&:inspect).join(', ')
        result << ') -> '

        if return_type
          result << return_type.inspect
        else
          result << 'void'
        end

        result << ' }'
      end
    end

    def accept(visitor, level)
      visitor.visit_block_type(self, level)
    end
  end


  class ProcType
    attr_reader :loc, :args, :return_type

    def initialize(loc, args, return_type)
      @loc = loc
      @args = args
      @return_type = return_type
    end

    def accept(visitor, level)
      visitor.visit_proc_type(self, level)
    end
  end


  class ClassOf < Annotation
    attr_reader :const, :loc, :type_args, :nilable

    def initialize(const, loc, type_args, nilable)
      @const = const
      @loc = loc
      @type_args = type_args
      @nilable = nilable
    end

    def type
      type_args.first
    end

    def sig
      "T.class_of(#{type.sig})"
    end

    def inspect(indent = 0)
      return super() if Myrb.debug?
      "ClassOf(#{type.inspect})"
    end

    def accept(visitor, level)
      visitor.visit_class_of(self, level)
    end
  end


  class SelfType
    attr_reader :const, :loc, :nilable

    alias nilable? nilable

    def initialize(const, loc, nilable)
      @const = const
      @loc = loc
      @nilable = nilable
    end

    def sig
      'T.self_type'
    end

    def inspect
      return super() if Myrb.debug?
      'SelfType'
    end

    def accept(visitor, level)
      visitor.visit_self_type(self, level)
    end
  end
end
