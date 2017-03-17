module QB
  GEM_NAME = 'qb'
  
  VERSION = "0.1.49"
  
  def self.gemspec
    Gem.loaded_specs[GEM_NAME]
  end
end
