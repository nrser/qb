require 'nrser/core_ext/hash'
require_relative './service'

# QB STDIO Service to receive log lines in JSON format and forward them
# on to the logger.
# 
class QB::IPC::STDIO::Server::LogService < QB::IPC::STDIO::Server::Service
  
  class Log < SemanticLogger::Log
    
    
    # Construction
    # ========================================================================
    
    def initialize **kwds
      super *kwds.values_at( :name, :level, :level_index )
      
      if kwds.key? :timestamp
        self.time = Time.parse kwds[:timestamp]
      end
      
      self.tags = kwds[:tags] || []
      self.named_tags = kwds[:named_tags] || {}
      
      @pid = kwds[:pid] || '???'
      @thread = kwds[:thread] || '???'
      
      exception = if kwds.key? :exception
        klass = kwds[:exception]["name"].safe_constantize
        
        if klass
          # HACK  Good God...
          #       
          #       What we're doing is constructing an instance of the
          #       exception class so that SemLog is happy with it... so we
          #       take the class name, load that constant, then we *don't*
          #       create an instance, because that could require args, and
          #       all we need is something that holds the message and
          #       backtrace, so we add the message as the response from
          #       dynamically-created `#to_s` and `#message` methods added
          #       *to that instance only*. Then we set the backtrace using
          #       the regular instance API.
          #       
          #       ...and it kinda seems to work. But I suspect it will fuck
          #       me/us/someone at some point if left like this...
          #       
          
          message = kwds[:exception]["message"] || '(none)'
          
          error = klass.allocate
          
          metaclass = class << error; self; end
          
          [:to_s, :message].each do |name|
            metaclass.send( :define_method, name ){ message }
          end
          
          if kwds[:exception]["stack_trace"]
            error.set_backtrace kwds[:exception]["stack_trace"]
          end
          
          error
        end
      end
      
      assign exception: exception, **kwds.slice(
        :message,
        :payload,
        :min_duration,
        :metric,
        :metric_amount,
        :duration,
        # :backtrace,
        # :log_exception,
        # :on_exception_level,
        :dimension,
      )
    end
        
    # Instance Methods
    # ========================================================================
    
    def process_info thread_name_length = 30
      "IPC:#{ @pid }:#{"%.#{ thread_name_length }s" % @thread}"
    end
    
    
  end # class Log
  
  
  def initialize name:, socket_dir:
    super name: name, socket_dir: socket_dir
    @loggers = {}
  end
  
  def work_in_thread
    while (line = @socket.gets) do
      logger.trace "received line",
        line: line
      
      load_log_in_thread line
    end
  end
  
  
  protected
  # ========================================================================
    
    # Get a {NRSER::Log::Logger} for a log name, creating them on demand
    # and caching after that.
    # 
    # @param [String] name
    #   Name from the log message.
    # 
    # @return [NRSER::Log::Logger]
    # 
    def logger_for name
      @loggers[name] ||= NRSER::Log[name]
    end
    
    
    # Log a {Log} in it's logger if it should log.
    # 
    # @protected
    # 
    # @param [Log] log
    #   Log instance to dispatch
    # 
    # @return [void]
    # 
    def write_log log
      logger = logger_for log.name
      # logger.level = :trace
      logger.log( log ) if logger.should_log?( log )
    end
    
    
    # Try to load the line into a {SemanticLogger::Log} instance.
    # 
    def load_log_in_thread line
      # logger.with_level :trace do
        decoded = logger.catch.warn(
          "Unable to decode log message",
          line: line,
        ) { ActiveSupport::JSON.decode line }
        
        logger.trace "Decoded log message", decoded
        
        return nil unless decoded
      
        logger.catch.warn(
          "Unable to process log message",
          line: line,
          decoded: decoded,
        ) do
          log = Log.new **decoded.to_options
          
          logger.trace "Constructed {Log}",
            log: log
          
          write_log log
        end # logger.catch.warn
      # end # logger.with_level :trace
    end
  
  public # end protected ***************************************************
  
end # LogService
