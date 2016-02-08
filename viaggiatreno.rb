require 'net/http'
require 'json'
require 'http'
# require_relative 'train_status'


# require 'ostruct'

# classe relativa alla stazione
class Station
  attr_reader :code, :name
  def initialize(code, name)
    @code = code
    @name = name
  end
end


# classe relativa al binomio numero_treno e stazione di partenza
class TrainInfo
  attr_reader :train_num, :departure_station
  def initialize(train_num, departure_station)
    @train_num = train_num
    @departure_station = departure_station
  end
end

# classe relativa all'errore generato nel corso del parsing
# del risultato ad una richiesta di status del treno
class StatusResultParsingError < Exception
  attr_reader :train_num

  def initialize(train_num)
    @train_num = train_num
  end
end


# classe relativa al risultato di una richiesta di status del treno
# Sarà una stringa contenente le info dello status in formato json
class StatusResult < String
  attr_accessor :train_num
  
  def hash
    return @hash unless @hash.nil?
    begin
      @hash = JSON.parse(self)
    rescue Exception => e #  JSON::ParserError => e
      raise StatusResultParsingError.new(@train_num), "Problem parsing JSON"
    end
  end
  alias_method :to_hash, :hash

  def train_status
    return @ts unless @ts.nil?
    begin
      @ts = TrainStatus.parse_json(self)
    rescue Exception => e #  JSON::ParserError => e
      raise StatusResultParsingError.new(@train_num), "Problem parsing JSON"
    end
  end

  def basic_info
    num_treno_comp = hash['compNumeroTreno'] # "EC 21"
    num_treno      = hash['numeroTreno']  #  "21"
    orario_part    = hash['compOrarioPartenza']
    orario_arr     = hash['compOrarioArrivo']
    id_origine = hash['idOrigine']
    orig = hash['origine']
    dest = hash['destinazione']
    if hash['fermate']
      fermate = hash['fermate'].map{|e| e["id"]} # lista (array) delle fermate (loro id)
    else
      puts "No 'fermate' found per: #{id_origine}/#{num_treno}"
      raise StatusResultParsingError.new(@train_num), "Problem parsing JSON"
    end
    # "#{num_treno}|#{num_treno_comp}|#{id_origine}|#{orario_part}|#{orig}|#{orario_arr}|#{dest}"
    "#{num_treno}|#{num_treno_comp}|#{id_origine}|#{orario_part}|#{orig}|#{orario_arr}|#{dest}|#{fermate.join(':')}"
  end
end


# classe relativa al risultato di una richiesta di status del treno
# Sarà una stringa contenente le info dello status in formato json
# deprecato
class PrevStatusResult < String
  attr_accessor :train_num
  
  def to_hash

    begin
      JSON.parse(self)
    rescue Exception => e #  JSON::ParserError => e
      raise StatusResultParsingError.new(@train_num), "Problem parsing JSON"
    end
  end

  def basic_info
    hash = self.to_hash
    num_treno_comp = hash['compNumeroTreno'] # "EC 21"
    num_treno      = hash['numeroTreno']  #  "21"
    orario_part    = hash['compOrarioPartenza']
    orario_arr     = hash['compOrarioArrivo']
    id_origine = hash['idOrigine']
    orig = hash['origine']
    dest = hash['destinazione']
    if hash['fermate']
      fermate = hash['fermate'].map{|e| e["id"]} # lista (array) delle fermate (loro id)
    else
      puts "No 'fermate' found per: #{id_origine}/#{num_treno}"
      raise StatusResultParsingError.new(@train_num), "Problem parsing JSON"
    end
    # "#{num_treno}|#{num_treno_comp}|#{id_origine}|#{orario_part}|#{orig}|#{orario_arr}|#{dest}"
    "#{num_treno}|#{num_treno_comp}|#{id_origine}|#{orario_part}|#{orig}|#{orario_arr}|#{dest}|#{fermate.join(':')}"
  end
end


