# frozen_string_literal: true

module Myrb
  class Rewriter < ::Parser::TreeRewriter
    attr_reader :annotator

    def initialize(annotations)
      @annotator = Annotator.new(annotations)
    end

    def on_module(node)
      annotator.on_module(node) { super }
    end

    def on_class(node)
      annotator.on_class(node) do |class_def|
        if class_def.type.has_args?
          remove(class_def.type.type_args.loc[:expression])
        end

        super
      end
    end

    def on_def(node)
      annotator.on_def(node) do |method_def|
        if return_type_loc = method_def.loc[:return_type]
          remove(return_type_loc)
        end

        super
      end
    end

    def on_argument(node)
      annotator.on_argument(node) do |arg|
        # TODO: handle keyword arguments
        if colon_loc = arg.loc[:colon]
          remove(colon_loc.with(end_pos: arg.type.loc[:expression].end_pos))
        end

        super
      end
    end

    def on_send(node)
      annotator.on_send(node) do |send_type, annotation|
        case send_type
          when :ivar
            handle_ivar(annotation)
        end
      end

      super
    end

    private

    def handle_ivar(ivar)
      # TODO: handle symbols with special characters
      replace(ivar.loc[:label], ":#{ivar.name}")
      remove(ivar.type.loc[:expression])
    end

    def join_ranges(begin_range, end_range)
      begin_range.with(end_pos: end_range.end_pos)
    end
  end
end
