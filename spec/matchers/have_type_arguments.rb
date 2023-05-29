# frozen_string_literal: true

RSpec::Matchers.define :have_type_arguments do |*type_strs|
  match do |object|
    @kind = 'unknown'
    @type_args = []

    case object
      when Myrb::ClassDef
        @kind = 'class'
        @type_args = object.type.type_args
      when Myrb::Annotation
        @kind = 'annotation'
        @type_args = object.type_args
      when Myrb::MethodDef
        @kind = 'method'
        # Not yet implemented
    end

    @type_args.map(&:inspect) == type_strs
  end

  failure_message do
    "expected #{@kind} to have type arguments of [#{type_strs.join(', ')}] but instead it had type arguments of #{@type_args.inspect}"
  end
end