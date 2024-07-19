# frozen_string_literal: true

module Myrb
  class RBSVisitor < AnnotationVisitor
    def visit_arg(node, level)
      if node.kwarg?
        "#{node.optional? ? "?" : ""}#{node.name}: #{visit(node.type, level)}"
      else
        "#{node.optional? ? "?" : ""}#{visit(node.type, level)}"
      end
    end

    def visit_args(node, level)
      arg_strs = node.args.filter_map do |a|
        next if a.naked_splat?
        next if a.block_arg?

        visit(a, level)
      end

      arg_strs.join(', ')
    end

    def visit_type_args(node, level)
      "[#{node.map { |ta| visit(ta, level) }.join(', ')}]"
    end

    def visit_class_def(node, level)
      if node.singleton?
        handle_singleton_class_def(node, level)
      else
        handle_class_def(node, level)
      end
    end

    def visit_ivar(node, level)
      receiver = node.parent_scope.singleton? ? "self." : ""
      indent("#{receiver}#{node.name}: #{visit(node.type, level)}", level)
    end

    def visit_attr(node, level)
      lines = []

      case node.kind
        when "attr_reader", "attr_accessor"
          lines << indent("def #{node.name}: () -> #{visit(node.type, level)}", level)
      end

      case node.kind
        when "attr_writer", "attr_accessor"
          type = visit(node.type, level)
          lines << indent("def #{node.name}=: (#{type}) -> #{type}", level)
      end

      lines.join("\n")
    end

    def visit_method_def(node, level)
      (+'').tap do |result|
        return_type = if node.return_type
          visit(node.return_type, level)
        else
          'untyped'
        end

        if node.return_type.is_a?(UnionType)
          return_type = "(#{return_type})"
        end

        block_arg = node.args.block_arg
        receiver = node.parent_scope.singleton? ? "self." : ""

        result << indent("def #{receiver}#{node.name}", level)
        result << ": "
        result << "#{visit(node.type_args, level)} " unless node.type_args.empty?
        result << "(#{visit(node.args, level)})"
        result << " #{visit_arg(block_arg, level)}" if block_arg
        result << " -> #{return_type}"
      end
    end

    def visit_module_def(node, level)
      (+'').tap do |result|
        result << indent("module #{visit(node.type, level)}\n", level)
        result << visit_scope(node, level + 1)
        result << indent("\nend\n", level)
      end
    end

    def visit_scope(node, level)
      lines = [node.mixins.map       { |kind, const| indent("#{kind} #{visit(const)}", level) }.join("\n")]
      lines << node.scopes.map       { |scp| visit(scp, level) }.join("\n")
      lines << node.method_defs.map  { |mtd| visit(mtd, level) }.join("\n")
      lines << node.interfaces.map   { |iface| visit(iface, level) }.join("\n")
      lines << node.type_aliases.map { |ta| visit(ta, level) }.join("\n")
      lines << node.const_assgns.map { |ca| visit(ca, level) }.join("\n")

      lines.reject(&:empty?).join("\n\n")
    end

    def visit_top_level_scope(node, level)
      (+'').tap do |result|
        result << "# typed: #{node.type_sigil}\n\n" if node.type_sigil
        result << visit_scope(node, level)
      end
    end

    def visit_type_list(node, level)
    end

    def visit_constant(node, level)
      node.name.dup
    end

    def visit_const_assgn(node, level)
      indent("#{node.const}: #{visit(node.type, level)}", level)
    end

    def visit_interface(node, level)
      indent_lines(node.definition.split("\n"), level)
    end

    def visit_type_alias(node, level)
      indent_lines(node.definition.split("\n"), level)
    end

    def visit_type(node, level)
      result = visit(node.const, level)
      result << visit(node.type_args, level) unless node.type_args.empty?
      result << "?" if node.nilable?
      result
    end

    def visit_block_type(node, level)
      "{ (#{visit(node.args, level)}) -> #{visit(node.return_type, level)} }"
    end

    def visit_proc_type(node, level)
      "^(#{visit(node.args, level)}) -> #{visit(node.return_type, level)}"
    end

    def visit_class_of(node, level)
    end

    def visit_self_type(node, level)
    end

    def visit_union_type(node, level)
      result = node.types.map { |t| visit(t, level) }.join(' | ')
      result = "(#{result})?" if node.nilable?
      result
    end

    def visit_nil_type(node, level)
      'nil'
    end

    def visit_untyped_type(node, level)
      'untyped'
    end

    def visit_void_type(node, level)
      'void'
    end

    def visit_bool_type(node, level)
      'bool'
    end

    private

    # maybe move this into AnnotationVisitor?
    def indent_lines(lines, level)
      ws = lines[-1].match(/\A\s*/)[0]
      lines.map! { |line| line.start_with?(ws) ? line[ws.size..-1] : line }
      indent(lines.join("\n"), level)
    end

    def handle_class_def(node, level)
      (+'').tap do |result|
        super_class = node.super_type ? " < #{visit(node.super_type, level)}" : ''
        result << indent("class #{visit(node.type, level)}#{super_class}\n", level)
        result << handle_class_body(node, level + 1)
        result << indent("end\n", level)
      end
    end

    def handle_singleton_class_def(node, level)
      handle_class_body(node, level)
    end

    def handle_class_body(node, level)
      lines = []

      unless node.mixins.empty?
        lines << node.mixins.map do |kind, const|
          indent("#{kind} #{visit(const, level)}", level)
        end.join("\n")
      end

      unless node.attrs.empty?
        lines << node.attrs.map { |a| visit(a, level) }.join("\n")
      end

      unless node.ivars.empty?
        lines << node.ivars.map { |ivar| visit(ivar, level) }.join("\n")
      end

      lines += node.method_defs.flat_map do |mtd|
        visit(mtd, level)
      end

      unless node.scopes.empty?
        lines << node.scopes.map { |scp| visit(scp, level) }.join("\n")
      end

      unless node.type_aliases.empty?
        lines << node.type_aliases.map { |ta| visit(ta, level) }.join("\n")
      end

      unless node.const_assgns.empty?
        lines << node.const_assgns.map { |ca| visit(ca, level) }.join("\n")
      end

      lines << ""

      lines.join("\n")
    end
  end
end
