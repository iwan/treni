# classe relativa al risultato di una richiesta di status del treno
# Sarà una stringa contenente le info dello status in formato json
class StatusResultOld < String
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
    BaseInfo.new(yml_content: hash).to_s
    # num_treno_comp = hash['compNumeroTreno'] # "EC 21"
    # num_treno      = hash['numeroTreno']  #  "21"
    # orario_part    = hash['compOrarioPartenza']
    # orario_arr     = hash['compOrarioArrivo']
    # id_origine = hash['idOrigine']
    # orig = hash['origine']
    # dest = hash['destinazione']
    # if hash['fermate']
    #   fermate = hash['fermate'].map{|e| e["id"]} # lista (array) delle fermate (loro id)
    # else
    #   puts "No 'fermate' found per: #{id_origine}/#{num_treno}"
    #   raise StatusResultParsingError.new(@train_num), "Problem parsing JSON"
    # end
    # # "#{num_treno}|#{num_treno_comp}|#{id_origine}|#{orario_part}|#{orig}|#{orario_arr}|#{dest}"
    # "#{num_treno}|#{num_treno_comp}|#{id_origine}|#{orario_part}|#{orig}|#{orario_arr}|#{dest}|#{fermate.join(':')}"
  end
end



# classe relativa al risultato di una richiesta di status del treno
# Sarà una stringa contenente le info dello status in formato json
# deprecato
# class PrevStatusResult < String
#   attr_accessor :train_num

#   def to_hash

#     begin
#       JSON.parse(self)
#     rescue Exception => e #  JSON::ParserError => e
#       raise StatusResultParsingError.new(@train_num), "Problem parsing JSON"
#     end
#   end

#   def basic_info
#     hash = self.to_hash
#     num_treno_comp = hash['compNumeroTreno'] # "EC 21"
#     num_treno      = hash['numeroTreno']  #  "21"
#     orario_part    = hash['compOrarioPartenza']
#     orario_arr     = hash['compOrarioArrivo']
#     id_origine = hash['idOrigine']
#     orig = hash['origine']
#     dest = hash['destinazione']
#     if hash['fermate']
#       fermate = hash['fermate'].map{|e| e["id"]} # lista (array) delle fermate (loro id)
#     else
#       puts "No 'fermate' found per: #{id_origine}/#{num_treno}"
#       raise StatusResultParsingError.new(@train_num), "Problem parsing JSON"
#     end
#     # "#{num_treno}|#{num_treno_comp}|#{id_origine}|#{orario_part}|#{orig}|#{orario_arr}|#{dest}"
#     "#{num_treno}|#{num_treno_comp}|#{id_origine}|#{orario_part}|#{orig}|#{orario_arr}|#{dest}|#{fermate.join(':')}"
#   end
# end
