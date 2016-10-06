# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'qb/version'

Gem::Specification.new do |spec|
  spec.name          = QB::GEM_NAME
  spec.version       = QB::VERSION
  spec.authors       = ["nrser"]
  spec.email         = ["neil@ztkae.com"]

  spec.summary       = %q{qb is all about projects. named after everyone's favorite projects.}
  # spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = "https://github.com/nrser/qb"
  spec.license       = "MIT"
  
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  
  # get an array of submodule dirs by executing 'pwd' inside each submodule
  gem_dir = File.expand_path(File.dirname(__FILE__)) + "/"
  `git submodule --quiet foreach pwd`.split($\).each do |submodule_path|
    Dir.chdir(submodule_path) do
      submodule_relative_path = submodule_path.sub gem_dir, ""
      # issue git ls-files in submodule's directory and
      # prepend the submodule path to create absolute file paths
      `git ls-files`.split($\).each do |filename|
        spec.files << "#{submodule_relative_path}/#{filename}"
      end
    end
  end
  
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  
  spec.add_dependency "cmds",'~> 0.0', ">= 0.0.9"
  spec.add_dependency "nrser-extras", '~> 0.0', ">= 0.0.3"
  spec.add_dependency "state_mate", '~> 0.0', ">= 0.0.7"
  
  
  if QB::VERSION.end_with? '.dev'
    commit = `git rev-parse HEAD`.strip
    
    spec.metadata = {
      "built" => Time.now.to_s,
      "branch" => `git rev-parse --abbrev-ref HEAD`.strip,
      "commit" => commit,
      "browse" => "https://github.com/nrser/qb/tree/#{ commit }",
    }
  end
end
