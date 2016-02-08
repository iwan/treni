

class BaseInfo
  attr_reader :num, :name, :dep_station_code, :dep_time, :dep_station_name, :arr_time, :arr_station_name, :station_codes
  def initialize(string, fetcher=nil)
    # string: 21|EC 21|S01301|18:52|CHIASSO|19:35|MILANO CENTRALE|S01301:S01322:S01700
    arr               = string.strip.split("|")
    @num              = arr[0]
    @name             = arr[1]
    @dep_station_code = arr[2]
    @dep_time         = arr[3]
    @dep_station_name = arr[4]
    @arr_time         = arr[5]
    @arr_station_name = arr[6]
    if arr[7].nil?
      @station_codes = []
      fetcher.log("#{code} has no station codes", num, dep_station_code) if fetcher
    else
      @station_codes  = arr[7].split(":")  
    end
  end

  def code
    "#{@num}|#{@dep_station_code}"
  end

  def no_arrival_time?
    @arr_time.empty?
  end
end