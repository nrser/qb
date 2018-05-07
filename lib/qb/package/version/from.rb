# frozen_string_literal: true


# Refinements
# =======================================================================

using NRSER::Types


# Definitions
# =======================================================================

# Module of factory methods to create {QB::Package::Version} instances from
# other objects (strings, {Gem::Version}, etc.)
# 
module QB::Package::Version::From
  
  # Get class to instantiate for prop values - either {QB::Package::Version}
  # or a specialized subclass like {QB::Package::Version::Leveled}.
  # 
  # @param [Hash<Symbol, Object>] **values
  #   Prop values.
  # 
  # @return [Class<QB::Package::Version>]
  # 
  def self.class_for **values
    if QB::Package::Version::Leveled.level_for **values
      QB::Package::Version::Leveled
    else
      QB::Package::Version
    end
  end # .class_for
  
  
  # Instantiate an instance from prop values, using {.class_for} to choose
  # the possible specialized class.
  # 
  # @param [Hash<Symbol, Object>] **values
  #   Prop values.
  # 
  # @return [QB::Package::Version]
  # 
  def self.prop_values **values
    class_for( **values ).new **values
  end # .values
  
  
  # Create an instance from a Gem-style version.
  # 
  # @param [String | Gem::Version] version
  # 
  # @return [QB::Package::Version]
  # 
  def self.gemver source
    gem_version = case source
    when ::Gem::Version
      source
    else
      ::Gem::Version.new source.to_s
    end
    
    # release segments are everything before a string
    release_segments = gem_version.segments.take_while { |seg|
      !seg.is_a?(String)
    }
    
    prerelease_segments = gem_version.segments[release_segments.length..-1]
    
    prop_values \
      raw: source.to_s,
      major: release_segments[0],
      minor: release_segments[1] || 0,
      patch: release_segments[2] || 0,
      revision: release_segments[3..-1] || [],
      prerelease: prerelease_segments,
      build: []
  end
  
  singleton_class.send :alias_method, :gem_version, :gemver
  
  
  def self.split_identifiers string
    string.split QB::Package::Version::IDENTIFIER_SEPARATOR
  end
  
  
  # Parse and/or validate version *identifiers*.
  # 
  # See {QB::Package::Version} for details on *identifiers*.
  # 
  # @param [String | Integer] value
  #   A value that is either already an *identifier* or a string that can
  #   be parsed into one.
  # 
  # @return [String | Integer]
  #   A valid *identifier*.
  # 
  def self.identifier_for value
    case value
    when QB::Package::Version::NUMBER_IDENTIFIER_RE
      value.to_i
    when QB::Package::Version::MIXED_SEGMENT
      value
    else
      raise ArgumentError.new binding.erb <<~END
        Can't parse identifier <%= value.inspect %>
        
        Expected one of:
        
        1.  <%= QB::Package::Version::NUMBER_IDENTIFIER_RE %>
        2.  <%= QB::Package::Version::MIXED_SEGMENT %>
        
      END
    end
  end # .identifier_for
  
  
  def self.segment_for string
    split_identifiers( string ).map { |s| identifier_for s }
  end
  
  
  # Load a SemVer¹ string into a {QB::Package::Version}.
  # 
  # @see https://semver.org
  # 
  # > **¹**
  # >   Through a combination of need, failure and frustration we are a
  # >   *wee bit* looser than the SemVer spec. This really comes from needing
  # >   to be able to handle more than three *release segments* because:
  # >
  # >   1.  Well, some projects use more than three and we can't change that.
  # >   2.  It seemed over-complicated to add another "almost-semver" parsing
  # >       option.
  # >
  # >   Details below. You can enforce our best attempt at pure SemVer with
  # >   the `strict:` keyword option.
  # 
  # ##### Gory Details #####
  # 
  # Oh, semver... what a pain you're been.
  # 
  # Right now, I just finished writing our own parser. It probably has a lot
  # of problems and I can't imagine it conforms to the spec even where it's
  # meant to. I didn't want to go this road, it was out of desperation.
  # 
  # First, QB was shelling-out to Node and using it's [semver][Node semver]
  # package, since that seems to kind of be the de-facto reference
  # implementation of the spec.
  # 
  # That was far too slow to process large lists of version like you might
  # get from `git tag`, and it means we depended on Node and had to bundle
  # the `semver` package in or install it otherwise, which was a pain for
  # a single function call.
  # 
  # Yeah, there are other ways to go about it, but they all suck too.
  # 
  # Next I tried the [semver2][Ruby semver2] Ruby gem. It never struck me as
  # super solid, and when faced with `1.2.3.4-pre`-style versions it just
  # tossed everything after the `3` and didn't mention it, which led me to
  # toss it too.
  # 
  # This happen when I realized we couldn't side-step "fourth release segment"
  # because I needed the system to handle OpenResty's Docker image versions,
  # which are `M.m.p.r` format, leading to add the
  # {QB::Package::Version#revision} property and write my own parsing logic
  # here.
  # 
  # [Node semver]: https://www.npmjs.com/package/semver
  # 
  # @param [#to_s] source
  #   Where to get the source string.
  # 
  # @param [Boolean] strict:
  #   When `true`, we attempt to adhere strictly to the SemVer spec, raising
  #   if we find any departures.
  # 
  # @raise [ArgumentError]
  #   1.  If there are **less than** `3` *release segments*.
  #       
  #       This helps us not loading things like `2018-new-stuff` into a
  #       version, as might be found in a Git tag.
  #       
  #       It does not let us avoid loading `2018.10.11-new-stuff` info a
  #       version, so fair warning.
  #       
  #   2.  If `strict: true` and there are not **exactly** `3`
  #       *release segments*.
  # 
  def self.semver source, strict: false
    source = source.to_s unless source.is_a?( String )
    
    identifier_for_ref = method :identifier_for
    
    if  source.include?( '-' ) &&
        source.include?( '+' ) &&
        source.index( '-' ) < source.index( '+' )
      release_str, _, rest = source.partition '-'
      pre_str, _, build_str = rest.partition '+'
    elsif source.include?( '+' )
      release_str, _, build_str = source.partition '+'
      pre_str = ''
    elsif source.include?( '-' )
      release_str, _, pre_str = source.partition '-'
      build_str = ''
    else
      release_str = source
      pre_str = build_str = ''
    end
    
    release_segs, pre_segs, build_segs = \
      [release_str, pre_str, build_str].map { |str|
        split_identifiers( str ).map &identifier_for_ref
      }
    
    # Check release segments length
    if strict && release_segs.length != 3
      raise NRSER::ArgumentError.new \
        "Strict SemVer versions *MUST* have at exactly 3 release segments",
        source: source,
        release_segments: release_segs
        
    elsif release_segs.length < 3
      raise NRSER::ArgumentError.new \
        "SemVer versions *MUST* have at lease 3 release segments",
        source: source,
        release_segments: release_segs
      
    end
    
    prop_values **{
      raw: source,
      major: release_segs[0],
      minor: release_segs[1],
      patch: release_segs[2],
      revision: release_segs[3..-1] || [],
      prerelease: pre_segs,
      build: build_segs,
    }.compact
  end
  
  
  def npm_version source
    semver source, strict: true
  end


  # Parse Docker image tag version and create an instance.
  # 
  # @param [#to_s] source
  #   String version to parse.
  # 
  # @return [QB::Package::Version]
  # 
  def self.docker_tag source
    source = source.to_s unless source.is_a?( String )
    self.string( source.gsub( '_', '+' ) ).merge raw: source
  end # .docker_tag


  # Parse string version into an instance. Accept Semver, Ruby Gem and
  # Docker image tag formats.
  # 
  # @param [#to_s] source
  #   String version to parse.
  # 
  # @return [QB::Package::Version]
  # 
  def self.string source
    source = source.to_s unless source.is_a?( String )
    
    t.non_empty_str.check source
    
    if source.include? '_'
      docker_tag source
    elsif ( source.include?( '-' ) ||
            source.include?( '+' ) ) &&
          source =~ /\A\d+\.\d+\.\d+/
      semver source
    else
      gemver source
    end
  end

  singleton_class.send :alias_method, :s, :string
  
  
  def self.object object
    case object
    when String
      string object
    when Hash
      prop_values **object
    when ::Gem::Version
      gemver object
    else
      raise TypeError.new binding.erb <<-END
        `object` must be String, Hash or Gem::Version
        
        Found:
        
            <%= object.pretty_inspect %>
        
      END
    end
  end
  
  
  # Load a {QB::Package::Version} from a file.
  # 
  # Just reads the file and passes the contents to {.string}.
  # 
  # @param [String | Pathname | IO] file
  #   File path or handle to read from.
  # 
  # @return [QB::Package::Version]
  # 
  def self.file path
    string File.read( path )
  end
  
  
  
  def self.repo repo_or_path, add_build: true
    repo = t.match repo_or_path,
      QB::Repo, repo_or_path,
      t.path,   QB::Repo.method( :from_path )
    
    version_path = repo.root_path / 'VERSION'
    file_version = file version_path
    
    if  add_build &&
        file_version.level? &&
        file_version.dev?
      file_version.build_version \
        branch: repo.branch,
        ref: repo.head_short,
        dirty: !repo.clean?
    else
      file_version
    end
  end
  
end # module QB::Package::Version::From
