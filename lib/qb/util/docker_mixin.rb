require 'nrser'

module QB 
module Util

# Mixin to help working with Docker.
module DockerMixin
  
  # Character limit for Docker image tags.
  # 
  # @return [Fixnum]
  # 
  DOCKER_TAG_MAX_CHARACTERS = 128
  

  # Regexp to validate strings as Docker tags:
  # 
  # 1.  Must start with an ASCII alpha-numeric - `A-Z`, `a-z`, `0-9`.
  #     
  # 2.  The rest of the characters can be:
  #     
  #     1.  `A-Z`
  #     2.  `a-z`
  #     3.  `_`
  #     4.  `.`
  #     5.  `-`
  #     
  #     Note that it *can not* include `+`, so [Semver][] strings with
  #     build info after the `+` are not legal.
  #         
  # 3.  Must be {QB::Util::DockerMixin::DOCKER_TAG_MAX_CHARACTERS} in length
  #     or less.
  # 
  # [Semver]: https://semver.org/
  # 
  # @return [Regexp]
  # 
  DOCKER_TAG_VALID_RE = \
    /\A[A-Za-z0-9_][A-Za-z0-9_\.\-]{0,#{ DOCKER_TAG_MAX_CHARACTERS - 1}}\z/.
    freeze
  
  
  # Class methods to extend the receiver with when {QB::Util::DockerMixin}
  # is included.
  module ClassMethods
    
    # Test if `string` is a valid Docker image tag by seeing if it matches 
    # {QB::Util::DockerMixin::DOCKER_TAG_VALID_RE}
    # 
    # @param [String] string
    #   String to test.
    # 
    # @return [Boolean]
    #   True if `string` is a valid Docker image tag.
    # 
    def valid_docker_tag? string
      DockerMixin::DOCKER_TAG_VALID_RE =~ string
    end
    
    
    # Check that `string` is a valid Docker image tag, raising an error if not.
    # 
    # Check is performed via
    # {QB::Util::DockerMixin::ClassMethods#valid_docker_tag}.
    # 
    # @param string see QB::Util::DockerMixin::ClassMethods#valid_docker_tag
    # 
    # @return [nil]
    def check_docker_tag string
      unless valid_docker_tag? string
        raise ArgumentError.new NRSER.squish <<-END
          Argument #{ string.inspect } is not a valid Docker image tag.
        END
      end
      nil
    end
    
    
    # Convert a [Semver][] version string to a string suitable for use as 
    # a Docker image tag, which, as of writing, are restricted to
    # 
    #     [A-Za-z0-9_.-]
    # 
    # and 128 characters max (used to be 30, but seems it's been increased).
    # 
    # [Docker image tag]: https://github.com/moby/moby/issues/8445
    # [Docker image tag (archive)]: https://archive.is/40soa
    # 
    # This restriction prohibits [Semver][] strings that use `+` to separate
    # the build segments.
    # 
    # We replace `+` with `_`.
    #
    # `_` is *not* a legal character in [Semver][] *or* Ruby Gem versions,
    # making it clear that the resulting string is for Docker use, and
    # allowing parsing to get back to an equal {QB::Package::Version}
    # instance.
    # 
    # [Semver]: http://semver.org/
    # 
    # @param [String] semver
    #   A legal [Semver][] version string to convert.
    # 
    # @return [String]
    #   Legal Docker image tag corresponding to `semver`.
    #
    # @raise [ArgumentError]
    #   If the resulting string is longer than 
    #   {QB::Package::Version::DOCKER_TAG_MAX_CHARACTERS}.
    # 
    # @raise [ArgumentError]
    #   If the resulting string still contains invalid characters for a Docker
    #   image tag after the substitution.
    # 
    def to_docker_tag semver
      semver.gsub('+', '_').tap { |docker_tag|
        check_docker_tag docker_tag
      }
    end # .to_docker_tag
    
  end # module ClassMethods
  
  def self.included base
    base.extend ClassMethods
  end
  
end # module DockerMixin

end # module Util
end # module QB
