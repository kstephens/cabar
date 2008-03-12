require 'cabar'

module Cabar

  # Common error base class for Cabar.
  class Error < ::Exception
    # The original error, if any.
    attr_accessor :error

    # The error chaing, if any.
    attr_accessor :error_chain

    attr_accessor :options

    def initialize msg, *args
      # $stderr.puts "#{self.class}.initialize(#{msg.inspect}, #{args.inspect})"
      if Hash === args[-1]
        opts = args.pop
        @error = opts[:error]
        opts.delete(:error)
      end
      @options = opts

      super msg, *args

      @error_chain = [ ]
      err_x = self
      while err_x && err_x.respond_to?(:error)
        suberror = err_x.error
        if suberror 
          @error_chain << suberror
        end
        err_x = suberror
      end

      # Get the inner-most backtrace.
      if (last_error = @error_chain[-1]) && 
          (last_backtrace = last_error.backtrace) 
        @backtrace = last_backtrace
      end
    end

    # Format a Error in cabar YAML format.
    def self.cabar_format err
      msg = [ ]

      msg << Cabar.yaml_header(:error)
      msg << "    class: #{err.class}"
      if err.respond_to?(:message)
        msg << "    message: #{err.message.inspect}"
      else
        msg << "    object: #{err.inspect.inspect}"
      end

      if err_chain = err.respond_to?(:error_chain) && err.error_chain
        i = -1
        err_chain.each do | suberr |
          msg << "    error_#{i += 1}:"
          msg << "      class: #{suberr.class}"
          msg << "      message: #{suberr.message.inspect}"
        end
      end

      if err.respond_to? :options
        options = err.options
        options.each do | k, v |
          msg << "    #{k}: #{v.inspect}"
        end
      end

      if err.respond_to? :backtrace
        msg << "    backtrace: "
        err.backtrace.each do | x |
          msg << "    - #{x.to_s.inspect}"
        end
      end

      msg << ''
      msg.join("\n")
    end

    def self.cabar_error_handler &blk
      yield
    rescue SystemExit => err
      raise err
    rescue Exception => err
      $stderr.puts Cabar::Error.cabar_format(err)
      Kernel.exit 10
    end

  end # class

end # module


