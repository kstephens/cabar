require 'cabar/base'

module Cabar

  # Common logger.
  class Logger < Base
    def initialize opts = EMPTY_HASH
      @levels = {
        :debug => 5,
        :info  => 4,
        :warn  => 3,
        :error => 2,
        :fatal => 1,
      }
      super
      @level ||= ENV['CABAR_DEBUG'] ? :debug : :warn
      @level = @levels[@level] || @level
    end

    def method_missing sel, *args
      # $stderr.puts "sel = #{sel.inspect} args=#{args.inspect}"
      if @levels[sel]
        log_at_level(sel, *args)
      else
        super
      end
    end

    def log_at_level(level, msg = nil, opts = EMPTY_HASH)
      if @level >= @levels[level] || opts[:force]
        if msg == nil && block_given?
          msg = yield
        end
        $stderr.puts "  #{name}: #{level}: #{msg}"
      end
    end
  end # class
end # module

