# frozen_string_literal: true

RSpec::Matchers.define :have_arg do |arg_name|
  match do |callable|
    callable.args.find { |arg| arg.name == arg_name }
  end

  failure_message do |callable|
    msg = "expected callable "
    msg = if callable.name
      msg + "##{callable.name}` "
    end
    msg + "to accept an argument named '#{arg_name}'"
  end
end

RSpec::Matchers.define :have_args do |*arg_names|
  match do |callable|
    @matching_args = callable.args.select { |arg| arg_names.include?(arg.name) }
    @matching_args.size == arg_names.size ? @matching_args : nil
  end

  failure_message do |method_def|
    msg = "expected callable "
    msg = if callable.name
      msg + "##{callable.name}` "
    end
    msg + "to accept arguments named #{arg_names.join(', ')} but found #{@matching_args.map(&:name).join(', ')}"
  end
end
