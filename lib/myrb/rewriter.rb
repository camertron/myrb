# frozen_string_literal: true

module Myrb
  class Rewriter < ::Parser::TreeRewriter
    attr_reader :annotator

    def initialize(annotations)
      @annotator = Annotator.new(annotations)
    end

    def on_module(node)
      annotator.on_module(node) do |module_def|
        handle_module_def(module_def)
        super
      end
    end

    def on_class(node)
      annotator.on_class(node) do |class_def|
        handle_class_def(class_def)
        super
      end
    end

    def on_def(node)
      annotator.on_def(node) do |method_def|
        handle_method_def(method_def)
        super
      end
    end

    def on_argument(node)
      annotator.on_argument(node) do |arg, idx|
        handle_argument(arg, idx)
        super
      end
    end

    def on_sclass(node)
      annotator.on_sclass(node) do |sclass|
        super
      end
    end

    def starts_line?(range)
      nl_idx = range.source_buffer.source.rindex("\n", range.begin_pos)
      return true unless nl_idx

      !!(range.source_buffer.source[(nl_idx + 1)...range.begin_pos] =~ /\A\s*\z/)
    end

    def rstrip(range)
      idx = range.source_buffer.source.index(/\S/, range.end_pos)
      range.with(end_pos: idx)
    end

    def lstrip(range)
      idx = range.source_buffer.source.rindex(/\S/, range.begin_pos - 1)
      range.with(begin_pos: idx + 1)
    end

    def smart_strip(range)
      if starts_line?(range)
        rstrip(range)
      else
        lstrip(range)
      end
    end

    def on_send(node)
      annotator.on_send(node) do |send_type, annotation|
        case send_type
          when :attr
            handle_attr(annotation)
        end
      end

      super
    end

    private

    def handle_module_def(module_def)
      handle_ivars(module_def)
      handle_interfaces(module_def)

      if module_def.has_singleton_class?
        handle_class_def(module_def.singleton_class_def)
      end
    end

    def handle_class_def(class_def)
      if class_def.type.has_args?
        remove(class_def.type.type_args.loc[:expression])
      end

      handle_module_def(class_def)
    end

    def handle_method_def(method_def)
      unless method_def.type_args.empty?
        remove(rstrip(method_def.type_args.loc[:expression]))
      end

      if return_type_loc = method_def.loc[:return_type]
        remove(return_type_loc)
      end
    end

    def handle_argument(arg, idx)
      if arg.kwarg?
        remove(
          if arg.default_value?
            # remove from after colon to after default equals
            arg.loc[:colon].with(
              begin_pos: arg.loc[:colon].end_pos,
              end_pos: arg.loc[:default_equals].end_pos
            )
          else
            # no default value, so remove the type and whitespace
            arg.loc[:colon].with(
              begin_pos: arg.loc[:colon].end_pos,
              end_pos: arg.type.loc[:expression].end_pos
            )
          end
        )
      elsif arg.naked_splat?
        remove(arg.loc[:expression])
      else
        # remove the type if present
        if colon_loc = arg.loc[:colon]
          remove(colon_loc.with(end_pos: arg.type.loc[:expression].end_pos))
        end
      end

      next_arg = annotator.arg_by_idx(idx + 1)

      if next_arg && next_arg.naked_splat?
        if comma_loc = arg.loc[:trailing_comma]
          remove(smart_strip(comma_loc))
        end
      end
    end

    def handle_attr(ivar)
      # TODO: handle symbols with special characters
      replace(ivar.loc[:label], ":#{ivar.name}")
      remove(ivar.type.loc[:expression]) rescue binding.irb
    end

    def handle_ivars(scope)
      scope.ivars.each do |ivar|
        remove(smart_strip(ivar.loc[:expression]))
      end
    end

    def handle_interfaces(scope)
      scope.interfaces.each do |iface|
        remove(smart_strip(iface.loc[:expression]))
      end
    end

    def join_ranges(begin_range, end_range)
      begin_range.with(end_pos: end_range.end_pos)
    end
  end
end
