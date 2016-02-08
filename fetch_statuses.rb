require_relative 'train_status'
require_relative 'viaggiatreno'
require 'date'
require 'fileutils'
require 'typhoeus' # https://github.com/typhoeus/typhoeus

# TODO:
# - salva in file di log gli errori

module TrainStatu


  class BaseInfo
    attr_reader :num, :name, :dep_station_code, :dep_time, :dep_station_name, :arr_time, :arr_station_name, :station_codes
    def initialize(string, fetcher)
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
        fetcher.log("#{code} has no station codes", num, dep_station_code)
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


  class Fetcher

    def initialize(status_dates_dir, list_file_path)
      @base_path      = status_dates_dir
      @list_file_path = list_file_path  # il file con la lista con le base_info
      @today          = Date.today.strftime("%Y-%m-%d")
      @yesterday      = (Date.today-1).strftime("%Y-%m-%d")
    end

    def run(force_rewrite: false, max_concurrency: 12)
      @force_rewrite = force_rewrite

      @hydra = Typhoeus::Hydra.new(max_concurrency: max_concurrency)
      @today_files     = Dir.glob(File.join(today_dir, "*.json")).map{|f| File.basename(f)}
      @yesterday_files = Dir.glob(File.join(yesterday_dir, "*.json")).map{|f| File.basename(f)}

      count = 0

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
                log "#{base_info.code} already fetched...", base_info.num, base_info.dep_station_code
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


    def log(message, train_num=nil, dep_station_code=nil)
      if train_num && dep_station_code
        uri = " [#{Viaggiatreno.train_status_uri(dep_station_code, train_num)}]"
      else  
        uri = ""
      end
      @log_lines << "   #{message}#{uri}"
    end



    private

    def status_filename(train_num, dep_station_code, whhen)
      dir = whhen==:yesterday ? yesterday_dir : today_dir
      File.join(dir, "#{train_num}-#{dep_station_code}.json")
    end


    def fetch_and_write_status(base_info, filename)
      train_num        = base_info.num
      dep_station_code = base_info.dep_station_code
      uri              = Viaggiatreno.train_status_uri(dep_station_code, train_num)
      status_request   = Typhoeus::Request.new(uri)

      status_request.on_complete do |response|
        status_result = StatusResult.new(response.body)

        arrived = false
        begin
          ts_hash = status_result.hash
          arrived = treno_arrivato?(ts_hash)
        rescue NoMethodError => e
          puts e.message
          log "Problem on reading arrival time for #{base_info.code}...", base_info.num, base_info.dep_station_code
        rescue StatusResultParsingError => e
          log "#{e.message} for #{base_info.code}...", base_info.num, base_info.dep_station_code
        end
        
        if arrived
          @file_count += 1
          File.open(filename, 'w'){|f| f.write(status_result)}
        else
          log "#{base_info.code} has not arrived yet...", base_info.num, base_info.dep_station_code
        end
      end
      @hydra.queue(status_request)
      # TODO: scrivi anche per quelli che dovevano arrivare da almeno 2 h
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
      File.join(@base_path, @today, "logging.txt")
    end

    def yesterday_log_path
      File.join(@base_path, @yesterday, "logging.txt")
    end

    def log_start
      @log_lines << "\n\n#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}  ---------------"
    end

    # TODO: refactor!
    def treno_arrivato?(hash)
      !hash["fermate"].last["arrivoReale"].nil?
    end

  end
  
end





statuses_dir = File.join(Dir.home, "dev", "ruby", "treni", "statuses")
lists_dir = Dir.glob("/Users/iwan/dev/ruby/treni/lista-thr/*").select {|f| File.directory? f}.last # selezioni cartella con data più recente
list_path = File.join(lists_dir, "merged.txt")

fetcher = TrainStatu::Fetcher.new(statuses_dir, list_path)
fetcher.run


# Added 5644 train status files
# ruby fetch_statuses.rb  13.75s user 7.22s system 10% cpu 3:17.03 total