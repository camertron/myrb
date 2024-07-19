$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'myrb/version'

Gem::Specification.new do |s|
  s.name     = 'myrb'
  s.version  = ::Myrb::VERSION
  s.authors  = ['Cameron Dutro']
  s.email    = ['camertron@gmail.com']
  s.homepage = 'http://github.com/camertron/myrb'
  s.description = s.summary = 'Inline types for Ruby.'
  s.platform = Gem::Platform::RUBY

  s.add_dependency 'parser', '~> 3.0'
  s.add_dependency 'onload', '~> 1.0'

  s.add_development_dependency 'steep', '~> 1.4'

  s.require_path = 'lib'

  s.executables << "myrb"
  s.executables << "myrbc"

  s.files = Dir['{lib,spec}/**/*', 'Gemfile', 'LICENSE', 'CHANGELOG.md', 'README.md', 'Rakefile', 'myrb.gemspec']
end
