require 'spec_helper'
require 'date'

describe BaseInfo do
  let(:bi_string) { "21|EC 21|S01301|18:52|CHIASSO|19:35|MILANO CENTRALE|00:43|S01301:S01322:S01700" }

  describe ".initialize with bi_string" do
    let(:base_info) { BaseInfo.new(bi_string: bi_string) }

    it 'read num' do
      expect(base_info.num).to eq("21")
    end
    it 'read name' do
      expect(base_info.name).to eq("EC 21")
    end
    it 'get code' do
      expect(base_info.code).to eq("21|S01301")
    end
    it 'read dep_station_code' do
      expect(base_info.dep_station_code).to eq("S01301")
    end
    it 'read dep_time' do
      expect(base_info.dep_time.to_s).to eq("18:52")
    end
    it 'read dep_station_name' do
      expect(base_info.dep_station_name).to eq("CHIASSO")
    end
    it 'read arr_time' do
      expect(base_info.arr_time.to_s).to eq("19:35")
    end
    it 'read arr_station_name' do
      expect(base_info.arr_station_name).to eq("MILANO CENTRALE")
    end
    it 'read duration' do
      expect(base_info.duration.to_s).to eq("00:43")
    end
    it 'read station_codes size' do
      expect(base_info.station_codes).to eq(["S01301", "S01322", "S01700"])
    end
    it 'has no_arrival_time?' do
      expect(base_info.no_arrival_time?).to eq(false)
    end
    it '.to_s' do
      expect(base_info.to_s).to eq(bi_string)
    end

    it 'get dep_date' do
      t = Time.new(2015, 5, 3, 19, 8)
      bi = BaseInfo.new(bi_string: bi_string, current_time: t)
      expect(bi.dep_date).to eq(Date.new(2015, 5, 3))
    end
    it 'read dep_datetime' do
      t = Time.new(2015, 5, 3, 19, 8)
      bi = BaseInfo.new(bi_string: bi_string, current_time: t)
      expect(bi.dep_datetime).to eq(Time.new(2015, 5, 3, 18, 52))
    end
    it 'get arr_date' do
      t = Time.new(2015, 5, 3, 19, 8)
      bi = BaseInfo.new(bi_string: bi_string, current_time: t)
      expect(bi.arr_date).to eq(Date.new(2015, 5, 3))
    end
    it 'read arr_datetime' do
      t = Time.new(2015, 5, 3, 19, 8)
      bi = BaseInfo.new(bi_string: bi_string, current_time: t)
      expect(bi.arr_datetime).to eq(Time.new(2015, 5, 3, 19, 35))
    end
    it 'read arr_datetime transday delay' do
      t = Time.new(2015, 5, 3, 0, 20)
      bi_s = "21|EC 21|S01301|18:52|CHIASSO|23:55|MILANO CENTRALE|00:43|S01301:S01322:S01700"
      bi = BaseInfo.new(bi_string: bi_s, current_time: t)
      expect(bi.arr_datetime).to eq(Time.new(2015, 5, 3, 19, 35))
    end

  end

end
