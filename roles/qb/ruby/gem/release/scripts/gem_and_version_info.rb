
# 1.  Find the gemspec path

spec_pattern = "#{ gem_root }/*.gemspec"
spec_path = Dir.glob(spec_pattern)[0]

if spec_path.nil?
  raise "No gemspec found for pattern #{ spec_pattern }"
end


# 2.  Get the gem name and version
#     
#     The gem *may already be loaded*, which would break the standard gemspec
#     approach because the `require` will be a no-op, resulting in the
#     already loaded version number being used instead of the one in the
#     file.
#     
#     This is only a problem for NRSER, which is loaded in vars.rb.rb, but
#     this fix should work for any module without worrying about what is
#     currently loaded... grab the info we need in a clean child process.
# 
code = <<-END
  require 'json'
  spec = Gem::Specification.load(#{ JSON.dump spec_path })
  puts JSON.dump({
    'version' => spec.version.version,
    'name' => spec.name,
  })
END

obj = JSON.load `ruby -e #{ code.shellescape }`
version = Gem::Version.new obj['version']
name = obj['name']


# 3.  Figure out what the next version will be

segments = version.segments.dup
segments.pop while segments.any? {|s| s.is_a? String}

segments[-1] = segments[-1].succ
segments << 'dev'

next_version = segments.join('.')


# 4.  Figure out what file the version definition lives in

version_path = if version_file.nil?
  bare_path = File.join( gem_root, 'VERSION' )
  
  if File.file?( bare_path )
    bare_path
  else
    # quick hack to deal with `a-b => a/b` gem names
    name_path = name.gsub '-', '/'
    
    File.join gem_root, 'lib', name_path, 'version.rb'
  end
else
  File.expand_path version_file, cwd
end

unless File.file?( version_path )
  raise "Version file not found at #{ version_path }"
end

# 5.  Return the facts

{
  'name' => name,
  'current_version' => version.version,
  'release_version' => version.release,
  'next_version' => next_version,
  'version_path' => version_path,
  'spec_path' => spec_path,
}
