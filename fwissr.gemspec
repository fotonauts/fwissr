require File.join(File.dirname(__FILE__), 'lib', 'fwissr', 'version')

spec = Gem::Specification.new do |s|
  s.name        = "fwissr"
  s.version     = Fwissr::VERSION
  s.platform    = Gem::Platform::RUBY
  s.summary     = "Fwissr"
  s.description = <<-EOF
  A simple configuration registry tool by Fotonauts.
  EOF

  s.author   = "Fotonauts Team"
  s.homepage = "https://github.com/fotonauts/fwissr"
  s.email    = [ "aymerick@fotonauts.com", "oct@fotonauts.com" ]

  s.require_paths = [ "lib" ]
  s.bindir        = "bin"
  s.executables   = %w( fwissr )
  s.files         = %w( LICENSE Rakefile README.md ) + Dir["{bin,lib}/**/*"]

  s.add_dependency("yajl-ruby")

  # Driver: mongo
  # s.add_dependency("mongo", '~> 1.9')
  # s.add_dependency("bson_ext")

  # Driver: moped
  # s.add_dependency("moped", '~> 1.5')
  # s.add_dependency("moped", "~> 2.0.beta3")

  s.add_development_dependency("rspec")
  s.add_development_dependency("mongo")
end
