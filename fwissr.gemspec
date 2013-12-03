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

  s.add_development_dependency("rspec")
end
