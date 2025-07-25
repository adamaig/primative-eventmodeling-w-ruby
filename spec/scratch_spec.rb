require 'spec_helper'

describe Scratch do
  include Scratch

  describe "scratch" do
    it { expect(1).to eq(2) }
  end
end
