$:.push File.expand_path("../lib", __FILE__)

require "casino/facebook_authenticator/version"

Gem::Specification.new do |s|
  s.name        = "casino-facebook_authenticator"
  s.version     = CASino::FacebookAuthenticator::VERSION
  s.authors     = ["Craig Weston"]
  s.email       = ["craig@craigweston.ca"]
  s.homepage    = "http://github.com/craigweston/casino-facebook_authenticator"
  s.summary     = "Provides mechanism to use facebook as an authenticator for CASino."
  s.description = "This gem can be used to allow the CASino to authenticate using the Facebook JavaScript SDK."
  s.license     = "MIT"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'rspec', '~> 2.12'
  s.add_development_dependency 'simplecov', '~> 0.7'
  s.add_development_dependency 'coveralls'
  s.add_development_dependency 'sqlite3', '~> 1.3.7'

  s.add_dependency "rails", ">= 4.1"
  s.add_dependency "koala", "~> 1.11.0rc"
  s.add_runtime_dependency 'activerecord', '>= 4.1.0', '< 4.3.0'
end
