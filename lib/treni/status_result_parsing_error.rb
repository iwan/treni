# classe relativa all'errore generato nel corso del parsing
# del risultato ad una richiesta di status del treno
class StatusResultParsingError < Exception
  attr_reader :train_num

  def initialize(train_num)
    @train_num = train_num
  end
end