class Viaggiatreno
  SCHEME_AND_HOST = "http://www.viaggiatreno.it/"


  class << self

    # Cerca treno tramite numero
    # Ritorna un array di oggetti TrainInfo (array vuoto, di dimensione 1 o più)
    def train_search(train_num)
      read_train_search(train_search_api(train_num))
    end


    # Fornisce lo status del/dei treno/i identificati dal train_num
    # Ritorna una stringa con info in forma json
    def train_status(train_num, station_code=nil)
      res = train_search(train_num).map do |ti|   # ti is a TrainInfo obj
        read_train_status(train_status_api(ti.departure_station.code, train_num), train_num)
      end
      res = res.first if station_code
      res
    end

    # Ritorna un array di 1 o più oggetti TrainInfo (o un array vuoto)
    def read_train_search(result)
      result.split("\n").map do |r|
        a  = r.split("|")
        b  = a.first.split(" - ")
        TrainInfo.new(b.first, Station.new(a.last.split("-").last, b.last))
      end
    end

    def read_train_status(result, train_num=nil)
      sr = StatusResult.new(result)
      sr.train_num = train_num # train_num mi serve per tracciare la comunicazione che va male...
      sr
      # result.select!{|ti| ti.departure_station.code==station_code} if station_code
      # result.map do |ti|
      #   train_status_api(ti.departure_station.code, train_num)
      #   # StatusResult.new(Net::HTTP.get(URI("#{BASE}/andamentoTreno/#{ti.departure_station.code}/#{train_num}"))) # 
      #   StatusResult.new(train_status_api(ti.departure_station.code, train_num)) # 
      # end
    end

    def train_search_uri(train_num)
      URI.join(SCHEME_AND_HOST, "viaggiatrenonew/", "resteasy/", "viaggiatreno/", "cercaNumeroTrenoTrenoAutocomplete/", train_num.to_s)
    end

    def train_status_uri(station_code, train_num)
      URI.join(SCHEME_AND_HOST, "viaggiatrenonew/", "resteasy/", "viaggiatreno/", "andamentoTreno/", "#{station_code}/", train_num.to_s)
    end


    private

    def train_search_api(train_num)
      # http://www.viaggiatreno.it/viaggiatrenonew/resteasy/viaggiatreno/cercaNumeroTrenoTrenoAutocomplete/2311
      uri = train_search_uri(train_num)
      if @http
        @http.get(uri.path).to_s
      else
        HTTP.get(uri).to_s # was Net::HTTP.get(uri)
      end
    end

    def train_status_api(station_code, train_num)
      # http://www.viaggiatreno.it/viaggiatrenonew/resteasy/viaggiatreno/cercaNumeroTrenoTrenoAutocomplete/2311
      uri = train_status_uri(station_code, train_num)
      if @http
        @http.get(uri.path).to_s
      else
        HTTP.get(uri) # was Net::HTTP.get(uri)
      end
    end
  end 
end

# puts Viaggiatreno.read_train_search("10001 - VENEZIA MESTRE|10001-S02589").inspect
# puts Viaggiatreno.train_search(21).inspect
# results = Viaggiatreno.train_status(21) # 2 elem
# results = Viaggiatreno.train_status(21, "S01301") # 1 elem
# puts Viaggiatreno.train_status(1234567).inspect # []
# puts Viaggiatreno.train_status(3977).inspect
# puts results.inspect

# puts Viaggiatreno.train_status_uri("S01301", 21)

# Viaggiatreno.open do |api|
#   puts api.train_search(21).inspect
#   puts api.train_status(21).inspect
# end


# http://www.viaggiatreno.it/viaggiatrenonew/resteasy/viaggiatreno/cercaNumeroTrenoTrenoAutocomplete/22
# http://www.viaggiatreno.it/viaggiatrenonew/resteasy/viaggiatreno/andamentoTreno/S00228/4640

# http://www.viaggiatreno.it/viaggiatrenonew/resteasy/viaggiatreno/andamentoTreno/S00228/10977


# Viaggiatreno.open do |api|
#   threads = 2.times.map do
#     Thread.new do
#       puts api.train_search(21).inspect
#     end
#   end
#   threads.each(&:join)
#   puts "Main thread finish here!"
# end

