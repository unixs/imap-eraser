# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'imap_eraser/version'

Gem::Specification.new do |spec|
  spec.name          = "imap_eraser"
  spec.version       = ImapEraser::VERSION
  spec.authors       = ["Alexander Feodorov"]
  spec.email         = ["webmaster@unixcomp.org"]

  spec.summary       = 'Automatically delete old emails in IMAP4 maiboxes. May pass flagged emails.'
  spec.description   = 'Automatically delete old emails in IMAP4 maiboxes.'
  spec.homepage      = 'https://github.com/unixs/imap-eraser'
  spec.license       = "LGPLv3"
  spec.platform      = Gem::Platform::RUBY

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'bin'
  spec.executables   = %w(imap_eraser)
  spec.require_paths = %w(lib)

  spec.required_ruby_version = '>=2.1.0'

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency 'rspec-core', '~> 3'
  spec.add_development_dependency 'rspec-expectations', '~> 3'
  spec.add_development_dependency "awesome_print", '~> 1'
  spec.add_development_dependency "pry-byebug", '~> 3'

  spec.add_runtime_dependency 'activesupport', '~> 5'
end
