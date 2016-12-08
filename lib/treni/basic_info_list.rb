require 'date'
require 'fileutils'
require 'typhoeus' # https://github.com/typhoeus/typhoeus


# Interroga Viaggiatreno su tutti i numeri da 1 a 99_999
# e salva i risultati in questa forma (è un StatusResult#basic_info ):
# 16|EC 16|S01700|12:25|MILANO CENTRALE|13:08|CHIASSO|S01700:S01322:S01301
# 17|EC 17|S01301|14:52|CHIASSO|15:35|MILANO CENTRALE|S01301:S01307:S01322:S01700
# 18|EC 18|S01700|14:25|MILANO CENTRALE|15:08|CHIASSO|S01700:S01322:S01301

# poi fa il merge dei file e fa il fix (dopo avere preventivamente fatto una copia)

# In particolare:
# - elimina le righe doppie da 'merged.txt'
# - salva le righe eliminate di cui sopra nel file 'double_lines.txt'
# - elimina le righe che non riportano un'ora di arrivo
# - salva le righe eliminate di cui sopra nel file 'no_arrival_time_lines.txt'


class BasicInfoList
  STEP = 10_000

  # dates_dir: path della dir che contiene le cartelle con le date
  # date_dir:  ev. nome della cartella con la data desiderata
  def initialize(dates_dir)
    @dates_dir = dates_dir
    @list_dir = File.join(dates_dir, Date.today.strftime("%Y-%m-%d"))
    puts @list_dir
    FileUtils.mkdir_p(@list_dir) if !Dir.exist?(@list_dir)
  end
  

  # arr 
  def fetch_all(arr=[], max_concurrency=12)
    arr = (0...10).to_a if arr.empty?
    arr.each do |k|
      offset = k * STEP
      count  = STEP
      end_at = offset+count-1

      puts "Creating list from train numbers #{offset} to #{end_at}..."

      filename = "#{offset}-#{end_at}_list.txt"
      nums = Hash[(offset..end_at).to_a.map{|e| [e, 0]}] # sarà un hash { numero_treno => nro_di_tentativi }

      File.open(File.join(@list_dir, filename), 'w') do |f|
        while(nums.empty?)
          nums = fetch(nums, f, max_concurrency: max_concurrency)
        end
      end
    end
  end



  def merge_all(merged_filename)
    most_recent_dir = Dir.glob("#{@dates_dir}/*").select{|f| File.directory? f}.last # seleziona la cartella con data più recente
    # ordino le liste
    lists = Dir.glob("#{most_recent_dir}/*_list.txt").sort{|x,y| x.split("_").first.split("-").first.to_i <=> y.split("_").first.split("-").first.to_i} # pippone per ordinare...
    puts "Start merging #{lists.size} files..."
    File.open("#{most_recent_dir}/#{merged_filename}", 'w') do |f|
      lists.each do |list|
        lines = File.readlines(list).sort{|x,y| [x.split("|")[0].to_i, x.split("|")[1]] <=> [y.split("|")[0].to_i, y.split("|")[1]]}
        # lines = File.readlines(list).sort{|x,y| x.split("|").first.to_i <=> y.split("|").first.to_i}
        lines.each do |line|
          f.write(line)
        end
      end
    end
    puts "... merge completed!"
  end


  def fix(merged_filename, date_dir: nil, duplicates_filename: "dupl_lines.txt", empty_arrival_time_filename: "empty_arrival_time_lines.txt")
    puts "Start fixing..."

    # lists_dir = Dir.glob("/Users/iwan/dev/ruby/treni/lista-thr/*").select {|f| File.directory? f}.last # selezioni cartella con data più recente
    if date_dir
      most_recent_dir = File.join(@dates_dir, date_dir)
    else
      most_recent_dir = Dir.glob("#{@dates_dir}/*").select {|f| File.directory? f}.last # seleziona la cartella con data più recente  
    end
    

    # ordino le liste
    FileUtils.mv File.join(most_recent_dir, merged_filename), File.join(most_recent_dir, "original_"+merged_filename) if File.exist? File.join(most_recent_dir, merged_filename)
    lines = File.readlines(File.join(most_recent_dir, "original_"+merged_filename))

    previous_line         = ""
    new_lines             = []
    dupl_lines            = []
    no_arrival_time_lines = []

    lines.sort.each do |line|
      line.strip!
      if line==previous_line
        dupl_lines << line
      elsif line.split("|")[5].empty?
        no_arrival_time_lines << line
      else
        new_lines << line
      end
      previous_line = line
    end

    File.open(File.join(most_recent_dir, duplicates_filename), 'w'){|f| dupl_lines.each{|l| f.write(l+"\n")}}
    File.open(File.join(most_recent_dir, merged_filename), 'w'){|f| new_lines.each{|l| f.write(l+"\n")}}
    File.open(File.join(most_recent_dir, empty_arrival_time_filename), 'w'){|f| no_arrival_time_lines.each{|l| f.write(l+"\n")}}

    puts "... fix completed!"
  end

  private
  
  def fetch(train_nums, file, max_concurrency: 12)
    # train_nums is an array with train numbers. Something like [1,2,3,4,5]
    puts "Retrieving #{train_nums.size} train statuses..."
    failed = []
    hydra = Typhoeus::Hydra.new(max_concurrency: max_concurrency) 
    puts " ... preparing requests..."
    requests = train_nums.map { |train_num|
      # puts train_num if train_num%10==0
      train_search_request = Typhoeus::Request.new(Viaggiatreno.train_search_uri(train_num))
      train_search_request.on_complete do |response|
        Viaggiatreno.read_train_search(response.body).each do |ti| # ti: TrainInfo obj
          uri = Viaggiatreno.train_status_uri(ti.departure_station.code, train_num)
          status_request = Typhoeus::Request.new(uri)
          status_request.on_complete do |response2|
            
            # puts r.basic_info
            begin
              r = Viaggiatreno.read_train_status(response2.body, train_num, ti.departure_station.code)
              string = r.basic_info
              # puts string
              file.write(string + "\n") if string
            rescue StatusResultParsingError => e
              failed << train_num
            rescue RuntimeError => e
              failed << train_num
            end
          end
          hydra.queue(status_request)
        end
      end
      hydra.queue(train_search_request)
    }
    puts " ... running requests..."
    hydra.run
    failed
  end

end


