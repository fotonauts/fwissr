require File.join(File.dirname(__FILE__), 'lib', 'fwissr', 'version')

spec = Gem::Specification.new do |s|
  s.name        = "fwissr"
  s.version     = Fwissr::VERSION
  s.platform    = Gem::Platform::RUBY
  s.summary     = "Fotonaut's swissr library and tools."
  s.description = <<-EOF
  A simple configuration registry tool by Fotonauts.
  EOF

  s.author   = "Fwissr"
  s.homepage = "https://github.com/fotonauts/fwissr"
  s.email    = "aymerick@fotonauts.com"

  s.require_path = "lib"
  s.bindir       = "bin"
  s.executables  = %w( fwissr )
  s.files        = %w( README.md Rakefile ) + Dir["{bin,lib}/**/*"]

  # rdoc
  s.has_rdoc         = true
  s.extra_rdoc_files = %w( README.md )

  s.add_dependency("yajl-ruby")
  # s.add_dependency('json")
  s.add_dependency("mongo")
  s.add_dependency("bson_ext")

  s.add_development_dependency("rspec")
  s.add_development_dependency("delorean") # mock Time
end
