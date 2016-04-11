require_relative '../lib/treni'



def foo(statuses_dir)
  Dir.glob
end

statuses_dir = File.join(Dir.home, "dev", "ruby", "treni_misc", "statuses")
# lists_dir = Dir.glob("/Users/iwan/dev/ruby/treni_misc/liste_treni/*").select {|f| File.directory? f}.last # selezioni cartella con data più recente
lists_dir = Dir.glob(File.join(Dir.home, "dev", "ruby", "treni_misc", "liste_treni", "*")).select {|f| File.directory? f}.last # selezioni cartella con data più recente
list_path = File.join(lists_dir, "merged.txt")

fetcher = FetcherV2.new(statuses_dir, list_path)
while(true)
  fetcher.fix_list_file # recupera ev. lista stazioni per quei treni che non ce l'hanno
  fetcher.run

  two_day_ago = Date.today


  # TODO: comprimi con tar.gz la cartella con data oggi-2.day se ancora non c'è
  #     (opzionale: elimina la cartella originale una volta che è stata compressa)
  # TODO: trasferisci il tar.gz su aws s3 se non è ancora presente
  sleep(60*15)
end
