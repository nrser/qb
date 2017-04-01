module QB
  class Options
    # base for errors in the module, extends QB:Error
    class Error < QB::Error
    end
    
    # raised when there's bad option metadata 
    class MetadataError < Error
    end
  end # Options
end # QB