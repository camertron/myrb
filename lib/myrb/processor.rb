# frozen_string_literal: true

module Myrb
  class Processor < ::Parser::AST::Processor
    attr_reader :annotator

    def initialize(annotations)
      @annotator = Annotator.new(annotations)
    end

    def on_module(node)
      name_node, *children = *node

      annotator.on_module(node) do |module_def|
        node.updated(nil, [name_node, module_def, *process_all(children)])
      end
    end

    alias on_class on_module

    def on_def(node)
      name_node, *children = *node

      annotator.on_def(node) do |method_def|
        node.updated(nil, [name_node, method_def, *process_all(children)])
      end
    end

    def on_args(node)
      annotator.on_args(node) do |args|
        node.updated(nil, [args, *process_all(node.children)])
      end
    end

    def on_argument(node)
      arg_name, value_node = *node

      annotator.on_argument(node) do |arg|
        node.updated(nil, [arg_name, process(value_node), arg])
      end
    end
  end
end