require 'net/http'
require 'date'
require 'fileutils'
require 'typhoeus' # https://github.com/typhoeus/typhoeus
require 'json'
require 'http'
require 'ostruct'
require 'active_support/inflector'



%w(
  version
  station
  train_identifier
  status_result
  status_result_parsing_error
  viaggiatreno
  basic_info_list
  base_info
  fetcher
).each { |file| require File.join(File.dirname(__FILE__), 'treni', file) }


module Treni
  # Your code goes here...
end
