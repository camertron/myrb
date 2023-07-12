# frozen_string_literal: true

module Myrb
  autoload :AnnotatedFile,      "myrb/annotated_file"
  autoload :AnnotatedSource,    "myrb/annotated_source"
  autoload :AnnotationVisitor,  "myrb/annotation_visitor"
  autoload :Annotation,         "myrb/annotation"
  autoload :Annotations,        "myrb/annotations"
  autoload :Annotator,          "myrb/annotator"
  autoload :Arg,                "myrb/arg"
  autoload :Args,               "myrb/args"
  autoload :AttrReader,         "myrb/attr"
  autoload :AttrWriter,         "myrb/attr"
  autoload :BaseLexer,          "myrb/base_lexer"
  autoload :BlockDef,           "myrb/block_def"
  autoload :ClassDef,           "myrb/class_def"
  autoload :DecorationVisitor,  "myrb/decoration_visitor"
  autoload :Endable,            "myrb/endable"
  autoload :ExpressionBoundary, "myrb/expression_boundary"
  autoload :Interface,          "myrb/interface"
  autoload :IVar,               "myrb/ivar"
  autoload :Lexer,              "myrb/lexer"
  autoload :LexerInterface,     "myrb/lexer_interface"
  autoload :MethodDef,          "myrb/method_def"
  autoload :ModuleDef,          "myrb/module_def"
  autoload :Parser,             "myrb/parser"
  autoload :Preprocessor,       "myrb/preprocessor"
  autoload :Processor,          "myrb/processor"
  autoload :Project,            "myrb/project"
  autoload :ProjectCache,       "myrb/project_cache"
  autoload :RBSParser,          "myrb/rbs_parser"
  autoload :RBSVisitor,         "myrb/rbs_visitor"
  autoload :Rewriter,           "myrb/rewriter"
  autoload :Scope,              "myrb/scope"
  autoload :SingletonClassDef,  "myrb/singleton_class_def"
  autoload :TokenHelpers,       "myrb/token_helpers"
  autoload :TopLevelScope,      "myrb/top_level_scope"
  autoload :TypeAlias,          "myrb/type_alias"
  autoload :TypeList,           "myrb/type_list"
  autoload :UnionType,          "myrb/union_type"

  # types
  autoload :BlockType,          "myrb/types"
  autoload :ClassOf,            "myrb/types"
  autoload :NilType,            "myrb/types"
  autoload :ProcType,           "myrb/types"
  autoload :SelfType,           "myrb/types"
  autoload :Type,               "myrb/types"
  autoload :UntypedType,        "myrb/types"

  class << self
    attr_accessor :debug

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

require 'onload'

Onload.register('.trb', Myrb::Preprocessor)
