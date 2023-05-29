# frozen_string_literal: true

require 'spec_helper'

describe 'Classes' do
  before(:each) do
    code(<<~RUBY)
      class CustomHash[K, V] < Hash[K, V]
      end
    RUBY
  end

  subject { find('CustomHash') }

  it 'parses the class definition' do
    expect(subject).to_not be_nil
    expect(subject).to have_type_arguments('K', 'V')
    expect(subject.super_type.const.to_ruby).to eq('Hash')
    expect(subject.super_type).to have_type_arguments('K', 'V')
  end
end
