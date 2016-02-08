class Fetcher

  def initialize(status_dates_dir, list_file_path)
    @base_path      = status_dates_dir
    @list_file_path = list_file_path  # il file con la lista con le base_info
  end

  # Scorre il file con la lista dei treni, prova ad aggiungere la lista delle
  # stazioni a quei treni a cui manca
  def fix_list_file(list_file_path=@list_file_path)
    puts "Start fixing list file (i will complete information about stations)"
    arr = []
    count = 0
    # lines = File.readlines(@list_file_path).select{|line| BaseInfo.new(line).station_codes.empty? }
    # puts lines.size
    File.readlines(@list_file_path).each do |line|
      base_info = BaseInfo.new(line)
      if base_info.station_codes.empty?
        uri = Viaggiatreno.train_status_uri(base_info.dep_station_code, base_info.num)
        response = Typhoeus.get(uri).body
        begin
          line = Viaggiatreno.read_train_status(response, base_info.num).basic_info+"\n"
          # puts line
          count +=1
        rescue StatusResultParsingError => e
          puts "Lista delle stazioni non trovata per #{base_info.num}|#{base_info.dep_station_code}"
        ensure
          arr << line
        end
      else
        arr << line
      end
    end
    puts arr.size
    File.write(list_file_path, arr.join)
    if count==0
      puts "No train updated"
    else
      puts "Udated #{count} train(s)"
    end
  end

  def run(force_rewrite: false, max_concurrency: 12)
    @force_rewrite   = force_rewrite
    @today_files     = Dir.glob(File.join(today_dir, "*.json")).map{|f| File.basename(f)}
    @yesterday_files = Dir.glob(File.join(yesterday_dir, "*.json")).map{|f| File.basename(f)}
    @hydra           = Typhoeus::Hydra.new(max_concurrency: max_concurrency)

    count = 0
    puts "\n\n#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} -----------------\n" 
    begin
      @log_lines = []
      @log_file = File.open(today_log_path, "a")

      log_start
      @file_count = 0

      File.readlines(@list_file_path).each do |line|
        # line: 88|EC 88|S02430|09:04|VERONA PORTA NUOVA|11:48|BRENNERO|S02430:S02044:S02038:S02026:S02014:S02011:S02001
        now       = Time.now.strftime("%H:%M")
        base_info = BaseInfo.new(line, self)
        whhen     = base_info.dep_time<now ? :today : :yesterday
        if base_info.no_arrival_time?
          # se il file 'merged.txt' è pulito, questa ipotesi non dovrebbe mai succedere
          log "No arrival time found for #{base_info.code}", base_info.num, base_info.dep_station_code
        else
          filename = status_filename(base_info.num, base_info.dep_station_code, whhen)

          if File.exist?(filename) and !@force_rewrite
              # log "#{base_info.code} already fetched...", base_info.num, base_info.dep_station_code
          else
            if base_info.arr_time<Time.now.strftime("%H:%M")
              fetch_and_write_status(base_info, filename)
              count+=1
            end
          end
        end
        # break if count>10 # <<<<==============
      end
      puts "Starting download #{count} train statuses..."
      @hydra.run

    rescue Exception => e
      puts e
      @log_lines << "!!! Something get wrong !!! Exit here."

    ensure
      @log_lines.each{|line| @log_file.write(line+"\n")}
      @log_file.close
      puts "Added #{@file_count} train status files"
    end
  end


  def log(message, train_num=nil, dep_station_code=nil, puts_on_screen_too: false)
    if train_num && dep_station_code
      uri = " [#{Viaggiatreno.train_status_uri(dep_station_code, train_num)}]"
    else  
      uri = ""
    end
    @log_lines << "   #{message}#{uri}"
    puts "#{message}#{uri}" if puts_on_screen_too
    # File.open(today_log_path, "a"){|f| f.write("   #{message}#{uri}\n")}
  end



  private

  def status_filename(train_num, dep_station_code, whhen)
    dir = whhen==:yesterday ? yesterday_dir : today_dir
    File.join(dir, "#{train_num}-#{dep_station_code}.json")
  end


  def fetch_and_write_status(base_info, filename)
    train_num        = base_info.num
    dep_station_code = base_info.dep_station_code
    # filename         = status_filename(train_num, dep_station_code, whhen)
    uri              = Viaggiatreno.train_status_uri(dep_station_code, train_num)
    status_request   = Typhoeus::Request.new(uri)

    status_request.on_complete do |response|
      status_result = StatusResult.new(response.body)

      arrived = false
      begin
        ts_hash = status_result.hash
        # puts "----> #{status_result.train_status.orario_partenza}"
        # puts ts_hash.inspect
        
        arrived = treno_arrivato?(ts_hash)
      rescue NoMethodError => e
        log "Problem on reading arrival time for #{base_info.code}...", base_info.num, base_info.dep_station_code
      rescue StatusResultParsingError => e
        log "#{e.message} for #{base_info.code}...", base_info.num, base_info.dep_station_code
      end
      
      if arrived
        @file_count += 1
        File.open(filename, 'w'){|f| f.write(status_result)}
        # log "booking #{base_info.code}...", base_info.num, base_info.dep_station_code
        # return true
      else
        log "#{base_info.code} has not arrived yet...", base_info.num, base_info.dep_station_code
      end
    end
    @hydra.queue(status_request)

    # TODO: scrivi anche per quelli che dovevano arrivare da almeno 2 h
    # false
  end



  # Today status dir
  def today_dir
    d = File.join(@base_path, Date.today.strftime("%Y-%m-%d"))
    FileUtils.mkdir_p(d) if !Dir.exist?(d)
    d
  end
  
  # Yesterday status dir
  def yesterday_dir
    d = File.join(@base_path, (Date.today-1).strftime("%Y-%m-%d"))
    FileUtils.mkdir_p(d) if !Dir.exist?(d)
    d
  end

  def today_log_path
    File.join(today_dir, "logging.txt")
  end

  def yesterday_log_path
    File.join(yesterday_dir, "logging.txt")
  end

  def log_start
    @log_lines << "\n\n#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}  ---------------"
  end

  # TODO: refactor!
  def treno_arrivato?(hash)
    !hash["fermate"].last["arrivoReale"].nil?
  end

end
