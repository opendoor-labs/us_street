# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'us_street/version'

Gem::Specification.new do |spec|
  spec.name          = "us_street"
  spec.version       = UsStreet::VERSION
  spec.authors       = ["Daniel Neighman"]
  spec.email         = ["has.sox@gmail.com"]
  spec.summary       = %q{Normalizes Us Streets}
  spec.description   = %q{Normalizes Us Streets}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'activesupport', '>=3.0'
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
