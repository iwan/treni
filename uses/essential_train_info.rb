# new version of basic_info_list.rb

# input:
#  - directory where to put the results
#  - fetch ten_thousand_from(num|arr)

# output:
#  - 16|EC 16|S01700|12:25|MILANO CENTRALE|13:08|CHIASSO|S01700:S01322:S01301

require_relative '../lib/treni'

dir = ENV.fetch "TRAIN_LIST_DIR"

eti = EssentialTrainInfo.new(dir)
eti.fetch_all # quando esegue questa poi non esegue le successive (?)
eti.merge_all "merged.txt"
eti.fix "merged.txt"


