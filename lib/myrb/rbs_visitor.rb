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
      (+'').tap do |result|
        type_args = if node.type.has_args?
          (+'[').tap do |ta|
            node.type.type_args.map.with_index do |type_arg, idx|
              ta << ', ' if idx > 0
              ta << "#{visit(type_arg, level)}"
            end

            ta << ']'
          end
        end

        super_class = node.super_type ? " < #{visit(node.super_type, level)}" : ''
        result << indent("class #{visit(node.type, level)}#{type_args}#{super_class}\n", level)

        lines = []

        unless node.mixins.empty?
          lines << node.mixins.map do |kind, const|
            indent("#{kind} #{visit(const, level)}", level + 1)
          end.join("\n")
        end

        unless node.attrs.empty?
          lines << node.attrs.map { |a| visit(a, level + 1) }.join("\n")
        end

        unless node.ivars.empty?
          lines << node.ivars.map { |ivar| visit(ivar, level + 1) }.join("\n")
        end

        lines += node.method_defs.flat_map do |mtd|
          visit(mtd, level + 1)
        end

        unless node.scopes.empty?
          lines << scopes.map { |scp| visit(scp, level + 1) }.join("\n")
        end

        result << lines.join("\n")
        result << indent("\nend\n", level)
      end
    end

    def visit_ivar(node, level)
      indent("#{node.name}: #{visit(node.type, level)}", level)
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
          'void'
        end

        block_arg = node.args.block_arg

        result << indent("def #{node.name}", level)
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
        result << indent("end\n", level)
      end
    end

    def visit_scope(node, level)
      lines = [node.mixins.map      { |kind, const| indent("#{kind} #{visit(const)}", level) }.join("\n")]
      lines << node.scopes.map      { |scp| visit(scp, level) }.join("\n")
      lines << node.method_defs.map { |mtd| visit(mtd, level) }.join("\n")

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
      str = node.tokens.map { |_, (text, _)| text }.join
      str << (node.nilable? ? '?' : '')
      str
    end

    def visit_type(node, level)
      visit(node.const, level)
    end

    def visit_proc_type(node, level)
      "{ (#{visit(node.args, level)}) -> #{visit(node.return_type, level)} }"
    end

    def visit_array_type(node, level)
      "Array[#{visit(node.elem_type, level)}]"
    end

    def visit_set_type(node, level)
    end

    def visit_hash_type(node, level)
      "Hash[#{visit(node.key_type, level)}, #{visit(node.value_type, level)}]"
    end

    def visit_range_type(node, level)
    end

    def visit_enumerable_type(node, level)
    end

    def visit_enumerator_type(node, level)
    end

    def visit_class_of(node, level)
    end

    def visit_self_type(node, level)
    end

    def visit_union_type(node, level)
      node.types.map { |t| visit(t, level) }.join(' | ')
    end

    def visit_nil_type(node, level)
      'nil'
    end

    def visit_untyped_type(node, level)
      'untyped'
    end
  end
end
