# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'relp/version'

Gem::Specification.new do |spec|
  spec.name          = "relp"
  spec.version       = Relp::VERSION
  spec.authors       = ["Dominik Hlavac Duran"]
  spec.email         = ["dhlavacd@redhat.com"]

  spec.summary       = "Ruby implementation of RELP (Reliable Event Logging Protocol) protocol."
  spec.description   = "Ruby implementation of RELP (Reliable Event Logging Protocol) protocol."
  spec.homepage      = "https://github.com/dhlavac/Relp"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.require_paths = ["lib"]
  spec.bindir        = "exe"

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
