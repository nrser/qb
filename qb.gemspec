# coding: utf-8

# WARNING!!!
#
# This file gets executed every time Bundler sets up, so we want it to be
# fast, fast, *fast*... or every command execution in development will be
# painfully slow.
#
# This comes into play because you're dealing with potentially large lists of
# files, and how you handle them makes a difference.
#

require 'pathname'

# gem_root = File.expand_path(File.dirname(__FILE__))
gem_root = Pathname.new( __FILE__ ).dirname.expand_path
lib = File.join gem_root, 'lib'

$LOAD_PATH.unshift( lib ) unless $LOAD_PATH.include?( lib )

require 'qb/version'


# "Constants"
# ============================================================================
#
# Though they're implemented as local variables because I don't want to
# pollute the global namespace.
#

# Things not to package (String | Regexp)
omit_files = [
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
  # don't think we need the Rakefile
  'Rakefile',
  
  # Omit the ansible devel checkout for now
  %r{^packages/python/ansible/},
]


# Helpers
# ============================================================================
#
# Again, implemented as local variables pointing to lambdas to not pollute.
#

get_rel_path = ->( path ) {
  Pathname.new( path ).relative_path_from( gem_root ).to_s
}

should_omit = ->( rel_path ) {
  omit_files.any? {|pattern|
    case pattern
    when String
      rel_path == pattern
    when Regexp
      pattern.match rel_path
    else
      raise "bad pattern: #{ pattern.inspect }"
    end
  }
}

filter_files = ->( rel_paths ) {
  rel_paths.reject { |rel_path| should_omit.call rel_path }
}


# Spec
# ============================================================================

Gem::Specification.new do |spec|
  spec.name           = QB::GEM_NAME
  spec.version        = QB::VERSION
  spec.authors        = ["nrser"]
  spec.email          = ["neil@ztkae.com"]

  spec.summary = \
    %q{qb is all about projects. named after everyone's favorite projects.}
  
  # spec.description = \
  #   %q{TODO: Write a longer description or delete this line.}
  
  spec.homepage       = "https://github.com/nrser/qb"
  spec.license        = "MIT"
  
  spec.required_ruby_version = '>= 2.3.0'
  
  
  # Files
  # ============================================================================
  
  # Start with all the checked-in files that are not omitted
  spec.files          = filter_files.call `git ls-files -z`.split( "\x0" )
  
  # Add files from `//node_modules` that are not omitted
  spec.files          += filter_files.call Dir.glob(
    (gem_root / 'node_modules' / '**' / '*'), File::FNM_DOTMATCH
  ).map { |abs_path| get_rel_path.call abs_path }
  
  # Add all files from Git submodules that are not omitted
  `git submodule --quiet foreach --recursive pwd`.
    split( $\ ).
    each do |submod_abs_path|
      submod_rel_path = get_rel_path.call submod_abs_path
      
      # Only deal with the submodule at all if it isn't totally omitted
      #
      # Need to add the `/` on the end 'cause that's how they're matched in the
      # regexps
      #
      unless should_omit.call( submod_rel_path + '/' )
        Dir.chdir submod_abs_path do
          # Issue git ls-files in submodule's directory and
          # prepend the submodule path to create absolute file paths
          #
          # WARNING!!!  Do **NOT** `<<` to `spec.files` in the loop, it's shit
          #             slow (lots of files -> prob resizing array tons of
          #             times)
          #
          spec.files += filter_files.call `git ls-files -z`.
            split( "\x0" ).
            map { |filename|
              File.join( submod_rel_path, filename)
            }
        end
      end
    end # each submod_abs_path
  
  # ****************************************************************************
  
  # Latest (as of 2018-01-6) `bundle gem` setup uses `//exe` as the gem
  # binaries (that are shipped) and `//bin` as the development binaries, so
  # I've just stuck to that
  spec.bindir        = "exe"
  
  # Executables to install in system path with gem
  #
  # All files in the bindir that *do not* start with `.`
  #
  spec.executables   = spec.files.grep  %r{^#{ spec.bindir }/[^\.]},
                                        &File.method( :basename )
  
  # Where that source be, standard `//lib` directory
  spec.require_paths = ["lib"]
  
  
  # Dependencies
  # ============================================================================
  
  # Development Dependencies
  # ----------------------------------------------------------------------------

  spec.add_development_dependency "bundler",        '~> 1.16', '>= 1.16.1'
  spec.add_development_dependency "rake",           '~> 12.3'
  
  # Testing with `rspec`
  spec.add_development_dependency "rspec",          '~> 3.7'
  
  # Doc site generation with `yard`
  spec.add_development_dependency "yard",           '~> 0.9.12'
  
  # These, along with `//.yardopts` config, are *supposed to* result in
  # rendering markdown files and doc comments using
  # GitHub-Flavored Markdown (GFM), though I'm not sure if it's totally working
  spec.add_development_dependency "redcarpet",      '~> 3.4'
  spec.add_development_dependency "github-markup",  '~> 1.6'
  
  # Nicer REPL experience
  spec.add_development_dependency "pry",            '~> 0.10.4'
  
  
  # Runtime Dependencies
  # ----------------------------------------------------------------------------
  
  # My guns
  spec.add_dependency 'nrser',            '0.3.0.dev'
  
  # My favorite wrapper
  spec.add_dependency "cmds",             '~> 0.2.10'
  
  # My gem to help manage system state
  spec.add_dependency "state_mate",       '~> 0.1.3'
  
  # Used to parse `ansible.cfg` files
  spec.add_dependency 'parseconfig',      '~> 1.0', '>= 1.0.8'
  
  # GitHub API client
  spec.add_dependency "octokit",          "~> 4.0"
  
  # Much better logging
  spec.add_dependency 'semantic_logger',  '~> 4.2'
  
  # With much more awesome printing!
  spec.add_dependency 'awesome_print',    '~> 1.8'
  
  # Ruby lib wrapping `git` binary system calls for use in {QB::Repo::Git}
  spec.add_dependency 'git',              '~> 1.3'
  
  # Ruby SemVer v2 implementation
  # 
  # Sub-proc'ing into JavaScript to use their `semver` package is *way* too
  # slow when processing lists of version strings (like Git tags).
  # 
  # Yeah, it could be sped up at the cost of added complexity, but I'm just
  # going to see if this work ok first.
  # 
  spec.add_dependency 'semver2', '~> 3.4.2'
  
  # Trying out a method decoration gem, aimed to be like Python (which I did
  # really like, once you got past the confusion of it)
  spec.add_dependency 'method_decorators', '~> 0.9.6'
  
  
  # Development-Only Extra Metadata
  # ============================================================================
  #
  # We dump this in CLI output header in local dev.
  #
  
  if QB::VERSION.end_with? '.dev'
    commit = `git rev-parse HEAD`.strip
    
    spec.metadata = {
      "built" => Time.now.to_s,
      "branch" => `git rev-parse --abbrev-ref HEAD`.strip,
      "commit" => commit,
      "browse" => "https://github.com/nrser/qb/tree/#{ commit }",
    }
  end # if dev version
  
end # spec
