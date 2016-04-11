

class BaseInfo
  attr_reader :num, :name, :dep_station_code, :dep_time, :dep_station_name
  attr_reader :arr_time, :arr_station_name, :duration, :station_codes
  attr_reader :dep_datetime, :arr_datetime

  FIELDS_SEP   = "|"
  STATIONS_SEP = ":"

  # Il fetcher viene utilizzato per il logger
  # bi_string: 21|EC 21|S01301|18:52|CHIASSO|19:35|MILANO CENTRALE|00:43|S01301:S01322:S01700
  def initialize(bi_string: nil, yml_content: nil, fetcher: nil, current_time: Time.now)
    # alternativamente mi passa bi_string oppure yml_content

    # bi_string: 21|EC 21|S01301|18:52|CHIASSO|19:35|MILANO CENTRALE|00:43|S01301:S01322:S01700
    # yml_content: "..."
    if bi_string
      arr               = bi_string.strip.split(FIELDS_SEP)
      @num              = arr[0]
      @name             = arr[1]
      @dep_station_code = arr[2]
      @dep_time         = BBTime.new(arr[3])
      @dep_station_name = arr[4]
      @arr_time         = BBTime.new(arr[5])
      @arr_station_name = arr[6]
      @duration         = BBTime.new(arr[7])
      if arr[8].nil?
        @station_codes = []
        fetcher.log("#{code} has no station codes", @num, @dep_station_code) if fetcher
      else
        @station_codes  = arr[8].split(STATIONS_SEP)
      end

    elsif yml_content # in realtà è un testo json
      @num              = yml_content['numeroTreno']        # "21"
      @name             = yml_content['compNumeroTreno']    # "EC 21"
      @dep_station_code = yml_content['idOrigine']          # "N00001"
      @dep_time         = BBTime.new(yml_content['compOrarioPartenza']) # "18:52"
      @arr_time         = BBTime.new(yml_content['compOrarioArrivo'])   # "19:35"
      @dep_station_name = yml_content['origine']            # "CHIASSO"
      @arr_station_name = yml_content['destinazione']       # "MILANO CENTRALE"
      @duration         = BBTime.new(yml_content['compDurata'])         # "00:43"
      if yml_content['fermate']
        @station_codes  = yml_content['fermate'].map{|e| e["id"]} # lista (array) delle fermate (loro id)
      else
        puts "No 'fermate' found per: #{@dep_station_code}/#{@num}"
        @station_codes  = []
        # raise StatusResultParsingError.new(@train_num), "Problem parsing JSON"
      end
    end
    set_datetime_attributes(current_time)
  end


  def code
    "#{@num}|#{@dep_station_code}"
  end

  def no_arrival_time?
    @arr_time.to_s.empty?
  end

  def to_s
    [@num, @name, @dep_station_code, @dep_time.to_s, @dep_station_name, @arr_time.to_s, @arr_station_name, @duration.to_s, @station_codes.join(STATIONS_SEP)].join(FIELDS_SEP)
  end

  def dep_date
    @dep_datetime.to_date
  end

  def arr_date
    @arr_datetime.to_date
  end

  private

  def set_datetime_attributes(t=Time.now)
    bb_t = BBTime.new(t)

    @arr_datetime = Time.new(t.year, t.month, t.day, @arr_time.hours, @arr_time.minutes)




    if @dep_time.to_s < @arr_time.to_s
      @dep_datetime = Time.new(t.year, t.month, t.day, @dep_time.hours, @dep_time.minutes)
    else # partito il giorno prima
      d = t.to_date-1
      @dep_datetime = Time.new(d.year, d.month, d.day, @dep_time.hours, @dep_time.minutes)
    end

    # if @arr_time.to_s < bb_t.to_s
    #   @arr_datetime = Time.new(t.year, t.month, t.day, @arr_time.hours, @arr_time.minutes)
    # else # partito il giorno prima
    #   d = t.to_date-1
    #   @arr_datetime = Time.new(d.year, d.month, d.day, @arr_time.hours, @arr_time.minutes)
    # end
  end

  #
  def hour(time)

  end
end
