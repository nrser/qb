# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------
require 'forwardable'

# Deps
# -----------------------------------------------------------------------
require 'awesome_print'
require 'semantic_logger'

# Project / Package
# -----------------------------------------------------------------------


# Refinements
# =======================================================================

using NRSER
using NRSER::Types


# Declarations
# =======================================================================

module QB::Util; end


# Definitions
# =======================================================================

# Utility methods to setup logging with [semantic_logger][].
# 
# [semantic_logger]: http://rocketjob.github.io/semantic_logger/
# 
module QB::Util::Logging
  include SemanticLogger::Loggable
  
  
  # @todo document Formatters module.
  module Formatters
    
    # Custom tweaked color formatter (for CLI output).
    # 
    # -   Turns on multiline output in Awesome Print by default.
    # 
    class Color < SemanticLogger::Formatters::Color
      
      # Constants
      # ======================================================================
      
      
      # Class Methods
      # ======================================================================
      
      
      # Attributes
      # ======================================================================
      
      
      # Constructor
      # ======================================================================
      
      # Instantiate a new `ColorFormatter`.
      def initialize **options
        super ap: { multiline: true },
              color_map: SemanticLogger::Formatters::Color::ColorMap.new(
                debug: SemanticLogger::AnsiColors::MAGENTA,
                trace: "\e[1;30m", # "Dark Gray"
              ),
              **options
      end # #initialize
      
      
      # Instance Methods
      # ======================================================================
      
      
      # Upcase the log level.
      # 
      # @return [String]
      # 
      def level
        "#{ color }#{ log.level.upcase }#{ color_map.clear }"
      end
      
      
      # Create the log entry text. Overridden to customize appearance -
      # generally reduce amount of info and put payload on it's own line.
      # 
      # We need to replace *two* super functions, the first being
      # [SemanticLogger::Formatters::Color#call][]:
      # 
      #     def call(log, logger)
      #       self.color = color_map[log.level]
      #       super(log, logger)
      #     end
      # 
      # [SemanticLogger::Formatters::Color#call]: https://github.com/rocketjob/semantic_logger/blob/v4.2.0/lib/semantic_logger/formatters/color.rb#L98
      # 
      # which doesn't do all too much, and the next being it's super-method,
      # [SemanticLogger::Formatters::Default#call][]:
      #     
      #     # Default text log format
      #     #  Generates logs of the form:
      #     #    2011-07-19 14:36:15.660235 D [1149:ScriptThreadProcess] Rails -- Hello World
      #     def call(log, logger)
      #       self.log    = log
      #       self.logger = logger
      #     
      #       [time, level, process_info, tags, named_tags, duration, name, message, payload, exception].compact.join(' ')
      #     end
      # 
      # [SemanticLogger::Formatters::Default#call]: https://github.com/rocketjob/semantic_logger/blob/v4.2.0/lib/semantic_logger/formatters/default.rb#L64
      # 
      # which does most the real assembly.
      # 
      # @param [SemanticLogger::Log] log
      #   The log entry to format.
      #   
      #   See [SemanticLogger::Log](https://github.com/rocketjob/semantic_logger/blob/v4.2.0/lib/semantic_logger/log.rb)
      # 
      # @param [SemanticLogger::Logger] logger
      #   The logger doing the logging (pretty sure, haven't checked).
      #   
      #   See [SemanticLogger::Logger](https://github.com/rocketjob/semantic_logger/blob/v4.2.0/lib/semantic_logger/logger.rb)
      # 
      # @return [String]
      #   The full log string.
      # 
      def call log, logger
        # SemanticLogger::Formatters::Color code
        self.color = color_map[log.level]
        
        # SemanticLogger::Formatters::Default code
        self.log    = log
        self.logger = logger
        
        is_info = log.level == :info
        
        [
          level,
          tags,
          named_tags,
          duration,
          (is_info ? nil : name),
          message,
          payload,
          exception,
        ].compact.join(' ')
        
      end # #call
      
      
    end # class Color
    
  end # module Formatters
  
  
  module Appender
    # Replacement for {SemanticLogger::Appender::Async} that implements the
    # same interface but just logs synchronously in the current thread.
    # 
    class Sync
      extend Forwardable
      
      # The appender we forward to, which is a {SemanticLogger::Processor}
      # in practice, since it wouldn't make any sense to wrap a regular
      # appender in a Sync.
      # 
      # @return [SemanticLogger::Processor]
      #     
      attr_accessor :appender

      # Forward methods that can be called directly
      def_delegator :@appender, :name
      def_delegator :@appender, :should_log?
      def_delegator :@appender, :filter
      def_delegator :@appender, :host
      def_delegator :@appender, :application
      def_delegator :@appender, :level
      def_delegator :@appender, :level=
      def_delegator :@appender, :logger
      # Added for sync
      def_delegator :@appender, :log
      def_delegator :@appender, :on_log
      def_delegator :@appender, :flush
      def_delegator :@appender, :close
      
      class FakeQueue
        def self.size
          0
        end
      end

      # Appender proxy to allow an existing appender to run asynchronously in a separate thread.
      #
      # Parameters:
      #   name: [String]
      #     Name to use for the log thread and the log name when logging any errors from this appender.
      #
      #   lag_threshold_s [Float]
      #     Log a warning when a log message has been on the queue for longer than this period in seconds.
      #     Default: 30
      #
      #   lag_check_interval: [Integer]
      #     Number of messages to process before checking for slow logging.
      #     Default: 1,000
      def initialize(appender:,
                     name: appender.class.name)

        @appender           = appender
      end
      
      # Needs to be there to support {SemanticLogger::Processor.queue_size},
      # which gets the queue and returns it's size (which will always be zero
      # for us).
      # 
      # We return {FakeQueue}, which only implements a `size` method that
      # returns zero.
      # 
      # @return [#size]
      # 
      def queue; FakeQueue; end
      
      def lag_check_interval; -1; end
      
      def lag_check_interval= value
        raise "Can't set `lag_check_interval` on Sync appender"
      end
      
      def lag_threshold_s; -1; end
      
      def lag_threshold_s= value
        raise "Can't set `lag_threshold_s` on Sync appender"
      end
      
      # @return [false] Sync appender is of course not size-capped.
      def capped?; false; end

      # The {SemanticLogger::Appender::Async} worker thread is exposed via
      # this method, which creates it if it doesn't exist and returns it, but
      # it doesn't seem like the returned value is ever used; the method
      # call is just invoked to start the thread.
      # 
      # Hence it seems to make most sense to just return `nil` since we don't
      # have a thread, and figure out what to do if that causes errors (so far
      # it seems fine).
      #
      # @return [nil]
      # 
      def thread; end
      
      # @return [true] Sync appender is always active
      def active?; true; end

    end # class Sync
  end # module Appenders
  
  
  # Module (Class) Methods
  # =====================================================================
  
  
  def self.level
    SemanticLogger.default_level
  end
  
  
  def self.level= level
    SemanticLogger.default_level = level
  end
  
  
  def self.setup?
    !!@setup
  end
  
  
  def self.get_env_level
    if ENV['QB_TRACE'].truthy?
      return :trace
    elsif ENV['QB_DEBUG'].truthy?
      return :debug
    elsif ENV['QB_LOG_LEVEL']
      return ENV['QB_LOG_LEVEL'].to_sym
    end
    
    nil
  end
  
  
  # Setup logging.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def self.setup level: nil, sync: false, dest: nil
    if setup?
      logger.warn "Logging is already setup!"
      return false
    end
    
    SemanticLogger.application = 'qb'
    
    level = get_env_level if level.nil?
    self.level = level if level
    self.appender = dest if dest
    
    if sync
      # Hack up SemanticLogger to do sync logging in the main thread
      
      # Create a {Locd::Logging::Appender::Sync}, which implements the
      # {SemanticLogger::Appender::Async} interface but just forwards directly
      # to it's appender in the same thread, and point it where
      # {SemanticLogger::Processor.instance} (which is an Async) points.
      # 
      sync_appender = Appender::Sync.new \
        appender: SemanticLogger::Processor.instance.appender
      
      # Swap our sync in for the async
      SemanticLogger::Processor.instance_variable_set \
        :@processor,
        sync_appender
    end
    
    @setup = true
    
    true
  end # .setup
  
  
  def self.appender
    @appender
  end
  
  
  def self.appender= value
    # Save ref to current appender (if any) so we can remove it after adding
    # the new one.
    old_appender = @appender
    
    @appender = case value
    when Hash
      SemanticLogger.add_appender value
    when String
      SemanticLogger.add_appender file_name: value
    else
      SemanticLogger.add_appender \
        io: value,
        formatter: Formatters::Color.new
    end
    
    # Remove the old appender (if there was one). This is done after adding
    # the new one so that failing won't result with no appenders.
    SemanticLogger.remove_appender( old_appender ) if old_appender
    
    @appender
  end
  
  
end # module QB::Util::Logging
