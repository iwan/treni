# classe relativa al risultato di una richiesta di status del treno
# Sarà una stringa contenente le info dello status in formato json
class StatusResult
  attr_accessor :train_num
  attr_reader :resp_txt, :resp_hash, :train_code


  def initialize(response_txt, train_code, dep_station=nil)
    @resp_txt   = response_txt
    @train_code = train_code
    @resp_hash  = parse_text(response_txt, train_code, dep_station)
    @dep_station = dep_station
  end

  def hash
    @resp_hash
  end
  alias_method :to_hash, :hash

  def to_s
    @resp_txt
  end
  alias_method :txt, :to_s

  def train_departed?
    !hash["fermate"].first["partenzaReale"].nil?
  rescue
    false
  end

  def train_arrived?
    !hash["fermate"].last["arrivoReale"].nil?
  rescue
    false
  end


  def basic_info
    BaseInfo.new(yml_content: hash).to_s
  end


  private
  def parse_text(txt, train_code, dep_station)
    begin
      JSON.parse(txt)
    rescue Exception => e #  JSON::ParserError => e
      puts "--------------------"
      puts txt
      puts "--------------------"
      raise StatusResultParsingError.new(@train_code), "Problem parsing JSON for train '#{dep_station}/#{train_code}'"
    end
  end
end
