# frozen_string_literal: true

module Myrb
  class Lexer < LexerInterface
    class UnexpectedTokenError < StandardError; end
    class CouldNotParseArgDefaultValueError < StandardError; end
    class SingletonClassError < StandardError; end

    include Annotations
    include TokenHelpers

    attr_reader :source_buffer, :context

    VISIBILITY_METHODS = %w(private public protected).freeze
    MIXIN_METHODS = %w(include extend prepend).freeze
    ATTR_METHODS = %w(attr_reader attr_writer attr_accessor).freeze

    def initialize(source_buffer, init_pos, context)
      super()

      @source_buffer = source_buffer
      @lexer = BaseLexer.new(source_buffer, init_pos, context)
      @generator = to_enum(:each_token)
      @current = get_next
      @context = context
      @context[:annotations] ||= TopLevelScope.new
      @top_level_scope = @context[:annotations]
      @context[:annotation_scope_stack] ||= [@top_level_scope]
      @scope_stack = @context[:annotation_scope_stack]
      @captured_tokens = []
    end

    def reset_to(pos)
      @lexer.reset_to(pos)
      @generator = to_enum(:each_token)
      @current = get_next
    end

    def advance
      @generator.next
    rescue StopIteration
      @top_level_scope.type_sigil = type_sigil
      [false, ['$eof']]
    end

    private

    def type_sigil
      @lexer.comments.each do |comment|
        if comment.text =~ /\A#\s+typed:\s+(ignore|false|true|strict|strong)\z/
          return Regexp.last_match.captures[0]
        end
      end

      nil
    end

    def current
      @current
    end

    def prev
      @prev
    end

    def current_scope
      @scope_stack.last
    end

    def push_scope(scope)
      @scope_stack.push(scope)
    end

    def pop_scope
      @scope_stack.pop
    end

    def each_token(&block)
      loop do
        break unless type_of(current)

        handle_current(block)
      end
    end

    def handle_current(block)
      case type_of(current)
        when :kMODULE
          mod = handle_module(block)
          current_scope.scopes << mod
          push_scope(mod)
        when :kCLASS
          klass = handle_class(block)
          current_scope.scopes << klass
          push_scope(klass)
        when :kDEF
          mtd = handle_def(block)
          current_scope.method_defs << mtd
          push_scope(mtd)
        when :kDO
          consume(:kDO, block)
          push_scope(BlockDef.instance)
        when :kIF, :kUNLESS, :kWHILE, :kUNTIL, :kBEGIN, :kCASE  # TODO: are there more of these?
          consume(type_of(current), block)
          push_scope(Endable.new(current_scope))
        when :kEND
          # TODO: if we encounter a kEND in the top-level scope, something went wrong.
          # Let's raise an error instead of silently ignoring.
          pop_scope unless current_scope.top_level_scope?
          consume(:kEND, block)
        when :tIDENTIFIER
          ident = text_of(current)

          case ident
            when *ATTR_METHODS
              if attrs = handle_attrs(block)
                current_scope.attrs.concat(attrs)
              end
            when *MIXIN_METHODS
              consume(:tIDENTIFIER, block)
              const, _ = handle_constant(block)
              current_scope.mixins << [ident.to_sym, const]
            when "interface"
              if (iface = maybe_handle_interface(block))
                current_scope.interfaces << iface
              end
            when "type"
              if (type_alias = maybe_handle_type_alias(block))
                current_scope.type_aliases << type_alias
              end
            else
              consume(type_of(current), block)
          end

        when :tIVAR
          ivar_token = current
          consume(type_of(ivar_token))

          if type_of(current) == :tCOLON
            consume(:tCOLON)
            ivar = handle_ivar_decl(ivar_token)
            current_scope.ivars << ivar

            if type_of(current) == :tNL
              consume(:tNL)
            end
          else
            block.call(ivar_token) if block
            consume(type_of(current), block)
          end

        when :tCONSTANT
          if (const_assgn = maybe_handle_const_assgn(block))
            current_scope.const_assgns << const_assgn
          end

        else
          consume(type_of(current), block)
      end
    end

    def maybe_handle_const_assgn(block)
      start_token = current
      tokens = [current]
      const_tokens = [current]

      consume(:tCONSTANT)

      loop do
        case type_of(current)
          when :tCONSTANT, :tCOLON2
            const_tokens << current
            tokens << current
            consume(type_of(current))
          else
            break
        end
      end

      loc = {}
      type = nil

      if type_of(current) == :tCOLON
        loc[:colon] = pos_of(current)
        tokens << current
        consume(:tCOLON)

        type_tokens = capture do
          # This will raise if we're inside a ternary or some other unexpected construct.
          # Generally if a type doesn't follow the tCOLON i.e. handle_types blows up, we
          # should assume something is wrong by setting type = nil, which will cause the
          # code below to yield all the tokens we consumed to the parser.
          type = handle_types rescue nil
        end

        tokens.concat(type_tokens)
      else
        type = UntypedType.new
      end

      if !type || type_of(current) != :tEQL
        tokens.each { |token| block.call(token) }
        return
      end

      const_tokens.each { |token| block.call(token) }
      consume(:tEQL, block)

      # This isn't quite right, but it's going to be very hard to extract the assigned value here,
      # as ExpressionBoundary doesn't seem to work :(
      loc[:expression] = pos_of(start_token).with(end_pos: pos_of(current).end_pos)
      loc[:constant] = pos_of(const_tokens.first).with(end_pos: pos_of(const_tokens.last).end_pos)

      name = const_tokens.map { |token| text_of(token) }.join("::")

      ConstAssgn.new(name, type, loc)
    end

    def maybe_handle_type_alias(block)
      tokens = [current]
      consume(:tIDENTIFIER)

      if type_of(current) == :tIDENTIFIER
        tokens << current
        consume(:tIDENTIFIER)

        if type_of(current) == :tEQL
          tokens << current
          consume(:tEQL)

          first_loc = pos_of(tokens.first)
          rbs_alias = RBSParser.parse(@lexer.source_buffer, first_loc.begin_pos)

          if rbs_alias
            loc = {
              expression: first_loc.with(
                end_pos: first_loc.begin_pos + rbs_alias.location.end_pos
              )
            }

            @lexer.reset_to(loc[:expression].end_pos)
            consume(type_of(current))

            if type_of(current) == :tNL
              consume(:tNL)
            end

            return TypeAlias.new(
              text_of(tokens[1]),
              loc[:expression].source,
              loc
            )
          end
        end
      end

      # this wasn't a type alias, so yield all tokens
      tokens.each { |t| block.call(t) }

      nil
    end

    def maybe_handle_interface(block)
      iface_token = current
      consume(:tIDENTIFIER)

      name = text_of(current)

      if interface_name?(name)
        stop_idx = source_buffer.source.index("end", pos_of(iface_token).begin_pos) + 3

        if stop_idx
          definition = source_buffer.source[pos_of(iface_token).begin_pos...stop_idx]
          loc = { expression: pos_of(iface_token).with(end_pos: stop_idx) }

          return Interface.new(name, definition, loc).tap do
            @lexer.reset_to(stop_idx)
            consume(type_of(current))

            if type_of(current) == :tNL
              consume(:tNL)
            end
          end
        end
      end

      block.call(iface_token)
      nil
    end

    def interface_name?(str)
      str =~ /\A_[A-Z]\w*\z/
    end

    def handle_ivar_decl(name_token)
      type = handle_types
      loc = {
        expression: pos_of(name_token).with(end_pos: pos_of(current).begin_pos),
        name: pos_of(name_token)
      }

      IVar.new(text_of(name_token), current_scope, type, loc)
    end

    # @TODO: handle list of attrs, eg. attr_reader foo: String, bar: String
    def handle_attrs(block)
      unless ATTR_METHODS.include?(text_of(current))
        return nil
      end

      attr_method = current
      consume(:tIDENTIFIER, block)

      name = nil
      type = UntypedType.new

      # current can either be a label with a type, or an identifier without a type
      case type_of(current)
        when :tLABEL
          ivar_token = current
          name = text_of(current)
          consume(type_of(current))
          type = handle_types

          fabricate_and_yield(
            block, [
              [:tSYMBOL, [text_of(ivar_token)]]
            ]
          )

        when :tIDENTIFIER
          name = text_of(current)
          consume(type_of(current), block)
      end

      loc = {
        expression: pos_of(attr_method).with(end_pos: pos_of(current).begin_pos),
        label: pos_of(ivar_token)
      }

      attrs = []

      case text_of(attr_method)
        when "attr_reader", "attr_accessor"
          attrs << AttrReader.new(name, type, loc)
      end

      case text_of(attr_method)
        when "attr_writer", "attr_accessor"
          attrs << AttrWriter.new(name, type, loc)
      end

      attrs
    end

    def attr_method?(token)
      ATTR_METHODS.include?(text_of(token))
    end

    def handle_class(block)
      consume(:kCLASS, block)

      # opening a singleton class
      if type_of(current) == :tLSHFT
        return handle_singleton_class(block)
      end

      class_type = handle_types
      yield_all(class_type.const.tokens, block)

      # The ruby lexer can get stuck lexing parameterized types, eg class MyClass[T]
      # and returns an EOF token when there is more input text to process. Resetting
      # fixes the problem.
      @lexer.reset_to(pos_of(current).begin_pos)
      @current = get_next

      super_type = if type_of(current) == :tLT
        consume(:tLT, block)
        handle_types.tap do |st|
          yield_all(st.const.tokens, block)
        end
      end

      ClassDef.new(class_type, super_type)
    end

    def handle_singleton_class(block)
      consume(:tLSHFT, block)

      if type_of(current) != :kSELF
        raise SingletonClassError, "Myrb does not yet support singleton classes on anything but self"
      end

      consume(:kSELF, block)
      current_scope.singleton_class_def
    end

    def handle_module(block)
      consume(:kMODULE, block)
      const, _ = handle_constant(block)
      ModuleDef.new(const)
    end

    def handle_def(block)
      @defining_method = true

      start_token = current

      consume(:kDEF, block)
      method_name = text_of(current)

      # The method name is usually a tIDENTIFIER but can be almost anything, including
      # things like tEQ (i.e. as in `def ==(other); end`), etc. We just sorta have to
      # trust that whatever comes after the `def` is the method name “¯\_(ツ)_/¯“
      consume(type_of(current), block)

      type_args = handle_type_args
      args = nil

      if type_of(current) == :tLPAREN2
        consume(:tLPAREN2, block)
        args = handle_args(block)
        consume(:tRPAREN, block)
      end

      loc = {}

      return_type = if type_of(current) == :tLAMBDA
        return_type_start_token = current
        consume(type_of(current))

        handle_types.tap do
          loc[:return_type] = pos_of(return_type_start_token).with(
            end_pos: pos_of(prev).end_pos
          )

          # If the method body starts with a reference to an instance variable,
          # the lexer for some reason does not emit a newline. This causes the
          # parser to choke, since it thinks the instance variable is part of
          # the argument list. We will likely have to re-evaluate this approach
          # for single-line methods.
          if type_of(current) != :tNL
            block.call([:tNL, [nil, nil]])
          end
        end
      else
        UntypedType.new
      end

      @defining_method = false

      loc[:expression] = pos_of(start_token).with(
        end_pos: pos_of(prev).end_pos
      )

      MethodDef.new(
        method_name,
        current_scope,
        type_args,
        args || Args.new([]),
        return_type,
        loc
      )
    end

    def handle_args(block = nil)
      in_kwargs = false

      Args.new(
        [].tap do |args|
          loop do
            break if type_of(current) == :tRPAREN

            args << arg = handle_arg(in_kwargs, block)
            in_kwargs = true if arg.splat?

            if type_of(current) == :tCOMMA
              consume(:tCOMMA, block)
            end
          end
        end
      )
    end

    def handle_arg(in_kwargs = false, block)
      start_token = current
      block_arg = false
      splat = false

      case type_of(current)
        when :tAMPER
          block_arg = true
          consume(:tAMPER, block)
        when :tSTAR
          splat = true
          consume(:tSTAR, block)
      end

      arg_name = nil
      loc = {}

      arg_type = case type_of(current)
        when :tLABEL
          label = current
          arg_name = text_of(current)

          loc[:colon] = pos_of(current).with(
            begin_pos: pos_of(current).end_pos - 1
          )

          # If in kwargs, tLABEL is correct; send it up to the parser. If not in kwargs,
          # swallow the label and send up a tIDENTIFIER positional arg instead. Since
          # the block arg comes last (and is not a keyword arg), exempt it from kwarg
          # handling even if we are currently parsing kwargs.
          if in_kwargs && !block_arg
            consume(:tLABEL, block)
          else
            consume(:tLABEL)
            block.call([:tIDENTIFIER, [arg_name, pos_of(label)]]) if block
          end

          block_arg ? handle_block_type : handle_types
        when :tIDENTIFIER
          arg_name = text_of(current)
          consume(:tIDENTIFIER, block)
          UntypedType.new
        else
          # so-called "naked" splats, i.e. "*" by itself, are allowed and indicate the
          # end of positional arguments
          unless splat
            pos = pos_of(current)
            raise UnexpectedTokenError, "expected a label or identifier when parsing arguments on line #{pos.line} column #{pos.column}"
          end
      end

      default_value_tokens = if type_of(current) == :tEQL
        loc[:default_equals] = pos_of(current)

        # if this is a kwarg, don't send tEQL to the parser since kwargs specify
        # default values after the label colon instead of an equals sign
        if in_kwargs
          consume(:tEQL)
        else
          consume(:tEQL, block)
        end

        handle_arg_default_value(block).tap do
          loc[:default_expression] = loc[:default_equals].with(
            begin_pos: loc[:default_equals].end_pos,
            end_pos: pos_of(prev).end_pos
          )
        end
      else
        []
      end

      loc[:expression] = pos_of(start_token).with(end_pos: pos_of(current).begin_pos)

      if type_of(current) == :tCOMMA
        loc[:trailing_comma] = pos_of(current)
      end

      Arg.new(
        name: arg_name,
        type: arg_type,
        loc: loc,
        block_arg: block_arg,
        kwarg: in_kwargs,
        splat: splat,
        default_value_tokens: default_value_tokens
      )
    end

    def handle_arg_default_value(block)
      range = ExpressionBoundary.find(@source_buffer, pos_of(current).begin_pos)

      unless range
        pos = pos_of(current)
        raise CouldNotParseArgDefaultValueError, "the arg default on line #{pos.line} column #{pos.column} could not be parsed"
      end

      [].tap do |tokens|
        loop do
          break if pos_of(current).end_pos > range.last

          tokens << current
          consume(type_of(current), block)
        end
      end
    end

    def handle_types
      wrapped_in_parens = false
      start_token = current
      nilable = false

      case type_of(current)
        when :tLPAREN2, :tLPAREN
          consume(type_of(current))
          wrapped_in_parens = true
        when :tLBRACK
          return handle_type_list
      end

      types = [].tap do |types|
        loop do
          types << handle_type

          if type_of(current) == :tPIPE
            consume(:tPIPE)
          else
            break
          end
        end
      end

      consume(:tRPAREN) if wrapped_in_parens

      if type_of(current) == :tEH
        nilable = true
        consume(:tEH)
      end

      stop_token = prev

      # TODO: handle intersection types as well, maybe joined with a + or & char?
      if types.size > 1
        loc = {
          expression: join_ranges(
            pos_of(start_token),
            pos_of(stop_token)
          )
        }

        UnionType.new(types, loc, nilable)
      elsif types.size == 1
        types.first
      else
        UntypedType.new
      end
    end

    def handle_type
      case type_of(current)
        when :kNIL
          return NilType.new(pos_of(current)).tap do
            consume(:kNIL)
          end
        when :tIDENTIFIER
          cls = case text_of(current)
            when 'untyped' then UntypedType
            when 'void'    then VoidType
            when 'bool'    then BoolType
          end

          if cls
            loc = {
              expression: pos_of(current)
            }

            return cls.new(loc).tap do
              consume(:tIDENTIFIER)
            end
          end
        when :tLBRACE
          return handle_block_type
        when :tCARET
          return handle_proc_type
      end

      start_token = current
      const, nilable = handle_constant
      return nil unless const

      type_args = handle_type_args

      if type_of(current) == :tEH
        nilable = true
        consume(:tEH)
      end

      stop_token = prev

      Annotations.get_type(
        const,
        type_args,
        nilable, {
          constant: pos_of(start_token),
          expression: join_ranges(
            pos_of(start_token),
            pos_of(stop_token)
          )
        }
      )
    end

    def handle_type_args
      type_args = []
      start_token = nil

      if type_of(current) == :tLBRACK2
        start_token = current
        consume(:tLBRACK2)

        until type_of(current) == :tRBRACK
          if type_args.size > 0
            consume(:tCOMMA)
          end

          type_args << handle_types
        end

        consume(:tRBRACK)
      end

      stop_token = prev

      loc = {
        expression: type_args.empty? ? nil : join_ranges(pos_of(start_token), pos_of(stop_token))
      }

      TypeArgs.new(loc, type_args)
    end

    def handle_block_type
      loc = {
        open_curly: pos_of(current)
      }

      consume(:tLBRACE)

      loc[:open_paren] = pos_of(current)
      consume(:tLPAREN)

      args = handle_args

      loc[:close_paren] = pos_of(current)
      consume(:tRPAREN)

      loc[:arrow] = pos_of(current)
      consume(:tLAMBDA)

      return_type = handle_types

      loc[:close_curly] = pos_of(current)
      consume(:tRCURLY)

      loc[:expression] = loc[:open_curly].with(end_pos: loc[:close_curly].end_pos)

      BlockType.new(loc, args, return_type)
    end

    def handle_proc_type
      @defining_method = true

      start_token = current

      consume(:tCARET)
      consume(:tLPAREN)

      args = handle_args

      consume(:tRPAREN)
      consume(:tLAMBDA)

      return_type = handle_type
      loc = {
        expression: pos_of(start_token).with(end_pos: pos_of(prev).end_pos)
      }

      @defining_method = false

      ProcType.new(loc, args, return_type)
    end

    def handle_type_list
      start_token = current
      consume(:tLBRACK)

      types = [].tap do |type_list|
        until type_of(current) == :tRBRACK
          if type_list.size > 0
            consume(:tCOMMA)
          end

          type_list << handle_type
        end

        consume(:tRBRACK)
      end

      stop_token = prev

      loc = {
        expression: join_ranges(pos_of(start_token), pos_of(stop_token)),
        open_bracket: pos_of(start_token),
        close_bracket: pos_of(stop_token),
        types: join_ranges(
          types.first.loc[:expression],
          types.last.loc[:expression]
        )
      }

      TypeList.new(types, loc)
    end

    def handle_constant(block = nil)
      if (iface_const = maybe_handle_interface_constant)
        return iface_const
      end

      nilable = false
      loc = {}

      tokens = [].tap do |const_tokens|
        loop do
          case type_of(current)
            # Identifiers are allowed because they could be type aliases. Hopefully that doesn't
            # completely screw things up, since aliases make it virtually impossible to distinguish
            # untyped keyword arguments from typed ones.
            when :tIDENTIFIER, :tCONSTANT, :tCOLON2, :tCOLON3
              const_tokens << current
              consume(type_of(current), block)
            when :tFID
              nilable = true
              const_tokens << [:tCONSTANT, [text_of(current).chomp("?"), pos_of(current).adjust(end_pos: -1)]]
              loc[:question_mark] = pos_of(current).with(begin_pos: pos_of(current).end_pos - 1)
              block.call(const_tokens.last) if block
              consume(:tFID)
              break
            else
              break
          end
        end
      end

      loc[:constant] = join_ranges(
        pos_of(tokens.first),
        pos_of(tokens.last)
      )

      loc[:expression] = join_ranges(
        pos_of(tokens.first),
        pos_of(prev)
      )

      [Constant.from_tokens(loc, tokens), nilable]
    end

    def maybe_handle_interface_constant
      type = type_of(current)
      name = text_of(current)
      pos = pos_of(current)
      nilable = false

      case type
        when :tIDENTIFIER
        when :tFID
          name = name.chomp("?")
          pos = pos.adjust(end_pos: -1)
          nilable = true
        else
          return
      end

      return unless interface_name?(name)

      loc = {
        constant: pos,
        expression: pos_of(current)
      }

      tokens = [[:tIDENTIFIER, [name, pos]]]

      [Constant.from_tokens(loc, tokens), nilable].tap do
        consume(type)
      end
    end

    def join(tokens)
      tokens.map { |t| text_of(t) }.join
    end

    def yield_all(tokens, block)
      tokens.each { |t| block.call(t) }
    end

    def fabricate_and_yield(block, tokens)
      tokens.each do |(type, (text, loc))|
        block.call([type, [text, loc || make_range(0, 0)]])
      end
    end

    def capture(&block)
      @capturing = true
      yield
      @capturing = false
      @captured_tokens.dup.tap do
        @captured_tokens.clear
      end
    end

    def consume(types, block = nil)
      types = Array(types)

      if !types.include?(type_of(current))
        raise UnexpectedTokenError,
          "expected #{to_list(types.map(&:to_s))}, got #{type_of(current)} "\
          "at #{@source_buffer.name}:#{pos_of(current).line}:#{pos_of(current).column}"
      end

      if @capturing
        @captured_tokens << current
      else
        block.call(current) if block
      end

      @prev = current

      end_pos = pos_of(current).end_pos

      # Skip over stabby lambdas (i.e. "->") because they seem to put the lexer into
      # a weird state that expects curly braces or do/end. If curly braces then appear
      # in the body of, say, a method, the lexer hands back a :tLAMBEG token when it
      # should return a tLBRACE token. We should only do this however if we're expecting
      # a "->" to indicate a return type, which is the only time Myrb uses it.
      if @defining_method && @source_buffer.source.index(/\s*(->)/, end_pos) == end_pos
        @current = [:tLAMBDA, ["->", make_range(*Regexp.last_match.offset(1))]]
        @lexer.reset_to(pos_of(current).end_pos)
        return current
      end

      @current = get_next
    end

    def to_list(items)
      if items.size == 1
        items.first
      elsif items.size == 2
        items.join(' or ')
      else
        items[0..-2].join(', ') << ' or ' << items[-1]
      end
    end

    def get_next
      @lexer.advance
    end

    def make_range(start, stop)
      ::Parser::Source::Range.new(@lexer.source_buffer, start, stop)
    end

    def join_ranges(begin_range, end_range)
      begin_range.with(end_pos: end_range.end_pos)
    end
  end
end
