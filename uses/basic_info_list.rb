require_relative '../lib/treni'

# Interroga il servizio di viaggiatreno per tutti i numeri di treno
# da 0 a 100_000. 

dir = File.join(Dir.home, "dev", "ruby", "treni_misc", "liste_treni")

bil = BasicInfoList.new(dir)
bil.fetch_all  # salva in file "0-9999_list.txt", ...
bil.merge_all("merged.txt")  # fa il merge dei file trovati al punto precedente
bil.fix("merged.txt") # corregge (toglie doppioni, ecc.)
