require_relative '../lib/treni'

lists_dir = ENV.fetch "TRAIN_LIST_DIR"
lists_dir = Dir.glob(File.join(lists_dir, "*")).select {|f| File.directory? f}.sort.last # selezioni cartella con data più recente
list_path = File.join(lists_dir, "merged.txt")

statuses_dir = ENV.fetch "TRAIN_STATUSES_DIR"

pause = ENV.fetch "TRAIN_PAUSE"
pause = pause.to_i

fetcher = FetcherV2.new(statuses_dir, list_path)
while(true)
  fetcher.fix_list_file # recupera ev. lista stazioni per quei treni che non ce l'hanno
  fetcher.run
  sleep(60*pause)
end
