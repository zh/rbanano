# frozen_string_literal: true

require_relative 'lib/banano/version'

Gem::Specification.new do |spec|
  spec.name          = "banano"
  spec.version       = Banano::VERSION
  spec.authors       = ["Stoyan Zhekov"]
  spec.email         = ["zh@zhware.net"]

  spec.summary       = 'Library for working with Banano currency.'
  spec.description   = 'Library for working with Banano currency. Implements parts of the RPC protocol for access to Banano node. Convertion between raw and banano units etc.'
  spec.homepage      = "https://github.com/zh/rbanano"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/zh/rbanano"
  spec.metadata["changelog_uri"] = "https://github.com/zh/rbanano/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.glob("{bin,lib}/**/*") + %w[LICENSE.txt README.md CHANGELOG.md]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) {|f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 1.0"
  spec.add_dependency "faraday_middleware", "~> 1.0"

  spec.add_development_dependency "pry", "~> 0"
  spec.add_development_dependency "rake", "~> 12.3"
  spec.add_development_dependency "rspec", "~> 3.9"
  spec.add_development_dependency "rubocop", "~> 0.85"
  spec.add_development_dependency "webmock", "~> 3.8"
end
