require_relative '../lib/treni'


statuses_dir = File.join(Dir.home, "dev", "ruby", "treni_misc", "statuses")
# lists_dir = Dir.glob("/Users/iwan/dev/ruby/treni_misc/liste_treni/*").select {|f| File.directory? f}.last # selezioni cartella con data più recente
lists_dir = Dir.glob(File.join(Dir.home, "dev", "ruby", "treni_misc", "liste_treni", "*")).select {|f| File.directory? f}.last # selezioni cartella con data più recente
list_path = File.join(lists_dir, "merged.txt")

fetcher = Fetcher.new(statuses_dir, list_path)
while(true)
  fetcher.fix_list_file # recupera ev. lista stazioni per quei treni che nin ce l'hanno
  fetcher.run
  sleep(60*15)
end

