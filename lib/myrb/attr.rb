# frozen_string_literal: true

module Myrb
  class Attr < Annotation
    attr_reader :name, :type, :loc

    def initialize(name, type, loc)
      @name = name
      @type = type
      @loc = loc
    end

    def to_rbi(level)
      indent("#{sig}\n#{kind} #{name}", level)
    end

    def to_rbs(level)
      indent("#{name}: #{type.sig}", level)
    end

    def accept(visitor, level)
      visitor.visit_attr(self, level)
    end
  end

  class AttrReader < Attr
    def kind
      'attr_reader'
    end

    def sig
      "sig { returns(#{ivar.sig}) }"
    end

    def method_sym
      sym(method_str)
    end

    def method_str
      ivar.bare_name
    end
  end

  class AttrWriter < Attr
    def kind
      'attr_writer'
    end

    def sig
      "sig { params(#{sym_join(ivar.bare_name, ivar.sig)}).void }"
    end

    def method_sym
      sym(method_str)
    end

    def method_str
      "#{ivar.bare_name}="
    end
  end
end
