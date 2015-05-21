# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "matrioska/version"

Gem::Specification.new do |s|
  s.name        = "matrioska"
  s.version     = Matrioska::VERSION
  s.authors     = ["Luca Pradovera"]
  s.email       = ["lpradovera@mojolingo.com"]
  s.homepage    = "https://github.com/adhearsion/matrioska"
  s.summary     = %q{Adhearsion plugin for in-call apps}
  s.description = %q{Adhearsion plugin for in-call apps. Provides a features-style interface to run applications in calls.}
  s.license     = 'MIT'

  s.rubyforge_project = "matrioska"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_runtime_dependency %q<adhearsion>, ["~> 2.4"]

  s.add_development_dependency %q<bundler>, ["~> 1.0"]
  s.add_development_dependency %q<rspec>, ["~> 2.5"]
  s.add_development_dependency %q<rake>, [">= 0"]
  s.add_development_dependency %q<guard-rspec>
 end
