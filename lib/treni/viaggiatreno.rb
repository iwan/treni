
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
        TrainIdentifier.new(b.first, Station.new(a.last.split("-").last, b.last))
      end
    end

    def read_train_status(result, train_num=nil, dep_station= nil)
      sr = StatusResult.new(result, train_num, dep_station)
      # sr.train_num = train_num # train_num mi serve per tracciare la comunicazione che va male...
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


