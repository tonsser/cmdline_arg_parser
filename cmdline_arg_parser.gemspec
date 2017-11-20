# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "cmdline_arg_parser/version"

Gem::Specification.new do |spec|
  spec.name          = "cmdline_arg_parser"
  spec.version       = CmdlineArgParser::VERSION
  spec.authors       = ["David Pedersen"]
  spec.email         = ["david@tonsser.com"]

  spec.summary       = %q{Simple command line argument parsing}
  spec.homepage      = "https://github.com/tonsser/cmdline_arg_parser"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
