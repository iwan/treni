# classe relativa alla stazione
class Station
  attr_reader :code, :name
  def initialize(code, name)
    @code = code
    @name = name
  end
end
