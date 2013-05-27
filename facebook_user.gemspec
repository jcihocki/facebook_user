# encoding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require "startup_giraffe/facebook_user/version"

Gem::Specification.new do |s|
  s.name        = "facebook_user"
  s.version     = StartupGiraffe::FacebookUser::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Johnny Cihocki"]
  s.email       = ["john@startupgiraffe.com"]
  s.homepage    = "http://startupgiraffe.com"
  s.summary     = "A Facebook User module for mongoid models"
  s.description = "facebook_user allows you to register and authenticate a user model using facebook auth"
  s.license     = "MIT"

  s.required_ruby_version     = ">= 1.9"
  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency("mongoid", [">= 3.0.0"])
  s.add_dependency( "fb_graph", ["> 2.6"] )

  s.files        = Dir.glob("lib/**/*") + %w(CHANGELOG.md LICENSE README.md)
  s.require_path = 'lib'
end
