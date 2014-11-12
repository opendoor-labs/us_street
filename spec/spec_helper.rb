$:.unshift File.expand_path('../lib', __dir__)

require 'us_street'
require 'pry'

RSpec.configure do |config|
  config.order = "random"
end
