# classe relativa al binomio numero_treno e stazione di partenza
class TrainIdentifier
  attr_reader :train_num, :departure_station
  def initialize(train_num, departure_station)
    @train_num = train_num
    @departure_station = departure_station
  end
end
