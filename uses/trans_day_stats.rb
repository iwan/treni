# legge un file "merged.txt", seleziona i treni che arrivano il giorno dopo la partenza
# e li ordina per ora di arrivo crescente

dir = File.join(Dir.home, "dev", "ruby", "treni_misc", "liste_treni", "2016-03-04")
lines = File.readlines(File.join(dir, "merged.txt"))

lines.keep_if do |line|
  arr = line.split("|")
  arr[3]>arr[5]
end

lines.sort!{|a, b| a.split("|")[5] <=> b.split("|")[5]}

File.open(File.join(dir, "trans_day.txt"), 'w'){|f| lines.each{|l| f.write(l)}}
File.open(File.join(dir, "trans_day_(only arrival time).txt"), 'w'){|f| lines.each{|l| f.write(l.split("|")[5]+"\n")}}