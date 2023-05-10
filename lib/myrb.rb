# frozen_string_literal: true

module Myrb
  autoload :AnnotatedFile,     'myrb/annotated_file'
  autoload :Annotation,        'myrb/annotation'
  autoload :Annotations,       'myrb/annotations'
  autoload :Arg,               'myrb/arg'
  autoload :Args,              'myrb/args'
  autoload :AttrReader,        'myrb/ivar'
  autoload :AttrWriter,        'myrb/ivar'
  autoload :BaseLexer,         'myrb/base_lexer'
  autoload :ClassDef,          'myrb/class_def'
  autoload :DecorationVisitor, 'myrb/decoration_visitor'
  autoload :IVar,              'myrb/ivar'
  autoload :Lexer,             'myrb/lexer'
  autoload :LexerInterface,    'myrb/lexer_interface'
  autoload :MethodDef,         'myrb/method_def'
  autoload :ModuleDef,         'myrb/module_def'
  autoload :Parser,            'myrb/parser'
  autoload :Processor,         'myrb/processor'
  autoload :RBSVisitor,        'myrb/rbs_visitor'
  autoload :Scope,             'myrb/scope'
  autoload :TopLevelScope,     'myrb/top_level_scope'
  autoload :TypeList,          'myrb/type_list'
  autoload :UnionType,         'myrb/union_type'


  # types
  autoload :ArrayType,         'myrb/types'
  autoload :ClassOf,           'myrb/types'
  autoload :EnumerableType,    'myrb/types'
  autoload :EnumeratorType,    'myrb/types'
  autoload :HashType,          'myrb/types'
  autoload :NilType,           'myrb/types'
  autoload :ProcType,          'myrb/types'
  autoload :RangeType,         'myrb/types'
  autoload :SelfType,          'myrb/types'
  autoload :SetType,           'myrb/types'
  autoload :Type,              'myrb/types'
  autoload :UntypedType,       'myrb/types'

  class << self
    def default_annotations_path
      @default_annotations_path ||= File.join('.', 'rbs')
    end

    def register_type_class(const, type_klass)
      registered_type_classes[const] = type_klass
    end

    def get_type(const, *args)
      if type_klass = registered_type_classes[const.to_ruby]
        type_klass.new(*args)
      else
        Type.new(const, *args)
      end
    end

    private

    def registered_type_classes
      @registered_type_classes ||= {}
    end
  end

  register_type_class("Array", ArrayType)
  register_type_class("ClassOf", ClassOf)
  register_type_class("Enumerable", EnumerableType)
  register_type_class("Enumerator", EnumeratorType)
  register_type_class("Hash", HashType)
  register_type_class("Proc", ProcType)
  register_type_class("Range", RangeType)
  register_type_class("Set", SetType)
end
