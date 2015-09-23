# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'uc/version'

Gem::Specification.new do |spec|
  spec.name          = "uc"
  spec.version       = Uc::VERSION
  spec.authors       = ["Neeraj"]
  spec.summary       = %q{Unicorn controller}
  spec.description   = %q{Unicorn controller}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_runtime_dependency "posix_mq", "~> 2.1"
  spec.add_runtime_dependency "nakayoshi_fork", "0.0.3"
end
