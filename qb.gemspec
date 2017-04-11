# coding: utf-8
require 'pathname'

GEM_ROOT = File.expand_path(File.dirname(__FILE__))
lib = File.join(GEM_ROOT, 'lib')
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'qb/version'

# things not to package (String | Regexp)
OMIT_FILES = [
  # standard gem ignores (test files)
  %r{^(test|spec|feature)/},
  # all the development files
  %r{^dev/},
  # all the temp files
  %r{^tmp/},
  # dotfiles / dev config
  '.gitignore',
  '.gitmodules',
  '.qb-options.yml',
  '.rspec',
  '.travis.yml',
  # don't think we need this *in* the gem - it's for bundler in dev
  'Gemfile',
  # dev executables are in /bin (gem executables are in /exe)
  %r{^bin/},
  # yarn artifacts
  'yarn.lock',
  'node_modules/.yarn-integrity',
  # nrser.blockinfile tests carried over from fork
  %r{^roles/nrser.blockinfile/tests/},
  # temp playbook used in development
  'temp.yml',
  # don't think we need the Rakefile
  'Rakefile',
]

Gem::Specification.new do |spec|
  spec.name          = QB::GEM_NAME
  spec.version       = QB::VERSION
  spec.authors       = ["nrser"]
  spec.email         = ["neil@ztkae.com"]

  spec.summary       = %q{qb is all about projects. named after everyone's favorite projects.}
  # spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = "https://github.com/nrser/qb"
  spec.license       = "MIT"
  
  checked_in_files = `git ls-files -z`.split("\x0")
  
  node_modules_files = Dir.glob(
    File.join(GEM_ROOT, 'node_modules/**/*'), File::FNM_DOTMATCH
  ).map {|abs_path|
    Pathname.new(abs_path).relative_path_from(Pathname.new(GEM_ROOT)).to_s
  }
  
  spec.files         = (checked_in_files + node_modules_files).reject {|fp|
    OMIT_FILES.any? {|pattern|
      case pattern
      when String
        fp == pattern
      when Regexp
        pattern.match fp
      else
        raise "bad pattern: #{ pattern.inspect }"
      end
    }
  }
  
  # get an array of submodule dirs by executing 'pwd' inside each submodule
  gem_dir = File.expand_path(File.dirname(__FILE__)) + "/"
  `git submodule --quiet foreach pwd`.split($\).each do |submodule_path|
    Dir.chdir(submodule_path) do
      submodule_relative_path = submodule_path.sub gem_dir, ""
      
      # don't bundle dev submods
      unless submodule_relative_path.start_with? 'dev/'
        # issue git ls-files in submodule's directory and
        # prepend the submodule path to create absolute file paths
        `git ls-files`.split($\).each do |filename|
          spec.files << "#{submodule_relative_path}/#{filename}"
        end
      end
    end
  end
  
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "yard"
  
  spec.add_dependency "cmds",'~> 0.0', ">= 0.2.0"
  spec.add_dependency "nrser-extras", '~> 0.0', ">= 0.0.3"
  spec.add_dependency "state_mate", '~> 0.0', ">= 0.0.9"
  spec.add_dependency 'parseconfig', '~> 1.0', '>= 1.0.8'
  
  
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
