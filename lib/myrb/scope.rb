# frozen_string_literal: true

module Myrb
  class Scope < Annotation
    attr_reader :type, :method_defs, :scopes, :ivars, :mixins

    def initialize(type)
      @type = type
      @method_defs = []
      @scopes = []
      @ivars = []
      @mixins = []
    end

    def to_rbi(level)
      lines = [mixins.map   { |kind, const| indent("#{kind} #{const.to_ruby}", level) }.join("\n")]
      lines << scopes.map   { |scp| scp.to_rbi(level) }.join("\n")
      lines << method_defs.map  { |mtd| mtd.to_rbi(level) }.join("\n")

      lines.reject(&:empty?).join("\n\n")
    end

    def to_rbs(level)
      lines = [mixins.map   { |kind, const| indent("#{kind} #{const.to_ruby}", level) }.join("\n")]
      lines << scopes.map   { |scp| scp.to_rbs(level) }.join("\n")
      lines << method_defs.map  { |mtd| mtd.to_rbs(level) }.join("\n")

      lines.reject(&:empty?).join("\n\n")
    end

    def accept(visitor, level)
      visitor.visit_scope(self, level)
    end

    def top_level_scope?
      false
    end
  end
end