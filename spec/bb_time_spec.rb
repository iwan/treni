require 'spec_helper'


describe BBTime do
  it 'initialize with string' do
    expect(BBTime.new("08:23")).to eq("08:23")
  end

  it 'initialize with time' do
    t = Time.new(2014, 05, 03, 8, 23)
    expect(BBTime.new(t)).to eq("08:23")
  end

  it 'raise error when initialize with a number' do
    expect { BBTime.new(10) }.to raise_error
  end

  it 'work with truncated bb_time 1' do
    expect(BBTime.new("8:23")).to eq("08:23")
  end

  it 'work with truncated bb_time 2' do
    expect(BBTime.new("23")).to eq("00:23")
  end

  it 'get hour number' do
    expect(BBTime.new("14:23").hour).to eq(14)
  end

  it 'get minutes number' do
    expect(BBTime.new("08:03").minute).to eq(3)
  end
end
