# frozen_string_literal: true

module Myrb
  class Constant < Annotation
    attr_reader :loc, :tokens, :nilable

    def initialize(loc, tokens, nilable = false)
      @loc = loc
      @tokens = tokens
      @nilable = nilable
    end

    alias nilable? nilable

    def to_ruby
      @ruby ||= tokens.map { |_, (text, _)| text }.join
    end

    def inspect
      return super() if Myrb.debug?
      to_ruby + (nilable? ? '?' : '')
    end

    def accept(visitor, level)
      visitor.visit_constant(self, level)
    end
  end


  class Type < Annotation
    attr_reader :const, :loc, :type_args

    def initialize(const, loc = nil, type_args = nil)
      @const = const
      @loc = loc
      @type_args = type_args
    end

    def to_ruby
      const.to_ruby
    end

    def sig
      const.to_ruby.dup.tap do |result|
        result << type_args.sig unless type_args.empty?
      end
    end

    def inspect(indent = 0)
      return super() if Myrb.debug?
      const.inspect.tap do |result|
        result << type_args.inspect unless type_args.empty?
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


  class ProcType < Annotation
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
      visitor.visit_proc_type(self, level)
    end
  end


  class ArrayType < Annotation
    attr_reader :const, :loc, :type_args

    def initialize(const, loc, type_args)
      @const = const
      @loc = loc
      @type_args = type_args
    end

    def elem_type
      type_args.args.first
    end

    def sig
      "T::Array[#{elem_type.sig}]"
    end

    def inspect(indent = 0)
      return super() if Myrb.debug?
      "Array[#{elem_type.inspect}]"
    end

    def accept(visitor, level)
      visitor.visit_array_type(self, level)
    end
  end


  class SetType < Annotation
    attr_reader :const, :loc, :type_args

    def initialize(const, loc, type_args)
      @const = const
      @loc = loc
      @type_args = type_args
    end

    def elem_type
      type_args.args.first
    end

    def sig
      "T::Set[#{elem_type.sig}]"
    end

    def inspect(indent = 0)
      return super() if Myrb.debug?
      "Set[#{elem_type.inspect}]"
    end

    def accept(visitor, level)
      visitor.visit_set_type(self, level)
    end
  end


  class HashType < Annotation
    attr_reader :const, :loc, :type_args

    def initialize(const, loc, type_args)
      @const = const
      @loc = loc
      @type_args = type_args
    end

    def key_type
      type_args.args.first
    end

    def value_type
      type_args.args.last
    end

    def sig
      "T::Hash[#{key_type.sig}, #{value_type.sig}]"
    end

    def inspect(indent = 0)
      return super() if Myrb.debug?
      "Hash[#{key_type.inspect}, #{value_type.inspect}]"
    end

    def accept(visitor, level)
      visitor.visit_hash_type(self, level)
    end
  end


  class RangeType < Annotation
    attr_reader :const, :loc, :type_args

    def initialize(type_args)
      @const = const
      @loc = loc
      @type_args = type_args
    end

    def elem_type
      type_args.first
    end

    def sig
      "T::Range[#{elem_type.sig}]"
    end

    def inspect(indent = 0)
      return super() if Myrb.debug?
      "Range[#{elem_type.inspect}]"
    end

    def accept(visitor, level)
      visitor.visit_range_type(self, level)
    end
  end


  class EnumerableType < Annotation
    attr_reader :const, :loc, :type_args

    def initialize(const, loc, type_args)
      @const = const
      @loc = loc
      @type_args = type_args
    end

    def elem_type
      type_args.first
    end

    def sig
      "T::Enumerable[#{elem_type.sig}]"
    end

    def inspect(indent = 0)
      return super() if Myrb.debug?
      "Enumerable[#{elem_type.inspect}]"
    end

    def accept(visitor, level)
      visitor.visit_enumerable_type(self, level)
    end
  end


  class EnumeratorType < Annotation
    attr_reader :const, :loc, :type_args

    def initialize(loc, type_args)
      @const = const
      @loc = loc
      @type_args = type_args
    end

    def elem_type
      type_args.first
    end

    def sig
      "T::Enumerator[#{elem_type.sig}]"
    end

    def inspect(indent = 0)
      return super() if Myrb.debug?
      "Enumerator[#{elem_type.inspect}]"
    end

    def accept(visitor, level)
      visitor.visit_enumerator_type(self, level)
    end
  end


  class ClassOf < Annotation
    attr_reader :loc, :type_args

    def initialize(const, loc, type_args)
      @const = const
      @loc = loc
      @type_args = type_args
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
    attr_reader :const, :loc

    def initialize(const, loc)
      @const = const
      @loc = loc
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
