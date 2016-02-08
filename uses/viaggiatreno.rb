
# puts Viaggiatreno.read_train_search("10001 - VENEZIA MESTRE|10001-S02589").inspect
# puts Viaggiatreno.train_search(21).inspect
# results = Viaggiatreno.train_status(21) # 2 elem
# results = Viaggiatreno.train_status(21, "S01301") # 1 elem
# puts Viaggiatreno.train_status(1234567).inspect # []
# puts Viaggiatreno.train_status(3977).inspect
# puts results.inspect

# puts Viaggiatreno.train_status_uri("S01301", 21)

# Viaggiatreno.open do |api|
#   puts api.train_search(21).inspect
#   puts api.train_status(21).inspect
# end


# http://www.viaggiatreno.it/viaggiatrenonew/resteasy/viaggiatreno/cercaNumeroTrenoTrenoAutocomplete/22
# http://www.viaggiatreno.it/viaggiatrenonew/resteasy/viaggiatreno/andamentoTreno/S00228/4640

# http://www.viaggiatreno.it/viaggiatrenonew/resteasy/viaggiatreno/andamentoTreno/S00228/10977


# Viaggiatreno.open do |api|
#   threads = 2.times.map do
#     Thread.new do
#       puts api.train_search(21).inspect
#     end
#   end
#   threads.each(&:join)
#   puts "Main thread finish here!"
# end
