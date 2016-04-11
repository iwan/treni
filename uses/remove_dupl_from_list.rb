require_relative '../lib/treni'

# Interroga il servizio di viaggiatreno per tutti i numeri di treno
# da 0 a 100_000. 

dir = File.join(Dir.home, "dev", "ruby", "treni_misc", "liste_treni")

bil = BasicInfoList.new(dir)
# bil.fetch_all([0,1,2,3,7])  # salva in file "0-9999_list.txt", ...
# bil.merge_all("merged.txt")  # fa il merge dei file trovati al punto precedente
bil.fix("merged.txt", date_dir: "2016-03-04") # corregge (toglie doppioni, ecc.)
