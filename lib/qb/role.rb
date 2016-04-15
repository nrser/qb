module QB
  class Role
    attr_accessor :path, :name, :rel_path
    
    def initialize path
      @path = path
      
      @rel_path = if path.to_s.start_with? QB::ROLES_DIR.to_s
        path.sub(QB::ROLES_DIR.to_s + '/', '')
      elsif path.to_s.start_with? Dir.getwd
        path.sub(Dir.getwd + '/', './')
      else
        path
      end
      
      @name = path.to_s.split(File::SEPARATOR).last
    end
    
    def to_s
      @rel_path.to_s
    end
    
    def namespace
      if @name.include? '.'
        @name.split('.').first
      else
        nil
      end
    end
    
    def namespaceless
      @name.split('.', 2).last
    end
  end
end