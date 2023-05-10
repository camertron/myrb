# frozen_string_literal: true

module Myrb
  class Processor < ::Parser::AST::Processor
    attr_reader :annotations, :scope_stack, :method_stack

    def initialize(annotations)
      @annotations = annotations
      @scope_stack = [annotations]
      @method_stack = []
    end

    def on_module(node)
      name_node, *children = *node
      name = extract_const(name_node).join('::')
      child_scope = find_child_scope(name)
      return nil unless child_scope

      scope_stack.push(child_scope)

      node.updated(nil, [name, child_scope, *process_all(children)]).tap do
        scope_stack.pop
      end
    end

    alias on_class on_module

    def on_def(node)
      name, *children = *node
      method_def = find_method_def(name.to_s)
      return nil unless method_def

      method_stack.push(method_def)

      node.updated(nil, [name, method_def, *process_all(children)]).tap do
        method_stack.pop
      end
    end

    def on_args(node)
      node.updated(nil, [current_method&.args, *process_all(node.children)])
    end

    def on_argument(node)
      arg_name, value_node = *node
      arg = find_arg(arg_name.to_s)
      return nil unless arg

      node.updated(nil, [arg_name, process(value_node), arg])
    end

    private

    def current_scope
      scope_stack.last
    end

    def current_method
      method_stack.last
    end

    def find_child_scope(name)
      current_scope.scopes.find do |child_scope|
        child_scope.type.to_ruby == name
      end
    end

    def find_method_def(name)
      if current_method
        current_method.method_defs.each do |mdef|
          return mdef if mdef.name == name
        end
      end

      current_scope.method_defs.find do |mdef|
        mdef.name == name
      end
    end

    def find_arg(name)
      current_method.args.find do |arg|
        arg.name == name
      end
    end

    def extract_const(node)
      return [] unless node
      scope_node, name = *node
      extract_const(scope_node) + [name]
    end
  end
end