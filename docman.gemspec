# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'docman/version'

Gem::Specification.new do |spec|
  spec.name          = "docman"
  spec.version       = Docman::VERSION
  spec.authors       = ["Alexander Tolstikov"]
  spec.email         = ["atolstikov@adyax.com"]
  spec.summary       = %q{Docman made for DOCroot MANagement for Drupal projects}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "cucumber"
  spec.add_development_dependency "aruba"

  spec.add_dependency 'thor'
end
