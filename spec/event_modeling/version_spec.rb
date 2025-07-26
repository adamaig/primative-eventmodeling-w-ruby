# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'EventModeling::VERSION' do
  it 'is defined' do
    expect(defined?(EventModeling::VERSION)).to eq('constant')
  end

  it 'is a string' do
    expect(EventModeling::VERSION).to be_a(String)
  end

  it 'follows semantic versioning format' do
    expect(EventModeling::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end

  it 'is the expected version' do
    expect(EventModeling::VERSION).to eq('1.0.0')
  end

  it 'is accessible from the main module' do
    expect(EventModeling::VERSION).to eq(EventModeling::VERSION)
  end
end
