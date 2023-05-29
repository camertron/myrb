# frozen_string_literal: true

module Myrb
  class Annotator
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

      yield(child_scope).tap do
        scope_stack.pop
      end
    end

    alias on_class on_module

    def on_def(node)
      name, *children = *node
      method_def = find_method_def(name.to_s)
      return nil unless method_def

      method_stack.push(method_def)

      yield(method_def).tap do
        method_stack.pop
      end
    end

    def on_args(node)
      if args = current_method.args
        yield args
      end
    end

    def on_argument(node)
      arg = case node.type
        when :restarg
          find_rest_arg
        else
          arg_name, value_node = *node
          find_arg(arg_name.to_s)
      end

      return nil unless arg

      yield arg
    end

    def on_send(node)
      _, method_name, *args = *node

      if Lexer::ATTR_METHODS.include?(method_name.to_s) && args.size > 0 && args[0].type == :sym
        ivar_name, = *args[0]
        ivar = find_ivar(ivar_name.to_s)
        return nil unless ivar

        yield :ivar, ivar
      end
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

    def find_rest_arg
      current_method.args.find(&:naked_splat?)
    end

    def find_ivar(name)
      current_scope.ivars.find do |ivar|
        ivar.name == name
      end
    end

    def extract_const(node)
      return [] unless node
      scope_node, name = *node
      extract_const(scope_node) + [name]
    end
  end
end
