$:.unshift File.expand_path('../lib', __dir__)

require 'us_street'
RSpec.configure do |config|
  config.order = "random"
end
