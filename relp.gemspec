# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'relp/version'

Gem::Specification.new do |spec|
  spec.name          = 'relp'
  spec.version       = Relp::VERSION
  spec.authors       = ['Jiří Vymazal', 'Dominik Hlaváč Ďurán']
  spec.email         = ['jvymazal@redhat.com', 'dhlavacd@redhat.com']

  spec.summary       = "Ruby implementation of RELP (Reliable Event Logging Protocol) protocol."
  spec.description   = "If you want to receive or send message via RELP protocol you can use this gem"
  spec.homepage      = 'https://github.com/ViaQ/Relp'
  spec.license       = 'MIT'


  spec.files         = Dir['{lib,bin,test}/**/*'] + ['LICENSE.txt', 'README.md', 'Rakefile', 'CHANGELOG.md']
  spec.test_files    = Dir['{test}/**/*']
  spec.require_paths = ["lib"]


  spec.required_ruby_version = '>= 2.1.0'

  spec.add_development_dependency 'bundler', '~> 2.1'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
end
