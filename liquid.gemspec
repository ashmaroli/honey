# encoding: utf-8
# frozen_string_literal: true

require_relative "lib/liquid/version"

Gem::Specification.new do |s|
  s.name     = "liquid"
  s.version  = Liquid::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary  = "A secure, non-evaling end user template engine with aesthetic markup."
  s.authors  = ["Tobias Lütke"]
  s.email    = ["tobi@leetsoft.com"]
  s.homepage = "http://www.liquidmarkup.org"
  s.license  = "MIT"
  s.files    = Dir.glob("{lib}/**/*").push("LICENSE")

  s.require_path = "lib"
  s.required_ruby_version = ">= 2.5.0"
end
