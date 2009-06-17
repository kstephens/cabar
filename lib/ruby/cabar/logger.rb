require 'cabar/base'

module Cabar

  # Common logger.
  class Logger < Base
    # The Logger to delegate to.
    attr_accessor :delegate

    # The mapping between Symbols and levels.
    attr_accessor :levels

    # The IO stream to write to.
    attr_accessor :output

    
    # The default logger level Hash.
    # Can be modified.
    def self.default_levels
      @@default_levels ||= {
        :fatal   => 1,
        :error   => 2,
        :warn    => 3,
        :info    => 4,
        :verbose => 5,
        :debug1  => 6,
        :debug   => 7,
        :debug2  => 8,
        :debug3  => 9,
        :debug4  => 10,
      }
    end


    def initialize opts = EMPTY_HASH
      @levels = Logger.default_levels

      super

      # Default level.
      @level ||= 
        ENV['CABAR_LOG_LEVEL'] || 
        (ENV['CABAR_DEBUG'] ? :debug : :warn)

      # Convert level symbol, level string, or level number
      @level = 
        @levels[@level] || 
        @levels[@level.to_sym] || 
        (@level.to_i > 0 ? @level.to_i : false) ||
        @level

      @output ||= $stderr
    end


    def method_missing sel, *args, &blk
      # $stderr.puts "sel = #{sel.inspect} args=#{args.inspect}"
      if @levels[sel]
        log_at_level(sel, *args, &blk)
      else
        super
      end
    end


    # Options:
    #
    # :force  -- output regardless of current log level. 
    # :prefix -- do not generate standard prefix.
    # :write  -- use write and flush, instead of puts.
    #
    def log_at_level(level, msg = nil, opts = EMPTY_HASH)
      if @level >= @levels[level] || opts[:force]
        if msg == nil && block_given?
          msg = yield
        end
        
        log_raw(level, msg, opts)
      end
    end
    

    # Log raw message to delegate our output.
    def log_raw(level, msg, opts = EMPTY_HASH)
      msg = [ msg ] unless Array === msg

      unless opts[:prefix] == false
        msg = msg.map{|m| "#{name}: #{m}"}
      end

      if @delegate
        d = @delegate
        while ! d.respond_to?(:log_raw) && d.respond_to?(:_logger)
          d = d._logger
        end
        d.log_raw(level, msg, opts)
      else
        if opts[:write]
          unless opts[:prefix] == false
            @output.write "  #{level.to_s.upcase}: "
          end
          msg.each do | msg |
            @output.write msg.to_s
            @output.flush
          end
        else
          msg.each do | msg |
            unless opts[:prefix] == false
              @output.write "  #{level.to_s.upcase}: "
            end
            @output.puts msg.to_s
          end
        end
      end
    end


    class Null < self
      def method_missing sel, *args, &blk
        if @levels[sel]
          return
        else
          super
        end
      end


      def log_at_level *args
      end


      def log_raw *args
      end
    end
  end # class


  class Base 
    # Returns the current Main object's Logger.
    # Subclasses should override this method.
    def self._logger
      Cabar::Main.current._logger
    end

    # Returns the current Main object's Logger.
    # Subclasses should override this method.
    def _logger
      Cabar::Main.current._logger
    end
  end # class


end # module

