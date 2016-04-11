require 'spec_helper'

describe Time do
  describe "#to_bb" do
    it 'return a BBTime object' do
      expect(Time.now.to_bb.class).to eq(BBTime)
    end

    it 'read time' do
      expect(Time.new(2015,5,3,14,3).to_bb).to eq("14:03")
    end

  end
end
