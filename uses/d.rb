require_relative '../lib/treni'

require 'yaml'

t = Time.now
bi = BaseInfo.new(yml_content: YAML.load_file('/Users/iwan/cippa.json'))
puts Time.now-t
puts bi.to_s

puts "-----"

bi = BaseInfo.new(yml_content: JSON.parse(File.read('/Users/iwan/cippa.json').force_encoding('UTF-8')))
puts Time.now-t
puts bi.to_s
