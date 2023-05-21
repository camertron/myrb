# frozen_string_literal: true

module Myrb
  autoload :AnnotatedFile,     'myrb/annotated_file'
  autoload :Annotation,        'myrb/annotation'
  autoload :Annotations,       'myrb/annotations'
  autoload :Annotator,         'myrb/annotator'
  autoload :Arg,               'myrb/arg'
  autoload :Args,              'myrb/args'
  autoload :AttrReader,        'myrb/ivar'
  autoload :AttrWriter,        'myrb/ivar'
  autoload :BaseLexer,         'myrb/base_lexer'
  autoload :ClassDef,          'myrb/class_def'
  autoload :DecorationVisitor, 'myrb/decoration_visitor'
  autoload :ExpressionParser,  'myrb/expression_parser'
  autoload :IVar,              'myrb/ivar'
  autoload :Lexer,             'myrb/lexer'
  autoload :LexerInterface,    'myrb/lexer_interface'
  autoload :MethodDef,         'myrb/method_def'
  autoload :ModuleDef,         'myrb/module_def'
  autoload :Parser,            'myrb/parser'
  autoload :Processor,         'myrb/processor'
  autoload :RBSVisitor,        'myrb/rbs_visitor'
  autoload :Rewriter,          'myrb/rewriter'
  autoload :Scope,             'myrb/scope'
  autoload :TokenHelpers,      'myrb/token_helpers'
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
    attr_accessor :debug

    def default_annotations_path
      @default_annotations_path ||= File.join('.', 'rbs')
    end

    def debug?
      @debug || !!ENV['MYRB_DEBUG']
    end

    def with_debug(value)
      old_value = @debug
      @debug = value
      yield
    ensure
      @debug = old_value
    end
  end
end
