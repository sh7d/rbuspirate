lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rbuspirate/version"

Gem::Specification.new do |spec|
  spec.name          = "rbuspirate"
  spec.version       = Rbuspirate::VERSION
  spec.authors       = ["sh7d"]
  spec.email         = ["sh7d@sh7d"]

  spec.summary       = %q{Ruby better buspirate interface}
  spec.description   = %q{Simple buspirate ruby interface}
  spec.homepage      = "https://github.com/sh7d/rbuspirate"

  spec.metadata["homepage_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib'] + Dir.glob('lib/**').select(&File.method(:directory?))

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "pry", "~> 0.12"
  spec.add_dependency "serialport", "~> 1.3"
end

