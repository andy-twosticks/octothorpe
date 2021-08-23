# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'octothorpe'

Gem::Specification.new do |spec|
  spec.name          = "octothorpe"
  spec.version       = Octothorpe::VERSION
  spec.authors       = ["Andy Jones"]
  spec.email         = ["andy@twosticksconsulting.co.uk"]
  spec.summary       = %q{Like a Hash. Better for message passing between classes, I hope.}

  spec.description   = <<-DESCRIPTION.gsub(/^\s+/, '')
    A very simple hash-like class that borrows a little from OpenStruct, etc.

    * Treats string and symbol keys as equal
    * Access member objects with ot.>>.keyname
    * Guard conditions allow you to control what returns if key is not present
    * Pretty much read-only, for better or worse

    Meant to facilitate message-passing between classes.
  DESCRIPTION

  spec.homepage      = "https://github.com/andy-twosticks/octothorpe"
  spec.license       = "MIT"

  spec.files         = `hg status -macn0`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-doc"
end
