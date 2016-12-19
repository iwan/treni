# BillBoard time

class BBTime < String
  SEP = ":"

  # hour_string: "14:56"
  def initialize(time)
    time = "" if time.nil?
    if time.is_a? String
      time = amend(time)
    elsif time.is_a? Time
      time = time.strftime("%H:%M")
    else
      raise "Time is not a valid type (it must be a String or a Time object). I found '#{time}' of class #{time.class}"
    end
    super(time)
  end

  def hour
    split(SEP).first.to_i
  end
  alias_method :hours, :hour

  def minute
    split(SEP).last.to_i
  end
  alias_method :minutes, :minute

  private

  def amend(time)
    return time if /^\d\d:\d\d$/=~time
    a = time.split(SEP)
    a.unshift("00") if a.size==1
    "#{a.first.rjust(2, '0')}#{SEP}#{a.last.rjust(2, '0')}"
  rescue
    time
  end
end
